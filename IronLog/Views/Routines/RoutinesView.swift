import SwiftUI
import SwiftData

struct RoutinesView: View {
    @Query(sort: \Routine.createdAt, order: .reverse) private var routines: [Routine]
    @Environment(\.modelContext) private var modelContext
    @State private var showingCreateRoutine = false

    var body: some View {
        NavigationStack {
            Group {
                if routines.isEmpty {
                    ContentUnavailableView(
                        "No Routines",
                        systemImage: "repeat",
                        description: Text("Create routines to quickly start structured workouts.")
                    )
                } else {
                    List {
                        ForEach(routines) { routine in
                            NavigationLink {
                                RoutineDetailView(routine: routine)
                            } label: {
                                RoutineRow(routine: routine)
                            }
                        }
                        .onDelete(perform: deleteRoutines)
                    }
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateRoutine = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateRoutine) {
                CreateRoutineView()
            }
        }
    }

    private func deleteRoutines(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(routines[index])
        }
        try? modelContext.save()
    }
}

struct RoutineRow: View {
    let routine: Routine

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(routine.name)
                .font(.headline)
            HStack(spacing: 12) {
                Label("\(routine.exerciseCount) exercises", systemImage: "dumbbell")
                if let lastUsed = routine.lastUsedAt {
                    Label(lastUsed.formatted(.relative(presentation: .named)), systemImage: "clock")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct RoutineDetailView: View {
    @Bindable var routine: Routine
    @Environment(\.modelContext) private var modelContext
    @State private var showingExercisePicker = false
    @State private var isEditing = false

    var sortedExercises: [RoutineExercise] {
        routine.exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        List {
            Section {
                if isEditing {
                    TextField("Routine name", text: $routine.name)
                } else {
                    if !routine.notes.isEmpty {
                        Text(routine.notes).foregroundStyle(.secondary)
                    }
                }
            }

            Section("Exercises") {
                ForEach(sortedExercises) { exercise in
                    RoutineExerciseRow(exercise: exercise)
                }
                .onDelete { offsets in
                    for index in offsets {
                        let ex = sortedExercises[index]
                        routine.exercises.removeAll { $0.id == ex.id }
                        modelContext.delete(ex)
                    }
                    try? modelContext.save()
                }
                .onMove { from, to in
                    var sorted = sortedExercises
                    sorted.move(fromOffsets: from, toOffset: to)
                    for (index, ex) in sorted.enumerated() {
                        ex.orderIndex = index
                    }
                    try? modelContext.save()
                }

                Button {
                    showingExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
            }
        }
        .navigationTitle(routine.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                EditButton()
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerSheet { exercise in
                let routineExercise = RoutineExercise(
                    exerciseName: exercise.name,
                    exerciseMuscleGroup: exercise.muscleGroup.rawValue,
                    orderIndex: routine.exercises.count
                )
                modelContext.insert(routineExercise)
                routine.exercises.append(routineExercise)
                try? modelContext.save()
            }
        }
    }
}

struct RoutineExerciseRow: View {
    @Bindable var exercise: RoutineExercise

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.exerciseName).font(.subheadline.weight(.medium))
                Text("\(exercise.targetSets) sets × \(exercise.targetReps) reps")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if exercise.targetWeight > 0 {
                Text(String(format: "%.1f kg", exercise.targetWeight))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct CreateRoutineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Routine Details") {
                    TextField("Routine name (e.g. Push Day)", text: $name)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let routine = Routine(name: name, notes: notes)
                        modelContext.insert(routine)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview("Routines – with data") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Routine.self, Exercise.self, WorkoutSession.self, configurations: config)
    let context = container.mainContext

    for (rName, exercises) in [
        ("Push Day", [("Bench Press", "Chest", 4, 8), ("Overhead Press", "Shoulders", 3, 10), ("Tricep Pushdown", "Triceps", 3, 12)]),
        ("Pull Day", [("Deadlift", "Back", 3, 5), ("Pull Up", "Back", 3, 8), ("Barbell Curl", "Biceps", 3, 12)]),
        ("Leg Day", [("Squat", "Legs", 4, 6), ("Leg Press", "Legs", 3, 10), ("Romanian Deadlift", "Legs", 3, 10)])
    ] {
        let routine = Routine(name: rName)
        context.insert(routine)
        for (i, (exName, muscle, sets, reps)) in exercises.enumerated() {
            let re = RoutineExercise(exerciseName: exName, exerciseMuscleGroup: muscle,
                                     orderIndex: i, targetSets: sets, targetReps: reps)
            context.insert(re)
            routine.exercises.append(re)
        }
    }
    try? context.save()
    return RoutinesView().modelContainer(container)
}

#Preview("Routines – empty") {
    RoutinesView()
        .modelContainer(for: [Routine.self, Exercise.self, WorkoutSession.self], inMemory: true)
}
