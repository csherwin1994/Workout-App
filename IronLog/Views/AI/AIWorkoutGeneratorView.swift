import SwiftUI
import SwiftData

// MARK: - Root sheet
struct AIWorkoutGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ActiveWorkoutViewModel.self) private var workoutVM

    @State private var service = AIWorkoutService()
    @State private var step: Step = .configure
    @State private var focus: WorkoutFocus = .push
    @State private var duration: Int = 45
    @State private var equipment: EquipmentLevel = .fullGym
    @State private var experience: ExperienceLevel = .intermediate
    @State private var showingStartConfirm = false

    enum Step { case configure, result }

    var body: some View {
        NavigationStack {
            ZStack {
                IronColor.bg.ignoresSafeArea()

                switch step {
                case .configure:
                    ConfigureView(
                        focus: $focus,
                        duration: $duration,
                        equipment: $equipment,
                        experience: $experience
                    ) {
                        Task { await generate() }
                    }
                    .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))

                case .result:
                    ResultView(
                        service: service,
                        onRegenerate: { Task { await generate() } },
                        onStartWorkout: { startWorkout() },
                        onSaveRoutine: { saveAsRoutine() },
                        onBack: { withAnimation { step = .configure } }
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(IronColor.labelSecondary)
                }
            }
        }
    }

    private func generate() async {
        withAnimation(.spring(duration: 0.35)) { step = .result }
        await service.generate(
            focus: focus,
            durationMinutes: duration,
            equipment: equipment,
            experience: experience
        )
    }

    private func startWorkout() {
        guard case .success(let workout) = service.state else { return }
        workoutVM.startFromGenerated(workout, context: modelContext)
        dismiss()
    }

    private func saveAsRoutine() {
        guard case .success(let workout) = service.state else { return }
        let routine = Routine(name: workout.title)
        modelContext.insert(routine)
        for (i, ex) in workout.exercises.enumerated() {
            let re = RoutineExercise(
                exerciseName: ex.name,
                exerciseMuscleGroup: ex.muscleGroup,
                orderIndex: i,
                targetSets: ex.sets,
                targetReps: ex.reps,
                targetWeight: ex.weight
            )
            modelContext.insert(re)
            routine.exercises.append(re)
        }
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Step 1: Configure
private struct ConfigureView: View {
    @Binding var focus: WorkoutFocus
    @Binding var duration: Int
    @Binding var equipment: EquipmentLevel
    @Binding var experience: ExperienceLevel
    let onGenerate: () -> Void

    private let durations = [30, 45, 60, 75, 90]

    var body: some View {
        ScrollView {
            VStack(spacing: IronSpacing.xl) {
                // Header
                VStack(spacing: IronSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(IronGradient.brand)
                            .frame(width: 64, height: 64)
                        Image(systemName: "sparkles")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    }
                    Text("AI Workout Builder")
                        .font(.title2.bold())
                        .foregroundStyle(IronColor.label)
                    Text("Tell us what you want and we'll build the perfect session")
                        .font(.subheadline)
                        .foregroundStyle(IronColor.labelSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, IronSpacing.lg)

                // Focus picker
                VStack(alignment: .leading, spacing: IronSpacing.sm) {
                    sectionLabel("What's your focus?")
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                        ForEach(WorkoutFocus.allCases) { f in
                            FocusCard(focus: f, isSelected: focus == f) { focus = f }
                        }
                    }
                }
                .padding(.horizontal, IronSpacing.md)

                // Duration picker
                VStack(alignment: .leading, spacing: IronSpacing.sm) {
                    sectionLabel("How long?")
                    HStack(spacing: 10) {
                        ForEach(durations, id: \.self) { d in
                            Button {
                                withAnimation(.spring(duration: 0.2)) { duration = d }
                            } label: {
                                VStack(spacing: 2) {
                                    Text("\(d)").font(.system(size: 18, weight: .bold))
                                    Text("min").font(.caption2)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(duration == d ? IronColor.accent : IronColor.surface)
                                .foregroundStyle(duration == d ? .white : IronColor.labelSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: IronSpacing.radiusSm))
                                .overlay(RoundedRectangle(cornerRadius: IronSpacing.radiusSm)
                                    .stroke(duration == d ? Color.clear : IronColor.border, lineWidth: 0.5))
                            }
                        }
                    }
                }
                .padding(.horizontal, IronSpacing.md)

                // Equipment picker
                VStack(alignment: .leading, spacing: IronSpacing.sm) {
                    sectionLabel("Equipment available")
                    HStack(spacing: 10) {
                        ForEach(EquipmentLevel.allCases) { eq in
                            Button {
                                withAnimation(.spring(duration: 0.2)) { equipment = eq }
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: eq.icon)
                                        .font(.system(size: 20, weight: .medium))
                                    Text(eq.rawValue)
                                        .font(.caption.weight(.medium))
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 70)
                                .background(equipment == eq ? IronColor.accentDim : IronColor.surface)
                                .foregroundStyle(equipment == eq ? IronColor.accent : IronColor.labelSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: IronSpacing.radiusSm))
                                .overlay(RoundedRectangle(cornerRadius: IronSpacing.radiusSm)
                                    .stroke(equipment == eq ? IronColor.accent.opacity(0.4) : IronColor.border, lineWidth: 0.5))
                            }
                        }
                    }
                }
                .padding(.horizontal, IronSpacing.md)

                // Experience picker
                VStack(alignment: .leading, spacing: IronSpacing.sm) {
                    sectionLabel("Experience level")
                    HStack(spacing: 10) {
                        ForEach(ExperienceLevel.allCases) { lvl in
                            Button {
                                withAnimation(.spring(duration: 0.2)) { experience = lvl }
                            } label: {
                                Text(lvl.rawValue)
                                    .font(.system(size: 13, weight: .medium))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(experience == lvl ? IronColor.surface : IronColor.surfaceHigh)
                                    .foregroundStyle(experience == lvl ? IronColor.label : IronColor.labelSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: IronSpacing.radiusSm))
                                    .overlay(RoundedRectangle(cornerRadius: IronSpacing.radiusSm)
                                        .stroke(experience == lvl ? IronColor.accent : IronColor.border, lineWidth: experience == lvl ? 1 : 0.5))
                            }
                        }
                    }
                }
                .padding(.horizontal, IronSpacing.md)

                // Generate button
                IronButton("Generate My Workout", icon: "sparkles", action: onGenerate)
                    .padding(.horizontal, IronSpacing.md)
                    .padding(.bottom, IronSpacing.xl)
            }
        }
        .scrollIndicators(.hidden)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(IronColor.labelSecondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

// MARK: - Focus card
private struct FocusCard: View {
    let focus: WorkoutFocus
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: focus.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isSelected ? .white : focus.color)
                Text(focus.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isSelected ? .white.opacity(0.9) : IronColor.labelSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .background(isSelected
                ? focus.color
                : focus.color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: IronSpacing.radiusSm))
            .overlay(RoundedRectangle(cornerRadius: IronSpacing.radiusSm)
                .stroke(isSelected ? Color.clear : focus.color.opacity(0.25), lineWidth: 0.5))
        }
        .animation(.spring(duration: 0.2), value: isSelected)
    }
}

// MARK: - Step 2: Result
private struct ResultView: View {
    let service: AIWorkoutService
    let onRegenerate: () -> Void
    let onStartWorkout: () -> Void
    let onSaveRoutine: () -> Void
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: IronSpacing.lg) {
                switch service.state {
                case .idle:
                    EmptyView()

                case .loading:
                    LoadingCard()
                        .padding(.top, IronSpacing.xxl)

                case .missingKey:
                    MissingKeyCard()

                case .failure(let msg):
                    FailureCard(message: msg, onRetry: onRegenerate, onBack: onBack)

                case .success(let workout):
                    WorkoutPreviewCard(workout: workout)
                    actionButtons
                }
            }
            .padding(.vertical, IronSpacing.lg)
        }
        .scrollIndicators(.hidden)
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            IronButton("Start Workout Now", icon: "play.fill", action: onStartWorkout)
            IronButton("Save as Routine", icon: "bookmark.fill", style: .secondary, action: onSaveRoutine)
            IronButton("Regenerate", icon: "arrow.clockwise", style: .ghost, action: onRegenerate)
        }
        .padding(.horizontal, IronSpacing.md)
        .padding(.bottom, IronSpacing.xl)
    }
}

// MARK: - Loading card
private struct LoadingCard: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: IronSpacing.xl) {
            ZStack {
                Circle()
                    .fill(IronGradient.brandSubtle)
                    .frame(width: 100, height: 100)
                    .scaleEffect(pulse ? 1.15 : 1)
                    .opacity(pulse ? 0.4 : 0.8)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulse)

                Image(systemName: "sparkles")
                    .font(.system(size: 38))
                    .foregroundStyle(IronGradient.brand)
                    .symbolEffect(.variableColor.cumulative, isActive: true)
            }
            .onAppear { pulse = true }

            VStack(spacing: IronSpacing.xs) {
                Text("Building your workout…")
                    .font(.title3.bold())
                    .foregroundStyle(IronColor.label)
                Text("Our AI coach is crafting the perfect session for you")
                    .font(.subheadline)
                    .foregroundStyle(IronColor.labelSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(IronSpacing.xl)
    }
}

// MARK: - Missing key
private struct MissingKeyCard: View {
    var body: some View {
        VStack(spacing: IronSpacing.md) {
            Image(systemName: "key.fill")
                .font(.system(size: 36))
                .foregroundStyle(IronColor.warning)
            Text("API Key Required")
                .font(.title3.bold())
                .foregroundStyle(IronColor.label)
            Text("Add your Anthropic API key in Profile → Settings to use AI workout generation.")
                .font(.subheadline)
                .foregroundStyle(IronColor.labelSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(IronSpacing.xl)
        .ironCard(padding: IronSpacing.xl)
        .padding(.horizontal, IronSpacing.md)
    }
}

// MARK: - Failure card
private struct FailureCard: View {
    let message: String
    let onRetry: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: IronSpacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(IronColor.danger)
            Text("Generation Failed")
                .font(.title3.bold())
                .foregroundStyle(IronColor.label)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(IronColor.labelSecondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                IronButton("Try Again", icon: "arrow.clockwise", action: onRetry)
                IronButton("Back", style: .secondary, action: onBack)
            }
        }
        .padding(IronSpacing.xl)
        .ironCard(padding: IronSpacing.xl)
        .padding(.horizontal, IronSpacing.md)
    }
}

// MARK: - Workout preview
private struct WorkoutPreviewCard: View {
    let workout: GeneratedWorkout

    var body: some View {
        VStack(alignment: .leading, spacing: IronSpacing.md) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(IronColor.accentPurple)
                        Text("AI Generated")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(IronColor.accentPurple)
                    }
                    Text(workout.title)
                        .font(.title3.bold())
                        .foregroundStyle(IronColor.label)
                }
                Spacer()
                HStack(spacing: 12) {
                    statPill("\(workout.exercises.count)", icon: "dumbbell.fill")
                    statPill("~\(workout.estimatedMinutes)m", icon: "clock.fill")
                }
            }

            Divider().background(IronColor.border)

            // Exercise list
            VStack(spacing: 12) {
                ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { idx, ex in
                    GeneratedExerciseRow(index: idx + 1, exercise: ex)
                }
            }
        }
        .ironCard(padding: IronSpacing.md)
        .padding(.horizontal, IronSpacing.md)
    }

    private func statPill(_ value: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(value).font(.caption.weight(.medium))
        }
        .foregroundStyle(IronColor.labelSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(IronColor.surfaceHigh)
        .clipShape(Capsule())
    }
}

private struct GeneratedExerciseRow: View {
    let index: Int
    let exercise: GeneratedExercise

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(IronColor.accent)
                .frame(width: 22, height: 22)
                .background(IronColor.accentDim)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(IronColor.label)

                HStack(spacing: 10) {
                    Text("\(exercise.sets) sets × \(exercise.reps) reps")
                        .font(.caption)
                        .foregroundStyle(IronColor.labelSecondary)
                    if exercise.weight > 0 {
                        Text("@ \(String(format: "%.0f", exercise.weight)) kg")
                            .font(.caption)
                            .foregroundStyle(IronColor.accent)
                    }
                }

                if !exercise.notes.isEmpty {
                    Text(exercise.notes)
                        .font(.caption)
                        .foregroundStyle(IronColor.labelTertiary)
                        .italic()
                }
            }

            Spacer()

            Text("\(exercise.restSeconds)s rest")
                .font(.caption2.weight(.medium))
                .foregroundStyle(IronColor.labelTertiary)
        }
    }
}

#Preview("Configure") {
    AIWorkoutGeneratorView()
        .modelContainer(for: [WorkoutSession.self, Exercise.self, Routine.self], inMemory: true)
        .environment(ActiveWorkoutViewModel())
}
