import Foundation
import SwiftData

// MARK: - Supabase Manager
// Handles cloud sync between local SwiftData and Supabase.
//
// SETUP:
// 1. Add the Swift package: https://github.com/supabase-community/supabase-swift
//    In Xcode: File > Add Package Dependencies, paste the URL above, add "Supabase" target
// 2. Set your project URL and anon key below (or in Info.plist)
// 3. Run the SQL schema in your Supabase SQL editor (see SupabaseSchema.sql in project root)
// 4. Call SupabaseManager.shared.signIn(...) after collecting credentials in ProfileView

// ─── Uncomment after adding the supabase-swift package ──────────────────────
// import Supabase
// ────────────────────────────────────────────────────────────────────────────

enum SupabaseConfig {
    /// Replace with your Supabase project URL
    static let projectURL = URL(string: "https://YOUR_PROJECT_ID.supabase.co")!
    /// Replace with your Supabase anon (public) key
    static let anonKey = "YOUR_SUPABASE_ANON_KEY"
}

// MARK: - DTOs (mirror your Supabase table columns)

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

    enum CodingKeys: String, CodingKey {
        case id
        case logId = "log_id"
        case orderIndex = "order_index"
        case weight, reps
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
    case signedOut
    case signedIn(userId: String, email: String)
}

// MARK: - SupabaseManager

@Observable
final class SupabaseManager {
    static let shared = SupabaseManager()

    var authState: AuthState = .signedOut
    var isSyncing = false
    var lastSyncError: String?

    private let baseURL: URL
    private let anonKey: String
    private var accessToken: String?

    private init() {
        self.baseURL = SupabaseConfig.projectURL
        self.anonKey = SupabaseConfig.anonKey
    }

    var isSignedIn: Bool {
        if case .signedIn = authState { return true }
        return false
    }

    var currentUserId: String? {
        if case .signedIn(let uid, _) = authState { return uid }
        return nil
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

    func signOut() async {
        _ = try? await post(path: "/auth/v1/logout", body: [:], requiresAuth: true)
        accessToken = nil
        authState = .signedOut
    }

    private func handleAuthResponse(_ json: [String: Any]) throws {
        guard
            let token = json["access_token"] as? String,
            let user = json["user"] as? [String: Any],
            let userId = user["id"] as? String,
            let email = user["email"] as? String
        else {
            let msg = (json["error_description"] as? String) ?? "Auth failed"
            throw SupabaseError.authFailed(msg)
        }
        accessToken = token
        authState = .signedIn(userId: userId, email: email)
    }

    // MARK: - Sync

    /// Full sync: push all local SwiftData records to Supabase, pull remote changes.
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
        let descriptor = FetchDescriptor<WorkoutSession>()
        let sessions = try context.fetch(descriptor)

        for session in sessions {
            guard session.endDate != nil else { continue } // skip in-progress

            let remote = RemoteWorkoutSession(
                id: session.id.uuidString,
                userId: userId,
                title: session.title,
                startDate: session.startDate,
                endDate: session.endDate,
                notes: session.notes,
                updatedAt: Date()
            )

            try await upsert(table: "workout_sessions", record: remote)

            for log in session.exerciseLogs {
                let remoteLog = RemoteExerciseLog(
                    id: log.id.uuidString,
                    sessionId: session.id.uuidString,
                    exerciseName: log.exerciseName,
                    exerciseMuscleGroup: log.exerciseMuscleGroup,
                    orderIndex: log.orderIndex
                )
                try await upsert(table: "exercise_logs", record: remoteLog)

                for set in log.sets {
                    let remoteSet = RemoteWorkoutSet(
                        id: set.id.uuidString,
                        logId: log.id.uuidString,
                        orderIndex: set.orderIndex,
                        weight: set.weight,
                        reps: set.reps,
                        isCompleted: set.isCompleted
                    )
                    try await upsert(table: "workout_sets", record: remoteSet)
                }
            }
        }
    }

    // MARK: - Push Routines

    private func pushRoutines(context: ModelContext, userId: String) async throws {
        let descriptor = FetchDescriptor<Routine>()
        let routines = try context.fetch(descriptor)

        for routine in routines {
            let remote = RemoteRoutine(
                id: routine.id.uuidString,
                userId: userId,
                name: routine.name,
                notes: routine.notes,
                updatedAt: Date()
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
        _ = try await post(path: "/rest/v1/\(table)", body: body, requiresAuth: true, method: "POST",
                           extraHeaders: ["Prefer": "resolution=merge-duplicates,return=minimal"])
    }

    private func post(
        path: String,
        body: [String: Any],
        requiresAuth: Bool,
        method: String = "POST",
        extraHeaders: [String: String] = [:]
    ) async throws -> [String: Any] {
        let url = baseURL.appendingPathComponent(path)
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

// MARK: - Error

enum SupabaseError: LocalizedError {
    case authFailed(String)
    case encodingFailed
    case httpError(Int, String)

    var errorDescription: String? {
        switch self {
        case .authFailed(let msg): return "Auth failed: \(msg)"
        case .encodingFailed: return "Failed to encode data"
        case .httpError(let code, let msg): return "HTTP \(code): \(msg)"
        }
    }
}
