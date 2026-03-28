import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Bindable var vm: ActiveWorkoutViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingExercisePicker = false
    @State private var showingFinish = false
    @State private var showingDiscard = false

    private var sortedLogs: [ExerciseLog] {
        (vm.session?.exerciseLogs ?? []).sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                IronColor.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    headerBar
                    if vm.isRestTimerRunning { restBanner }
                    exerciseList
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerSheet { vm.addExercise($0, context: modelContext) }
        }
        .confirmationDialog("Finish Workout?", isPresented: $showingFinish, titleVisibility: .visible) {
            Button("Finish & Save") { vm.finishWorkout(); dismiss() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Save \(sortedLogs.count) exercises to your history.") }
        .confirmationDialog("Discard Workout?", isPresented: $showingDiscard, titleVisibility: .visible) {
            Button("Discard", role: .destructive) { vm.discardWorkout(context: modelContext); dismiss() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Button { showingDiscard = true } label: {
                    Text("Discard")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(IronColor.danger)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(vm.session?.title ?? "Workout")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(IronColor.label)
                        .lineLimit(1)
                    Text(vm.formattedElapsed)
                        .font(IronFont.mono(22, weight: .bold))
                        .foregroundStyle(IronColor.accent)
                }

                Spacer()

                Button { showingFinish = true } label: {
                    Text("Finish")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(IronGradient.success)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, IronSpacing.md)
            .padding(.vertical, IronSpacing.sm)

            Divider().background(IronColor.border)

            // Volume strip
            let totalVol = vm.session?.totalVolume ?? 0
            let totalSets = vm.session?.totalSets ?? 0
            HStack(spacing: IronSpacing.xl) {
                volumePill(value: "\(totalSets)", label: "sets")
                volumePill(value: totalVol >= 1000
                    ? String(format: "%.1fk", totalVol/1000)
                    : String(format: "%.0f kg", totalVol),
                    label: "volume")
                volumePill(value: "\(sortedLogs.count)", label: "exercises")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(IronColor.surface)

            Divider().background(IronColor.border)
        }
    }

    private func volumePill(value: String, label: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(IronFont.mono(14, weight: .bold))
                .foregroundStyle(IronColor.label)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(IronColor.labelTertiary)
        }
    }

    // MARK: - Rest timer banner
    private var restBanner: some View {
        HStack {
            Image(systemName: "timer").font(.caption.weight(.semibold))
            Text("Rest — \(vm.formattedRest)")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Button("Skip") { vm.stopRestTimer() }
                .font(.caption.weight(.bold))
                .foregroundStyle(IronColor.accent)
        }
        .foregroundStyle(IronColor.warning)
        .padding(.horizontal, IronSpacing.md)
        .padding(.vertical, 10)
        .background(IronColor.warning.opacity(0.1))
        .overlay(Divider().background(IronColor.warning.opacity(0.3)), alignment: .bottom)
    }

    // MARK: - Exercise list
    private var exerciseList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(sortedLogs) { log in
                    ExerciseLogCard(log: log, vm: vm)
                }
                Button { showingExercisePicker = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(IronColor.accent)
                        Text("Add Exercise")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(IronColor.accent)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(IronColor.accentDim)
                    .clipShape(RoundedRectangle(cornerRadius: IronSpacing.radius))
                    .overlay(RoundedRectangle(cornerRadius: IronSpacing.radius)
                        .stroke(IronColor.accent.opacity(0.25), lineWidth: 0.5))
                }
            }
            .padding(IronSpacing.md)
            .padding(.bottom, IronSpacing.xxl)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Exercise log card
struct ExerciseLogCard: View {
    let log: ExerciseLog
    let vm: ActiveWorkoutViewModel
    @Environment(\.modelContext) private var modelContext

    private var sortedSets: [WorkoutSet] {
        log.sets.sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Exercise header
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(log.exerciseName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(IronColor.accent)
                    if let group = Exercise.MuscleGroup(rawValue: log.exerciseMuscleGroup) {
                        MuscleBadge(group: group)
                    }
                }
                Spacer()
                IronIconButton(icon: "ellipsis", action: {})
            }
            .padding(IronSpacing.md)

            Divider().background(IronColor.border)

            // Column headers
            HStack {
                Text("SET").frame(width: 34, alignment: .center)
                Spacer()
                Text("KG").frame(width: 72, alignment: .center)
                Text("REPS").frame(width: 72, alignment: .center)
                Image(systemName: "checkmark").frame(width: 36, alignment: .center)
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(IronColor.labelTertiary)
            .padding(.horizontal, IronSpacing.md)
            .padding(.vertical, 8)

            Divider().background(IronColor.borderSubtle)

            // Sets
            VStack(spacing: 0) {
                ForEach(Array(sortedSets.enumerated()), id: \.element.id) { index, set in
                    SetRow(
                        set: set,
                        setNumber: index + 1,
                        vm: vm
                    )
                    if index < sortedSets.count - 1 {
                        Divider().background(IronColor.borderSubtle).padding(.leading, IronSpacing.md)
                    }
                }
            }

            // Add set
            Button { vm.addSet(to: log, context: modelContext) } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus").font(.caption.weight(.bold))
                    Text("Add Set").font(.caption.weight(.semibold))
                }
                .foregroundStyle(IronColor.labelSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .background(IronColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: IronSpacing.radius))
        .overlay(RoundedRectangle(cornerRadius: IronSpacing.radius)
            .stroke(IronColor.border, lineWidth: 0.5))
    }
}

// MARK: - Set row
struct SetRow: View {
    @Bindable var set: WorkoutSet
    let setNumber: Int
    let vm: ActiveWorkoutViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 0) {
            // Set badge
            Text("\(setNumber)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(set.isCompleted ? IronColor.success : IronColor.labelTertiary)
                .frame(width: 34)

            Spacer()

            // Weight
            TextField("0", value: $set.weight, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(IronFont.mono(16))
                .foregroundStyle(IronColor.label)
                .frame(width: 72)
                .padding(.vertical, 7)
                .background(IronColor.surfaceHigh)
                .clipShape(RoundedRectangle(cornerRadius: IronSpacing.radiusXs))

            // Reps
            TextField("0", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(IronFont.mono(16))
                .foregroundStyle(IronColor.label)
                .frame(width: 72)
                .padding(.vertical, 7)
                .background(IronColor.surfaceHigh)
                .clipShape(RoundedRectangle(cornerRadius: IronSpacing.radiusXs))

            // Complete toggle
            Button { vm.toggleSetComplete(set, context: modelContext) } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(set.isCompleted ? IronColor.success : IronColor.border)
                    .frame(width: 36)
            }
        }
        .padding(.horizontal, IronSpacing.md)
        .padding(.vertical, 10)
        .background(set.isCompleted ? IronColor.success.opacity(0.06) : Color.clear)
        .animation(.easeInOut(duration: 0.2), value: set.isCompleted)
    }
}

// MARK: - Exercise picker sheet
struct ExercisePickerSheet: View {
    let onSelect: (Exercise) -> Void
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var search = ""
    @State private var selectedMuscle: Exercise.MuscleGroup?

    private var filtered: [Exercise] {
        exercises.filter {
            (selectedMuscle == nil || $0.muscleGroup == selectedMuscle) &&
            (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                IronColor.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", isSelected: selectedMuscle == nil) { selectedMuscle = nil }
                            ForEach(Exercise.MuscleGroup.allCases, id: \.self) { g in
                                FilterChip(label: g.rawValue, isSelected: selectedMuscle == g) {
                                    selectedMuscle = selectedMuscle == g ? nil : g
                                }
                            }
                        }
                        .padding(.horizontal, IronSpacing.md)
                        .padding(.vertical, IronSpacing.sm)
                    }
                    Divider().background(IronColor.border)

                    List(filtered) { exercise in
                        Button {
                            onSelect(exercise)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(IronColor.label)
                                HStack(spacing: 6) {
                                    MuscleBadge(group: exercise.muscleGroup)
                                    Text(exercise.equipment.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(IronColor.labelTertiary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(IronColor.surface)
                        .listRowSeparatorTint(IronColor.border)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .searchable(text: $search, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(IronColor.labelSecondary)
                }
            }
        }
    }
}

#Preview("Active Workout") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutSession.self, Exercise.self, Routine.self, configurations: config)
    let ctx = container.mainContext
    let session = WorkoutSession(title: "Push Day")
    ctx.insert(session)
    let log = ExerciseLog(exerciseName: "Bench Press", exerciseMuscleGroup: "Chest")
    ctx.insert(log)
    for (i, (w, r)) in [(80.0,8),(85.0,6),(90.0,4)].enumerated() {
        let s = WorkoutSet(orderIndex: i, weight: w, reps: r)
        s.isCompleted = i == 0
        ctx.insert(s); log.sets.append(s)
    }
    session.exerciseLogs = [log]
    try? ctx.save()
    let vm = ActiveWorkoutViewModel()
    vm.session = session; vm.isActive = true; vm.elapsedSeconds = 847
    return ActiveWorkoutView(vm: vm).modelContainer(container)
}
