import SwiftUI
import Foundation

// MARK: - Domain Types

enum WorkoutFocus: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    case push      = "Push"
    case pull      = "Pull"
    case legs      = "Legs"
    case upper     = "Upper Body"
    case lower     = "Lower Body"
    case fullBody  = "Full Body"
    case chest     = "Chest"
    case back      = "Back"
    case shoulders = "Shoulders"
    case arms      = "Arms"
    case core      = "Core"
    case cardio    = "Cardio"

    var icon: String {
        switch self {
        case .push:      return "arrow.up.circle.fill"
        case .pull:      return "arrow.down.circle.fill"
        case .legs:      return "figure.run"
        case .upper:     return "figure.arms.open"
        case .lower:     return "figure.walk"
        case .fullBody:  return "figure.mixed.cardio"
        case .chest:     return "heart.fill"
        case .back:      return "arrow.backward.circle.fill"
        case .shoulders: return "sparkle"
        case .arms:      return "dumbbell.fill"
        case .core:      return "circle.grid.cross.fill"
        case .cardio:    return "bolt.fill"
        }
    }

    var color: Color {
        switch self {
        case .push:      return Color(hex: "5B8EFF")
        case .pull:      return Color(hex: "4ECDC4")
        case .legs:      return Color(hex: "C77DFF")
        case .upper:     return Color(hex: "FF9A3C")
        case .lower:     return Color(hex: "FF6B6B")
        case .fullBody:  return Color(hex: "2ED573")
        case .chest:     return Color(hex: "FF6B6B")
        case .back:      return Color(hex: "4ECDC4")
        case .shoulders: return Color(hex: "FFD93D")
        case .arms:      return Color(hex: "6BCB77")
        case .core:      return Color(hex: "FF9A3C")
        case .cardio:    return Color(hex: "FF4757")
        }
    }
}

enum EquipmentLevel: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case fullGym    = "Full Gym"
    case dumbbells  = "Dumbbells"
    case bodyweight = "Bodyweight"

    var icon: String {
        switch self {
        case .fullGym:    return "building.2.fill"
        case .dumbbells:  return "dumbbell.fill"
        case .bodyweight: return "figure.strengthtraining.traditional"
        }
    }
}

enum ExperienceLevel: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case beginner     = "Beginner"
    case intermediate = "Intermediate"
    case advanced     = "Advanced"
}

// MARK: - Generated Workout

struct GeneratedWorkout: Identifiable {
    let id = UUID()
    let title: String
    let exercises: [GeneratedExercise]
    let focus: WorkoutFocus
    let estimatedMinutes: Int
}

struct GeneratedExercise: Identifiable {
    let id = UUID()
    let name: String
    let muscleGroup: String
    let sets: Int
    let reps: Int
    let weight: Double
    let restSeconds: Int
    let notes: String
}

// MARK: - Codable API Response
private struct APIWorkout: Codable {
    let title: String
    let exercises: [APIExercise]
}

private struct APIExercise: Codable {
    let name: String
    let muscle_group: String
    let sets: Int
    let reps: Int
    let weight_kg: Double
    let rest_seconds: Int
    let notes: String
}

// MARK: - Service

@Observable
final class AIWorkoutService {

    enum State: Equatable {
        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading): return true
            case (.success, .success): return true
            case (.missingKey, .missingKey): return true
            case (.failure(let a), .failure(let b)): return a == b
            default: return false
            }
        }
        case idle
        case loading
        case success(GeneratedWorkout)
        case missingKey
        case failure(String)
    }

    var state: State = .idle

    @ObservationIgnored @AppStorage("anthropicAPIKey") private var apiKey: String = ""

    var hasAPIKey: Bool { !apiKey.trimmingCharacters(in: .whitespaces).isEmpty }

    // MARK: - Public

    func generate(
        focus: WorkoutFocus,
        durationMinutes: Int,
        equipment: EquipmentLevel,
        experience: ExperienceLevel
    ) async {
        guard hasAPIKey else { state = .missingKey; return }
        state = .loading

        let prompt = buildPrompt(focus: focus, duration: durationMinutes,
                                 equipment: equipment, experience: experience)
        do {
            let raw = try await callClaude(userPrompt: prompt)
            let workout = try parse(raw, focus: focus, duration: durationMinutes)
            state = .success(workout)
        } catch let err as AIError {
            state = .failure(err.message)
        } catch {
            state = .failure("Something went wrong. Please try again.")
        }
    }

    func reset() { state = .idle }

    // MARK: - Private

    private func buildPrompt(
        focus: WorkoutFocus,
        duration: Int,
        equipment: EquipmentLevel,
        experience: ExperienceLevel
    ) -> String {
        """
        Create a \(duration)-minute \(focus.rawValue) workout for a \(experience.rawValue.lowercased()) \
        using \(equipment.rawValue.lowercased()) equipment.

        Return ONLY a JSON object with this exact structure — no markdown, no explanation:
        {
          "title": "<catchy workout title>",
          "exercises": [
            {
              "name": "<exercise name>",
              "muscle_group": "<primary muscle group>",
              "sets": <number>,
              "reps": <number>,
              "weight_kg": <number, 0 for bodyweight>,
              "rest_seconds": <number>,
              "notes": "<form tip or modification>"
            }
          ]
        }

        Guidelines:
        - Include 4–7 exercises appropriate for the duration
        - Order exercises from compound to isolation
        - For bodyweight, weight_kg should be 0
        - Rest 60–120s for compounds, 45–90s for isolation
        - notes should be concise (under 12 words)
        - muscle_group must be one of: Chest, Back, Shoulders, Biceps, Triceps, Legs, Glutes, Core, Cardio, Full Body
        """
    }

    private func callClaude(userPrompt: String) async throws -> String {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw AIError.network("Invalid API URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 1024,
            "system": "You are an expert personal trainer. Always respond with valid JSON only — no markdown fences, no extra text.",
            "messages": [["role": "user", "content": userPrompt]]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AIError.network("No HTTP response")
        }
        guard http.statusCode == 200 else {
            if http.statusCode == 401 { throw AIError.auth("Invalid API key. Check your key in Profile.") }
            throw AIError.network("API error \(http.statusCode). Please try again.")
        }

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = json["content"] as? [[String: Any]],
            let first = content.first,
            let text = first["text"] as? String
        else {
            throw AIError.parse("Unexpected API response format.")
        }

        return text
    }

    private func parse(_ text: String, focus: WorkoutFocus, duration: Int) throws -> GeneratedWorkout {
        // Strip any accidental markdown fences
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw AIError.parse("Could not read AI response.")
        }

        let decoded = try JSONDecoder().decode(APIWorkout.self, from: data)

        let exercises = decoded.exercises.map { e in
            GeneratedExercise(
                name: e.name,
                muscleGroup: e.muscle_group,
                sets: e.sets,
                reps: e.reps,
                weight: e.weight_kg,
                restSeconds: e.rest_seconds,
                notes: e.notes
            )
        }

        return GeneratedWorkout(
            title: decoded.title,
            exercises: exercises,
            focus: focus,
            estimatedMinutes: duration
        )
    }
}

// MARK: - Errors
enum AIError: Error {
    case network(String)
    case auth(String)
    case parse(String)

    var message: String {
        switch self {
        case .network(let m), .auth(let m), .parse(let m): return m
        }
    }
}
