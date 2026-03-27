import SwiftData
import Foundation

@Model
final class Exercise {
    var id: UUID
    var name: String
    var muscleGroup: MuscleGroup
    var equipment: Equipment
    var instructions: String
    var isCustom: Bool

    init(
        name: String,
        muscleGroup: MuscleGroup,
        equipment: Equipment,
        instructions: String = "",
        isCustom: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.instructions = instructions
        self.isCustom = isCustom
    }

    enum MuscleGroup: String, CaseIterable, Codable {
        case chest = "Chest"
        case back = "Back"
        case shoulders = "Shoulders"
        case biceps = "Biceps"
        case triceps = "Triceps"
        case legs = "Legs"
        case glutes = "Glutes"
        case core = "Core"
        case cardio = "Cardio"
        case fullBody = "Full Body"

        var icon: String {
            switch self {
            case .chest: return "figure.arms.open"
            case .back: return "figure.walk"
            case .shoulders: return "figure.strengthtraining.traditional"
            case .biceps: return "dumbbell"
            case .triceps: return "dumbbell"
            case .legs: return "figure.run"
            case .glutes: return "figure.run"
            case .core: return "figure.core.training"
            case .cardio: return "heart.fill"
            case .fullBody: return "figure.mixed.cardio"
            }
        }
    }

    enum Equipment: String, CaseIterable, Codable {
        case barbell = "Barbell"
        case dumbbell = "Dumbbell"
        case machine = "Machine"
        case cablePulley = "Cable/Pulley"
        case bodyweight = "Bodyweight"
        case kettlebell = "Kettlebell"
        case bands = "Bands"
        case other = "Other"
    }
}
