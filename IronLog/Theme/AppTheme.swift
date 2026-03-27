import SwiftUI

enum AppTheme {
    // MARK: – Accent
    static let accent = Color.blue

    // MARK: – Muscle group colors
    static func muscleColor(_ group: Exercise.MuscleGroup) -> Color {
        switch group {
        case .chest:     return Color(red: 0.95, green: 0.35, blue: 0.35)
        case .back:      return Color(red: 0.25, green: 0.60, blue: 0.95)
        case .shoulders: return Color(red: 0.95, green: 0.65, blue: 0.15)
        case .biceps:    return Color(red: 0.40, green: 0.80, blue: 0.45)
        case .triceps:   return Color(red: 0.30, green: 0.70, blue: 0.55)
        case .legs:      return Color(red: 0.70, green: 0.40, blue: 0.90)
        case .glutes:    return Color(red: 0.85, green: 0.45, blue: 0.75)
        case .core:      return Color(red: 0.95, green: 0.55, blue: 0.20)
        case .cardio:    return Color(red: 0.95, green: 0.25, blue: 0.45)
        case .fullBody:  return Color(red: 0.20, green: 0.70, blue: 0.80)
        }
    }

    // MARK: – Gradients
    static let heroGradient = LinearGradient(
        colors: [Color.blue, Color(red: 0.35, green: 0.20, blue: 0.95)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static func muscleGradient(_ group: Exercise.MuscleGroup) -> LinearGradient {
        let base = muscleColor(group)
        return LinearGradient(colors: [base, base.opacity(0.7)],
                              startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // MARK: – Card
    static var cardBackground: some ShapeStyle { Color(.secondarySystemBackground) }

    // MARK: – Spacing
    static let cardPadding: CGFloat = 16
    static let cornerRadius: CGFloat = 14
    static let sectionSpacing: CGFloat = 20
}

// MARK: – View helpers
extension View {
    func ironCard() -> some View {
        self
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }

    func sectionHeader(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())
                .padding(.horizontal)
            self
        }
    }
}

// MARK: – Muscle badge
struct MuscleBadge: View {
    let group: Exercise.MuscleGroup

    var body: some View {
        Text(group.rawValue)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(AppTheme.muscleColor(group).opacity(0.18))
            .foregroundStyle(AppTheme.muscleColor(group))
            .clipShape(Capsule())
    }
}
