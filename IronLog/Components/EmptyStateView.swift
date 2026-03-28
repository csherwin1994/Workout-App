import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: IronSpacing.lg) {
            ZStack {
                Circle()
                    .fill(IronColor.accentDim)
                    .frame(width: 80, height: 80)
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(IronColor.accent)
            }

            VStack(spacing: IronSpacing.xs) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(IronColor.label)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(IronColor.labelSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            if let actionTitle, let action {
                IronButton(actionTitle, action: action)
                    .frame(maxWidth: 220)
            }
        }
        .padding(IronSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EmptyStateView(
        icon: "clock",
        title: "No Workouts Yet",
        message: "Your completed workouts will appear here. Start your first session to begin tracking.",
        actionTitle: "Start Workout",
        action: {}
    )
    .background(IronColor.bg)
}
