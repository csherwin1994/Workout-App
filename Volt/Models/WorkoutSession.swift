import SwiftData
import Foundation

@Model
final class WorkoutSession {
    var id: UUID
    var title: String
    var startDate: Date
    var endDate: Date?
    var notes: String
    @Relationship(deleteRule: .cascade) var exerciseLogs: [ExerciseLog]

    var duration: TimeInterval {
        guard let end = endDate else {
            return Date().timeIntervalSince(startDate)
        }
        return end.timeIntervalSince(startDate)
    }

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var totalVolume: Double {
        exerciseLogs.flatMap(\.sets).filter(\.isCompleted).reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }

    var totalSets: Int {
        exerciseLogs.flatMap(\.sets).filter(\.isCompleted).count
    }

    init(title: String = "My Workout") {
        self.id = UUID()
        self.title = title
        self.startDate = Date()
        self.notes = ""
        self.exerciseLogs = []
    }
}

@Model
final class ExerciseLog {
    var id: UUID
    var exerciseName: String
    var exerciseMuscleGroup: String
    var orderIndex: Int
    @Relationship(deleteRule: .cascade) var sets: [WorkoutSet]

    var completedSets: [WorkoutSet] {
        sets.filter(\.isCompleted).sorted { $0.orderIndex < $1.orderIndex }
    }

    init(exerciseName: String, exerciseMuscleGroup: String, orderIndex: Int = 0) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.exerciseMuscleGroup = exerciseMuscleGroup
        self.orderIndex = orderIndex
        self.sets = []
    }
}

@Model
final class WorkoutSet {
    var id: UUID
    var orderIndex: Int
    var weight: Double
    var reps: Int
    var rpe: Double?
    var setType: SetType
    var isCompleted: Bool
    var completedAt: Date?

    init(orderIndex: Int = 0, weight: Double = 0, reps: Int = 0, setType: SetType = .normal) {
        self.id = UUID()
        self.orderIndex = orderIndex
        self.weight = weight
        self.reps = reps
        self.setType = setType
        self.isCompleted = false
    }

    enum SetType: String, CaseIterable, Codable {
        case warmup = "W"
        case normal = "N"
        case dropSet = "D"
        case failureSet = "F"

        var color: String {
            switch self {
            case .warmup: return "yellow"
            case .normal: return "blue"
            case .dropSet: return "purple"
            case .failureSet: return "red"
            }
        }
    }
}
