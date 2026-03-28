import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Bindable var vm: ActiveWorkoutViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("weightUnit") private var weightUnit = "kg"
    @State private var showingExercisePicker = false
    @State private var showingFinish = false
    @State private var showingDiscard = false

    private var sortedLogs: [ExerciseLog] {
        (vm.session?.exerciseLogs ?? []).sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VoltColor.bg.ignoresSafeArea()

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
            Button("Finish & Save") { vm.finishWorkout(context: modelContext); dismiss() }
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
                        .foregroundStyle(VoltColor.danger)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(vm.session?.title ?? "Workout")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(VoltColor.label)
                        .lineLimit(1)
                    Text(vm.formattedElapsed)
                        .font(VoltFont.mono(22, weight: .bold))
                        .foregroundStyle(VoltColor.accent)
                }

                Spacer()

                Button { showingFinish = true } label: {
                    Text("Finish")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(VoltGradient.success)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, VoltSpacing.md)
            .padding(.vertical, VoltSpacing.sm)

            Divider().background(VoltColor.border)

            // Volume strip
            let totalVol = vm.session?.totalVolume ?? 0
            let totalSets = vm.session?.totalSets ?? 0
            HStack(spacing: VoltSpacing.xl) {
                volumePill(value: "\(totalSets)", label: "sets")
                volumePill(value: totalVol >= 1000
                    ? String(format: "%.1fk", totalVol/1000)
                    : String(format: "%.0f \(weightUnit)", totalVol),
                    label: "volume")
                volumePill(value: "\(sortedLogs.count)", label: "exercises")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(VoltColor.surface)

            Divider().background(VoltColor.border)
        }
    }

    private func volumePill(value: String, label: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(VoltFont.mono(14, weight: .bold))
                .foregroundStyle(VoltColor.label)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(VoltColor.labelTertiary)
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
                .foregroundStyle(VoltColor.accent)
        }
        .foregroundStyle(VoltColor.warning)
        .padding(.horizontal, VoltSpacing.md)
        .padding(.vertical, 10)
        .background(VoltColor.warning.opacity(0.1))
        .overlay(Divider().background(VoltColor.warning.opacity(0.3)), alignment: .bottom)
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
                            .foregroundStyle(VoltColor.accent)
                        Text("Add Exercise")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(VoltColor.accent)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(VoltColor.accentDim)
                    .clipShape(RoundedRectangle(cornerRadius: VoltSpacing.radius))
                    .overlay(RoundedRectangle(cornerRadius: VoltSpacing.radius)
                        .stroke(VoltColor.accent.opacity(0.25), lineWidth: 0.5))
                }
            }
            .padding(VoltSpacing.md)
            .padding(.bottom, VoltSpacing.xxl)
        }
        .scrollIndicators(.hidden)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(VoltColor.accent)
            }
        }
    }
}

// MARK: - Exercise log card
struct ExerciseLogCard: View {
    let log: ExerciseLog
    let vm: ActiveWorkoutViewModel
    @Environment(\.modelContext) private var modelContext
    @AppStorage("weightUnit") private var weightUnit = "kg"
    @State private var showingRemove = false

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
                        .foregroundStyle(VoltColor.accent)
                    if let group = Exercise.MuscleGroup(rawValue: log.exerciseMuscleGroup) {
                        MuscleBadge(group: group)
                    }
                }
                Spacer()
                VoltIconButton(icon: "ellipsis", action: { showingRemove = true })
            }
            .padding(VoltSpacing.md)

            Divider().background(VoltColor.border)

            // Column headers
            HStack {
                Text("SET").frame(width: 34, alignment: .center)
                Spacer()
                Text(weightUnit.uppercased()).frame(width: 72, alignment: .center)
                Text("REPS").frame(width: 72, alignment: .center)
                Image(systemName: "checkmark").frame(width: 36, alignment: .center)
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(VoltColor.labelTertiary)
            .padding(.horizontal, VoltSpacing.md)
            .padding(.vertical, 8)

            Divider().background(VoltColor.borderSubtle)

            // Sets
            VStack(spacing: 0) {
                ForEach(Array(sortedSets.enumerated()), id: \.element.id) { index, set in
                    SetRow(
                        set: set,
                        setNumber: index + 1,
                        vm: vm
                    )
                    if index < sortedSets.count - 1 {
                        Divider().background(VoltColor.borderSubtle).padding(.leading, VoltSpacing.md)
                    }
                }
            }

            // Add set
            Button { vm.addSet(to: log, context: modelContext) } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus").font(.caption.weight(.bold))
                    Text("Add Set").font(.caption.weight(.semibold))
                }
                .foregroundStyle(VoltColor.labelSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .background(VoltColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: VoltSpacing.radius))
        .overlay(RoundedRectangle(cornerRadius: VoltSpacing.radius)
            .stroke(VoltColor.border, lineWidth: 0.5))
        .confirmationDialog("Remove \(log.exerciseName)?", isPresented: $showingRemove, titleVisibility: .visible) {
            Button("Remove Exercise", role: .destructive) {
                vm.session?.exerciseLogs.removeAll { $0.id == log.id }
                modelContext.delete(log)
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {}
        }
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
                .foregroundStyle(set.isCompleted ? VoltColor.success : VoltColor.labelTertiary)
                .frame(width: 34)

            Spacer()

            // Weight
            TextField("0", value: $set.weight, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(VoltFont.mono(16))
                .foregroundStyle(VoltColor.label)
                .frame(width: 72)
                .padding(.vertical, 7)
                .background(VoltColor.surfaceHigh)
                .clipShape(RoundedRectangle(cornerRadius: VoltSpacing.radiusXs))

            // Reps
            TextField("0", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(VoltFont.mono(16))
                .foregroundStyle(VoltColor.label)
                .frame(width: 72)
                .padding(.vertical, 7)
                .background(VoltColor.surfaceHigh)
                .clipShape(RoundedRectangle(cornerRadius: VoltSpacing.radiusXs))

            // Complete toggle
            Button { vm.toggleSetComplete(set, context: modelContext) } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(set.isCompleted ? VoltColor.success : VoltColor.border)
                    .frame(width: 36)
            }
        }
        .padding(.horizontal, VoltSpacing.md)
        .padding(.vertical, 10)
        .background(set.isCompleted ? VoltColor.success.opacity(0.06) : Color.clear)
        .animation(.easeInOut(duration: 0.2), value: set.isCompleted)
    }
}

// MARK: - Exercise picker sheet
struct ExercisePickerSheet: View {
    let onSelect: (Exercise) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
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
                VoltColor.bg.ignoresSafeArea()
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
                        .padding(.horizontal, VoltSpacing.md)
                        .padding(.vertical, VoltSpacing.sm)
                    }
                    Divider().background(VoltColor.border)

                    if exercises.isEmpty {
                        VStack(spacing: VoltSpacing.md) {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(VoltColor.labelTertiary)
                            Text("Exercise library is empty")
                                .font(.headline)
                                .foregroundStyle(VoltColor.label)
                            Text("Visit the Exercises tab to browse and manage your library.")
                                .font(.subheadline)
                                .foregroundStyle(VoltColor.labelSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, VoltSpacing.xl)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filtered.isEmpty {
                        VStack(spacing: VoltSpacing.md) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundStyle(VoltColor.labelTertiary)
                            Text("No exercises found")
                                .font(.headline)
                                .foregroundStyle(VoltColor.label)
                            Text("Try a different search or muscle group filter.")
                                .font(.subheadline)
                                .foregroundStyle(VoltColor.labelSecondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(filtered) { exercise in
                            Button {
                                onSelect(exercise)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(VoltColor.muscle(exercise.muscleGroup).opacity(0.12))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: exercise.icon)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(VoltColor.muscle(exercise.muscleGroup))
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(exercise.name)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(VoltColor.label)
                                        HStack(spacing: 6) {
                                            MuscleBadge(group: exercise.muscleGroup)
                                            Text(exercise.equipment.rawValue)
                                                .font(.caption)
                                                .foregroundStyle(VoltColor.labelTertiary)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(VoltColor.surface)
                            .listRowSeparatorTint(VoltColor.border)
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .searchable(text: $search, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(VoltColor.labelSecondary)
                }
            }
            .onAppear { DataManager.seedExercisesIfNeeded(context: modelContext) }
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
