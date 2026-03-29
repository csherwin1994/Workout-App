import Foundation
import SwiftData
import CryptoKit
import AuthenticationServices

// MARK: - Config

enum SupabaseConfig {
    static let projectURL = URL(string: "https://txgpmclruboyzszqyjyt.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR4Z3BtY2xydWJveXpzenF5anl0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ2MjM0MzcsImV4cCI6MjA5MDE5OTQzN30.Pe-2uy_nHovWiXES21KsWG5pv4FAex_xdUhL1DMEHjU"
}

// MARK: - DTOs

struct RemoteWorkoutSession: Codable {
    var id: String
    var userId: String
    var title: String
    var startDate: Date
    var endDate: Date?
    var notes: String
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, notes
        case userId = "user_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case updatedAt = "updated_at"
    }
}

struct RemoteExerciseLog: Codable {
    var id: String
    var sessionId: String
    var exerciseName: String
    var exerciseMuscleGroup: String
    var orderIndex: Int

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case exerciseName = "exercise_name"
        case exerciseMuscleGroup = "exercise_muscle_group"
        case orderIndex = "order_index"
    }
}

struct RemoteWorkoutSet: Codable {
    var id: String
    var logId: String
    var orderIndex: Int
    var weight: Double
    var reps: Int
    var isCompleted: Bool
    var duration: Double
    var distance: Double
    var calories: Int

    enum CodingKeys: String, CodingKey {
        case id
        case logId = "log_id"
        case orderIndex = "order_index"
        case weight, reps, duration, distance, calories
        case isCompleted = "is_completed"
    }
}

struct RemoteRoutine: Codable {
    var id: String
    var userId: String
    var name: String
    var notes: String
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, notes
        case userId = "user_id"
        case updatedAt = "updated_at"
    }
}

// MARK: - Auth State

enum AuthState {
    case loading
    case signedOut
    case signedIn(userId: String, email: String)
}

// MARK: - SupabaseManager

@Observable
final class SupabaseManager {
    static let shared = SupabaseManager()

    var authState: AuthState = .loading
    var isSyncing = false
    var lastSyncError: String?

    private let baseURL = SupabaseConfig.projectURL
    private let anonKey = SupabaseConfig.anonKey
    private var accessToken: String?

    // UserDefaults keys for session persistence
    private let kAccessToken = "supabase_access_token"
    private let kUserId      = "supabase_user_id"
    private let kUserEmail   = "supabase_user_email"

    private init() {
        restoreSession()
    }

    var isSignedIn: Bool {
        if case .signedIn = authState { return true }
        return false
    }

    var currentUserId: String? {
        if case .signedIn(let uid, _) = authState { return uid }
        return nil
    }

    var currentEmail: String? {
        if case .signedIn(_, let email) = authState { return email }
        return nil
    }

    // MARK: - Session Persistence

    private func restoreSession() {
        let defaults = UserDefaults.standard
        guard
            let token = defaults.string(forKey: kAccessToken),
            let uid   = defaults.string(forKey: kUserId),
            let email = defaults.string(forKey: kUserEmail)
        else {
            authState = .signedOut
            return
        }
        accessToken = token
        authState = .signedIn(userId: uid, email: email)
    }

    private func persistSession(token: String, userId: String, email: String) {
        let defaults = UserDefaults.standard
        defaults.set(token,   forKey: kAccessToken)
        defaults.set(userId,  forKey: kUserId)
        defaults.set(email,   forKey: kUserEmail)
    }

    private func clearSession() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: kAccessToken)
        defaults.removeObject(forKey: kUserId)
        defaults.removeObject(forKey: kUserEmail)
    }

    // MARK: - Auth

    func signUp(email: String, password: String) async throws {
        let body: [String: String] = ["email": email, "password": password]
        let response = try await post(path: "/auth/v1/signup", body: body, requiresAuth: false)
        try handleAuthResponse(response)
    }

    func signIn(email: String, password: String) async throws {
        let body: [String: String] = ["email": email, "password": password]
        let response = try await post(path: "/auth/v1/token?grant_type=password", body: body, requiresAuth: false)
        try handleAuthResponse(response)
    }

    // MARK: - Sign In with Apple

    func signInWithApple(idToken: String, rawNonce: String) async throws {
        let body: [String: Any] = [
            "provider": "apple",
            "id_token": idToken,
            "nonce": rawNonce
        ]
        let response = try await post(path: "/auth/v1/token?grant_type=id_token", body: body, requiresAuth: false)
        try handleAuthResponse(response)
    }

    // MARK: - Sign In with Google

    @MainActor
    func signInWithGoogle(presenting anchor: ASPresentationAnchor) async throws {
        let redirectURL = "com.sherwinlabs.volt://auth-callback"
        guard var components = URLComponents(string: baseURL.absoluteString + "/auth/v1/authorize") else {
            throw SupabaseError.encodingFailed
        }
        components.queryItems = [
            URLQueryItem(name: "provider", value: "google"),
            URLQueryItem(name: "redirect_to", value: redirectURL)
        ]
        guard let authURL = components.url else { throw SupabaseError.encodingFailed }

        let anchorProvider = AnchorProvider(anchor: anchor)
        let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "com.sherwinlabs.volt") { url, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: SupabaseError.authFailed("No callback URL"))
                }
            }
            session.presentationContextProvider = anchorProvider
            session.prefersEphemeralWebBrowserSession = true
            session.start()
        }
        _ = anchorProvider

        guard
            let fragment = callbackURL.fragment,
            let token = fragment.split(separator: "&").first(where: { $0.hasPrefix("access_token=") })?.dropFirst("access_token=".count)
        else {
            throw SupabaseError.authFailed("No access token in callback")
        }
        let accessTokenStr = String(token)
        let user = try await fetchUser(accessToken: accessTokenStr)
        self.accessToken = accessTokenStr
        authState = .signedIn(userId: user.id, email: user.email)
        persistSession(token: accessTokenStr, userId: user.id, email: user.email)
    }

    private struct UserResponse: Decodable {
        let id: String
        let email: String
    }

    private func fetchUser(accessToken: String) async throws -> UserResponse {
        guard let url = URL(string: baseURL.absoluteString + "/auth/v1/user") else {
            throw SupabaseError.encodingFailed
        }
        var request = URLRequest(url: url)
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw SupabaseError.httpError(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return try JSONDecoder().decode(UserResponse.self, from: data)
    }

    func signOut() async {
        _ = try? await post(path: "/auth/v1/logout", body: [:], requiresAuth: true)
        accessToken = nil
        clearSession()
        authState = .signedOut
    }

    private func handleAuthResponse(_ json: [String: Any]) throws {
        guard
            let token  = json["access_token"] as? String,
            let user   = json["user"] as? [String: Any],
            let userId = user["id"] as? String,
            let email  = user["email"] as? String
        else {
            let msg = (json["error_description"] as? String)
                   ?? (json["msg"] as? String)
                   ?? "Authentication failed"
            throw SupabaseError.authFailed(msg)
        }
        accessToken = token
        authState = .signedIn(userId: userId, email: email)
        persistSession(token: token, userId: userId, email: email)
    }

    // MARK: - Sync

    func syncAll(context: ModelContext) async {
        guard let userId = currentUserId else { return }
        isSyncing = true
        lastSyncError = nil
        defer { isSyncing = false }
        do {
            try await pushWorkouts(context: context, userId: userId)
            try await pushRoutines(context: context, userId: userId)
        } catch {
            lastSyncError = error.localizedDescription
        }
    }

    // MARK: - Push Workouts

    private func pushWorkouts(context: ModelContext, userId: String) async throws {
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        for session in sessions {
            guard session.endDate != nil else { continue }
            let remote = RemoteWorkoutSession(
                id: session.id.uuidString, userId: userId,
                title: session.title, startDate: session.startDate,
                endDate: session.endDate, notes: session.notes, updatedAt: Date()
            )
            try await upsert(table: "workout_sessions", record: remote)
            for log in session.exerciseLogs {
                let remoteLog = RemoteExerciseLog(
                    id: log.id.uuidString, sessionId: session.id.uuidString,
                    exerciseName: log.exerciseName,
                    exerciseMuscleGroup: log.exerciseMuscleGroup, orderIndex: log.orderIndex
                )
                try await upsert(table: "exercise_logs", record: remoteLog)
                for set in log.sets {
                    let remoteSet = RemoteWorkoutSet(
                        id: set.id.uuidString, logId: log.id.uuidString,
                        orderIndex: set.orderIndex, weight: set.weight,
                        reps: set.reps, isCompleted: set.isCompleted,
                        duration: set.duration, distance: set.distance,
                        calories: set.calories
                    )
                    try await upsert(table: "workout_sets", record: remoteSet)
                }
            }
        }
    }

    // MARK: - Push Routines

    private func pushRoutines(context: ModelContext, userId: String) async throws {
        let routines = try context.fetch(FetchDescriptor<Routine>())
        for routine in routines {
            let remote = RemoteRoutine(
                id: routine.id.uuidString, userId: userId,
                name: routine.name, notes: routine.notes, updatedAt: Date()
            )
            try await upsert(table: "routines", record: remote)
        }
    }

    // MARK: - HTTP Helpers

    private func upsert<T: Encodable>(table: String, record: T) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(record)
        guard let body = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SupabaseError.encodingFailed
        }
        _ = try await post(
            path: "/rest/v1/\(table)", body: body, requiresAuth: true,
            extraHeaders: ["Prefer": "resolution=merge-duplicates,return=minimal"]
        )
    }

    private func post(
        path: String,
        body: [String: Any],
        requiresAuth: Bool,
        method: String = "POST",
        extraHeaders: [String: String] = [:]
    ) async throws -> [String: Any] {
        guard let url = URL(string: baseURL.absoluteString + path) else {
            throw SupabaseError.encodingFailed
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        if requiresAuth, let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        for (key, value) in extraHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SupabaseError.httpError(http.statusCode, msg)
        }
        if data.isEmpty { return [:] }
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }
}

// MARK: - Nonce Helpers

func randomNonce(length: Int = 32) -> String {
    let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    while remainingLength > 0 {
        var randoms = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
        randoms.forEach { random in
            if remainingLength == 0 { return }
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    return result
}

func sha256Nonce(_ input: String) -> String {
    let digest = SHA256.hash(data: Data(input.utf8))
    return digest.compactMap { String(format: "%02x", $0) }.joined()
}

// MARK: - ASWebAuthenticationSession Anchor

private final class AnchorProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    let anchor: ASPresentationAnchor
    init(anchor: ASPresentationAnchor) { self.anchor = anchor }
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { anchor }
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case authFailed(String)
    case encodingFailed
    case httpError(Int, String)

    var errorDescription: String? {
        switch self {
        case .authFailed(let msg):      return msg
        case .encodingFailed:           return "Failed to encode data"
        case .httpError(let code, let msg): return "HTTP \(code): \(msg)"
        }
    }
}
