import SwiftUI

// MARK: - Hex Colour Helper
extension Color {
    init(hex: String) {
        let v = Scanner(string: hex)
        var rgb: UInt64 = 0
        v.scanHexInt64(&rgb)
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8)  & 0xFF) / 255,
            blue:  Double( rgb        & 0xFF) / 255
        )
    }
}

// MARK: - Colour Tokens
enum IronColor {
    // Backgrounds
    static let bg          = Color(hex: "0A0A0B")
    static let surface     = Color(hex: "111113")
    static let surfaceHigh = Color(hex: "1C1C1E")
    static let border      = Color(hex: "2C2C2E")
    static let borderSubtle = Color(hex: "1F1F21")

    // Brand
    static let accent      = Color(hex: "5B8EFF")
    static let accentDim   = Color(hex: "5B8EFF").opacity(0.18)
    static let accentPurple = Color(hex: "A78BFA")
    static let accentGreen  = Color(hex: "30D158")

    // Text
    static let label           = Color.white
    static let labelSecondary  = Color(hex: "8E8E93")
    static let labelTertiary   = Color(hex: "48484A")

    // Semantic
    static let success = Color(hex: "30D158")
    static let warning = Color(hex: "FF9F0A")
    static let danger  = Color(hex: "FF453A")

    // Muscle Groups — vivid for dark backgrounds
    static func muscle(_ group: Exercise.MuscleGroup) -> Color {
        switch group {
        case .chest:     return Color(hex: "FF6B6B")
        case .back:      return Color(hex: "4ECDC4")
        case .shoulders: return Color(hex: "FFD93D")
        case .biceps:    return Color(hex: "6BCB77")
        case .triceps:   return Color(hex: "4D96FF")
        case .legs:      return Color(hex: "C77DFF")
        case .glutes:    return Color(hex: "FF79C6")
        case .core:      return Color(hex: "FF9A3C")
        case .cardio:    return Color(hex: "FF4757")
        case .fullBody:  return Color(hex: "2ED573")
        }
    }
}

// MARK: - Gradients
enum IronGradient {
    static let brand = LinearGradient(
        colors: [Color(hex: "5B8EFF"), Color(hex: "A78BFA")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let brandSubtle = LinearGradient(
        colors: [Color(hex: "5B8EFF").opacity(0.25), Color(hex: "A78BFA").opacity(0.15)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let success = LinearGradient(
        colors: [Color(hex: "30D158"), Color(hex: "00C49A")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let dark = LinearGradient(
        colors: [IronColor.surface, IronColor.bg],
        startPoint: .top, endPoint: .bottom
    )
}

// MARK: - Spacing & Sizing
enum IronSpacing {
    static let xs: CGFloat  = 4
    static let sm: CGFloat  = 8
    static let md: CGFloat  = 16
    static let lg: CGFloat  = 24
    static let xl: CGFloat  = 32
    static let xxl: CGFloat = 48

    static let radius: CGFloat   = 14
    static let radiusLg: CGFloat = 20
    static let radiusSm: CGFloat = 8
    static let radiusXs: CGFloat = 6
}

// MARK: - Typography
enum IronFont {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func mono(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - View Modifiers

extension View {
    /// Standard dark card — surface colour + border
    func ironCard(padding: CGFloat = IronSpacing.md) -> some View {
        self
            .padding(padding)
            .background(IronColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: IronSpacing.radius))
            .overlay(
                RoundedRectangle(cornerRadius: IronSpacing.radius)
                    .stroke(IronColor.border, lineWidth: 0.5)
            )
    }

    /// Section title + content stacked vertically
    func ironSection(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: IronSpacing.sm) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(IronColor.labelSecondary)
                .textCase(.uppercase)
                .tracking(0.6)
                .padding(.horizontal, IronSpacing.md)
            self
        }
    }
}

// MARK: - Muscle Badge
struct MuscleBadge: View {
    let group: Exercise.MuscleGroup

    var body: some View {
        Text(group.rawValue)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(IronColor.muscle(group).opacity(0.15))
            .foregroundStyle(IronColor.muscle(group))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(IronColor.muscle(group).opacity(0.3), lineWidth: 0.5))
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? IronColor.accent : IronColor.surface)
                .foregroundStyle(isSelected ? .white : IronColor.labelSecondary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(
                    isSelected ? Color.clear : IronColor.border, lineWidth: 0.5
                ))
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
