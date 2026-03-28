import SwiftUI

// MARK: - Primary Button
struct IronButton: View {
    enum Style { case primary, secondary, ghost, danger }

    let title: String
    let icon: String?
    let style: Style
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        style: Style = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: IronSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                        .scaleEffect(0.85)
                } else {
                    if let icon { Image(systemName: icon).font(.system(size: 16, weight: .semibold)) }
                    Text(title).font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(backgroundView)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: IronSpacing.radius))
            .overlay(
                RoundedRectangle(cornerRadius: IronSpacing.radius)
                    .stroke(borderColor, lineWidth: 0.5)
            )
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1)
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:   IronGradient.brand
        case .secondary: IronColor.surfaceHigh
        case .ghost:     Color.clear
        case .danger:    IronColor.danger.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:   .white
        case .secondary: IronColor.label
        case .ghost:     IronColor.accent
        case .danger:    IronColor.danger
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary:   Color.clear
        case .secondary: IronColor.border
        case .ghost:     Color.clear
        case .danger:    IronColor.danger.opacity(0.4)
        }
    }
}

// MARK: - Icon Button
struct IronIconButton: View {
    let icon: String
    let action: () -> Void
    var tint: Color = IronColor.labelSecondary

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(IronColor.surfaceHigh)
                .clipShape(Circle())
        }
    }
}

// MARK: - Previews
#Preview {
    VStack(spacing: 12) {
        IronButton("Start Workout", icon: "plus.circle.fill") {}
        IronButton("Browse Routines", icon: "repeat", style: .secondary) {}
        IronButton("Generate AI Workout", icon: "sparkles", style: .ghost) {}
        IronButton("Discard", style: .danger) {}
        IronButton("Generating...", isLoading: true) {}
    }
    .padding()
    .background(IronColor.bg)
}
