import SwiftData
import Foundation

/// Seeds the app with a default exercise library on first launch.
struct DataManager {
    static func seedExercisesIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let exercises: [(String, Exercise.MuscleGroup, Exercise.Equipment)] = [
            // Chest
            ("Bench Press", .chest, .barbell),
            ("Incline Bench Press", .chest, .barbell),
            ("Decline Bench Press", .chest, .barbell),
            ("Dumbbell Fly", .chest, .dumbbell),
            ("Cable Fly", .chest, .cablePulley),
            ("Push Up", .chest, .bodyweight),
            ("Chest Dip", .chest, .bodyweight),

            // Back
            ("Deadlift", .back, .barbell),
            ("Barbell Row", .back, .barbell),
            ("Pull Up", .back, .bodyweight),
            ("Lat Pulldown", .back, .machine),
            ("Seated Cable Row", .back, .cablePulley),
            ("Dumbbell Row", .back, .dumbbell),
            ("T-Bar Row", .back, .barbell),
            ("Face Pull", .back, .cablePulley),

            // Shoulders
            ("Overhead Press", .shoulders, .barbell),
            ("Dumbbell Shoulder Press", .shoulders, .dumbbell),
            ("Lateral Raise", .shoulders, .dumbbell),
            ("Front Raise", .shoulders, .dumbbell),
            ("Arnold Press", .shoulders, .dumbbell),
            ("Upright Row", .shoulders, .barbell),

            // Biceps
            ("Barbell Curl", .biceps, .barbell),
            ("Dumbbell Curl", .biceps, .dumbbell),
            ("Hammer Curl", .biceps, .dumbbell),
            ("Preacher Curl", .biceps, .machine),
            ("Cable Curl", .biceps, .cablePulley),
            ("Incline Dumbbell Curl", .biceps, .dumbbell),

            // Triceps
            ("Tricep Pushdown", .triceps, .cablePulley),
            ("Skull Crusher", .triceps, .barbell),
            ("Close Grip Bench Press", .triceps, .barbell),
            ("Overhead Tricep Extension", .triceps, .dumbbell),
            ("Tricep Dip", .triceps, .bodyweight),
            ("Kickback", .triceps, .dumbbell),

            // Legs
            ("Squat", .legs, .barbell),
            ("Front Squat", .legs, .barbell),
            ("Leg Press", .legs, .machine),
            ("Romanian Deadlift", .legs, .barbell),
            ("Leg Extension", .legs, .machine),
            ("Leg Curl", .legs, .machine),
            ("Calf Raise", .legs, .machine),
            ("Lunge", .legs, .bodyweight),
            ("Bulgarian Split Squat", .legs, .dumbbell),

            // Glutes
            ("Hip Thrust", .glutes, .barbell),
            ("Glute Bridge", .glutes, .bodyweight),
            ("Cable Kickback", .glutes, .cablePulley),

            // Core
            ("Plank", .core, .bodyweight),
            ("Crunch", .core, .bodyweight),
            ("Ab Rollout", .core, .other),
            ("Hanging Leg Raise", .core, .bodyweight),
            ("Russian Twist", .core, .bodyweight),
            ("Cable Crunch", .core, .cablePulley),

            // Cardio
            ("Treadmill", .cardio, .machine),
            ("Cycling", .cardio, .machine),
            ("Jump Rope", .cardio, .other),
            ("Rowing Machine", .cardio, .machine),
        ]

        for (name, muscle, equipment) in exercises {
            context.insert(Exercise(name: name, muscleGroup: muscle, equipment: equipment))
        }

        try? context.save()
    }
}
