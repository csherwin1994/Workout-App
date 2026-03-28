import Foundation

// MARK: - Recommendation result

struct WorkoutRecommendation {
    let title: String
    let reason: String
    let muscleGroups: [String]
    let buttonLabel: String
}

// MARK: - Engine

enum WorkoutRecommendationEngine {

    /// Returns a recommendation based on recent workout history and available routines.
    static func recommend(from sessions: [WorkoutSession], routines: [Routine]) -> WorkoutRecommendation {
        let completed = sessions.filter { $0.endDate != nil }

        // Work out which muscle groups were trained in the last 7 days
        let recentCutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentGroups = Set(
            completed
                .filter { $0.startDate >= recentCutoff }
                .flatMap { $0.exerciseLogs }
                .map { $0.exerciseMuscleGroup }
        )

        // Work out which muscle groups were trained in the last 2 days (too fresh)
        let freshCutoff = Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        let freshGroups = Set(
            completed
                .filter { $0.startDate >= freshCutoff }
                .flatMap { $0.exerciseLogs }
                .map { $0.exerciseMuscleGroup }
        )

        // All muscle groups
        let allGroups = Exercise.MuscleGroup.allCases.map { $0.rawValue }

        // Groups not trained recently at all — highest priority
        let untrained = allGroups.filter { !recentGroups.contains($0) && $0 != "Cardio" }

        // Groups trained recently but not in last 2 days — good to hit again
        let recovered = recentGroups.filter { !freshGroups.contains($0) && $0 != "Cardio" }

        // Build suggestion
        if completed.isEmpty {
            return WorkoutRecommendation(
                title: "Start your first workout",
                reason: "Pick a routine or log your first session to get personalised suggestions.",
                muscleGroups: ["Chest", "Back", "Legs"],
                buttonLabel: "Suggest Workout"
            )
        }

        // Try to find a matching routine for untrained groups
        if let best = bestRoutine(for: untrained, from: routines) {
            let groups = primaryGroups(of: best)
            return WorkoutRecommendation(
                title: best.name,
                reason: "You haven't trained \(groups.first ?? "these muscles") in a while — time to hit it.",
                muscleGroups: groups,
                buttonLabel: "Suggested: \(best.name)"
            )
        }

        // Fall back to recovered groups
        if let best = bestRoutine(for: Array(recovered), from: routines) {
            let groups = primaryGroups(of: best)
            return WorkoutRecommendation(
                title: best.name,
                reason: "\(groups.first ?? "These muscles") are recovered and ready to train again.",
                muscleGroups: groups,
                buttonLabel: "Suggested: \(best.name)"
            )
        }

        // No routines — suggest by muscle group pattern
        let suggested = suggestSplit(recentGroups: recentGroups, freshGroups: freshGroups)
        return WorkoutRecommendation(
            title: suggested.name,
            reason: suggested.reason,
            muscleGroups: suggested.groups,
            buttonLabel: "Suggested: \(suggested.name)"
        )
    }

    // MARK: - Helpers

    private static func primaryGroups(of routine: Routine) -> [String] {
        let groups = routine.exercises.map { $0.exerciseMuscleGroup }
        let counts = Dictionary(groups.map { ($0, 1) }, uniquingKeysWith: +)
        return counts.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
    }

    private static func bestRoutine(for targetGroups: [String], from routines: [Routine]) -> Routine? {
        guard !targetGroups.isEmpty, !routines.isEmpty else { return nil }
        return routines.max(by: { a, b in
            let scoreA = a.exercises.filter { targetGroups.contains($0.exerciseMuscleGroup) }.count
            let scoreB = b.exercises.filter { targetGroups.contains($0.exerciseMuscleGroup) }.count
            return scoreA < scoreB
        })
    }

    private static func suggestSplit(
        recentGroups: Set<String>,
        freshGroups: Set<String>
    ) -> (name: String, reason: String, groups: [String]) {
        // Classic PPL rotation
        let pushGroups  = ["Chest", "Shoulders", "Triceps"]
        let pullGroups  = ["Back", "Biceps"]
        let legGroups   = ["Legs", "Glutes"]

        let pushFresh  = pushGroups.allSatisfy  { freshGroups.contains($0) }
        let pullFresh  = pullGroups.allSatisfy  { freshGroups.contains($0) }
        let legsFresh  = legGroups.allSatisfy   { freshGroups.contains($0) }

        if !legsFresh {
            return ("Leg Day", "Legs haven't been trained recently — a strong session will keep your progress balanced.", legGroups)
        }
        if !pullFresh {
            return ("Pull Day", "Your back and biceps are recovered and ready to go.", pullGroups)
        }
        if !pushFresh {
            return ("Push Day", "Chest, shoulders, and triceps are due for a session.", pushGroups)
        }
        return ("Rest or Cardio", "You've trained all major groups recently — a rest or cardio session is the smart move.", ["Cardio"])
    }
}
