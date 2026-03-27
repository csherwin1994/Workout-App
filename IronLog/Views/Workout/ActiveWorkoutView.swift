import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Bindable var vm: ActiveWorkoutViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingExercisePicker = false
    @State private var showingFinishConfirm = false
    @State private var showingDiscardConfirm = false

    var sortedLogs: [ExerciseLog] {
        (vm.session?.exerciseLogs ?? []).sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Timer + rest bar
                    WorkoutHeaderBar(vm: vm)

                    // Exercise logs
                    VStack(spacing: 16) {
                        ForEach(sortedLogs) { log in
                            ExerciseLogCard(log: log, vm: vm)
                        }

                        // Add exercise button
                        Button {
                            showingExercisePicker = true
                        } label: {
                            Label("Add Exercise", systemImage: "plus")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle(vm.session?.title ?? "Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") { showingDiscardConfirm = true }
                        .foregroundStyle(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish") { showingFinishConfirm = true }
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerSheet { exercise in
                vm.addExercise(exercise, context: modelContext)
            }
        }
        .confirmationDialog("Finish Workout?", isPresented: $showingFinishConfirm, titleVisibility: .visible) {
            Button("Finish Workout") {
                vm.finishWorkout()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Save this workout to your history.")
        }
        .confirmationDialog("Discard Workout?", isPresented: $showingDiscardConfirm, titleVisibility: .visible) {
            Button("Discard", role: .destructive) {
                vm.discardWorkout(context: modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct WorkoutHeaderBar: View {
    @Bindable var vm: ActiveWorkoutViewModel

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Label(vm.formattedElapsed, systemImage: "clock")
                    .font(.headline)
                Spacer()
                if vm.isRestTimerRunning {
                    Button {
                        vm.stopRestTimer()
                    } label: {
                        Label(vm.formattedRest, systemImage: "timer")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            Divider()
        }
    }
}

struct ExerciseLogCard: View {
    let log: ExerciseLog
    let vm: ActiveWorkoutViewModel
    @Environment(\.modelContext) private var modelContext

    var sortedSets: [WorkoutSet] {
        log.sets.sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Exercise header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(log.exerciseName)
                        .font(.headline)
                        .foregroundStyle(.blue)
                    Text(log.exerciseMuscleGroup)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Sets header
            HStack {
                Text("SET").frame(width: 36)
                Spacer()
                Text("KG").frame(width: 70)
                Text("REPS").frame(width: 70)
                Text("").frame(width: 36)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .padding(.bottom, 4)

            Divider().padding(.horizontal)

            // Sets
            ForEach(sortedSets) { set in
                SetRow(set: set, setNumber: (sortedSets.firstIndex(where: { $0.id == set.id }) ?? 0) + 1, vm: vm)
            }

            // Add set button
            Button {
                vm.addSet(to: log, context: modelContext)
            } label: {
                Label("Add Set", systemImage: "plus")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

struct SetRow: View {
    @Bindable var set: WorkoutSet
    let setNumber: Int
    let vm: ActiveWorkoutViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HStack(spacing: 8) {
            // Set number / type badge
            Text("\(setNumber)")
                .font(.subheadline.bold())
                .frame(width: 36)
                .foregroundStyle(set.isCompleted ? .white : .primary)
                .background(
                    Circle()
                        .fill(set.isCompleted ? Color.green : Color(.tertiarySystemBackground))
                        .frame(width: 28, height: 28)
                )

            Spacer()

            // Weight
            TextField("0", value: $set.weight, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(width: 70)
                .padding(.vertical, 6)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Reps
            TextField("0", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 70)
                .padding(.vertical, 6)
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Complete toggle
            Button {
                vm.toggleSetComplete(set, context: modelContext)
            } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(set.isCompleted ? .green : .secondary)
                    .font(.title3)
                    .frame(width: 36)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(set.isCompleted ? Color.green.opacity(0.08) : .clear)
        .animation(.easeInOut(duration: 0.2), value: set.isCompleted)
    }
}

struct ExercisePickerSheet: View {
    let onSelect: (Exercise) -> Void
    @Environment(\.dismiss) private var dismiss
    @Query private var exercises: [Exercise]
    @State private var search = ""
    @State private var selectedMuscle: Exercise.MuscleGroup? = nil

    var filtered: [Exercise] {
        exercises.filter { ex in
            let matchesMuscle = selectedMuscle == nil || ex.muscleGroup == selectedMuscle
            let matchesSearch = search.isEmpty || ex.name.localizedCaseInsensitiveContains(search)
            return matchesMuscle && matchesSearch
        }
        .sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Muscle group filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: selectedMuscle == nil) {
                            selectedMuscle = nil
                        }
                        ForEach(Exercise.MuscleGroup.allCases, id: \.self) { group in
                            FilterChip(label: group.rawValue, isSelected: selectedMuscle == group) {
                                selectedMuscle = group
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                Divider()

                List(filtered) { exercise in
                    Button {
                        onSelect(exercise)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name).foregroundStyle(.primary)
                            Text("\(exercise.muscleGroup.rawValue) · \(exercise.equipment.rawValue)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}
