import SwiftUI
import SwiftData

struct WorkoutTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var workoutVM = ActiveWorkoutViewModel()
    @State private var showingActiveWorkout = false
    @State private var showingRoutinePicker = false
    @Query private var routines: [Routine]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Active workout banner
                    if workoutVM.isActive {
                        ActiveWorkoutBanner(vm: workoutVM)
                            .onTapGesture { showingActiveWorkout = true }
                    }

                    // Start buttons
                    VStack(spacing: 12) {
                        Button {
                            workoutVM.startWorkout(context: modelContext)
                            showingActiveWorkout = true
                        } label: {
                            Label("Start Empty Workout", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(workoutVM.isActive)

                        Button {
                            showingRoutinePicker = true
                        } label: {
                            Label("Start from Routine", systemImage: "repeat")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)

                    // Recent routines
                    if !routines.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("My Routines")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(routines.prefix(3)) { routine in
                                RoutineQuickStartCard(routine: routine) {
                                    workoutVM.startFromRoutine(routine, context: modelContext)
                                    showingActiveWorkout = true
                                }
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Workout")
            .onAppear {
                DataManager.seedExercisesIfNeeded(context: modelContext)
            }
            .fullScreenCover(isPresented: $showingActiveWorkout) {
                ActiveWorkoutView(vm: workoutVM)
            }
            .sheet(isPresented: $showingRoutinePicker) {
                RoutinePickerSheet(workoutVM: workoutVM, showingActiveWorkout: $showingActiveWorkout)
            }
        }
        .environment(workoutVM)
    }
}

struct ActiveWorkoutBanner: View {
    let vm: ActiveWorkoutViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.session?.title ?? "Active Workout")
                    .font(.headline)
                Text(vm.formattedElapsed)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

struct RoutineQuickStartCard: View {
    let routine: Routine
    let onStart: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.name)
                    .font(.headline)
                Text("\(routine.exerciseCount) exercises")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Start", action: onStart)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

struct RoutinePickerSheet: View {
    let workoutVM: ActiveWorkoutViewModel
    @Binding var showingActiveWorkout: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var routines: [Routine]

    var body: some View {
        NavigationStack {
            List(routines) { routine in
                Button {
                    workoutVM.startFromRoutine(routine, context: modelContext)
                    dismiss()
                    showingActiveWorkout = true
                } label: {
                    VStack(alignment: .leading) {
                        Text(routine.name).foregroundStyle(.primary)
                        Text("\(routine.exerciseCount) exercises")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Pick a Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
