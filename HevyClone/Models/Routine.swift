import SwiftData
import Foundation

@Model
final class Routine {
    var id: UUID
    var name: String
    var notes: String
    var createdAt: Date
    var lastUsedAt: Date?
    @Relationship(deleteRule: .cascade) var exercises: [RoutineExercise]

    var exerciseCount: Int { exercises.count }

    init(name: String, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.notes = notes
        self.createdAt = Date()
        self.exercises = []
    }
}

@Model
final class RoutineExercise {
    var id: UUID
    var exerciseName: String
    var exerciseMuscleGroup: String
    var orderIndex: Int
    var targetSets: Int
    var targetReps: Int
    var targetWeight: Double

    init(
        exerciseName: String,
        exerciseMuscleGroup: String,
        orderIndex: Int = 0,
        targetSets: Int = 3,
        targetReps: Int = 10,
        targetWeight: Double = 0
    ) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.exerciseMuscleGroup = exerciseMuscleGroup
        self.orderIndex = orderIndex
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeight = targetWeight
    }
}
