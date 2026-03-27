import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Environment(\.modelContext) private var modelContext
    @State private var search = ""
    @State private var selectedMuscle: Exercise.MuscleGroup? = nil
    @State private var showingCreateExercise = false

    var filtered: [Exercise] {
        exercises.filter { ex in
            let matchesMuscle = selectedMuscle == nil || ex.muscleGroup == selectedMuscle
            let matchesSearch = search.isEmpty || ex.name.localizedCaseInsensitiveContains(search)
            return matchesMuscle && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Muscle filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: selectedMuscle == nil) {
                            selectedMuscle = nil
                        }
                        ForEach(Exercise.MuscleGroup.allCases, id: \.self) { group in
                            FilterChip(label: group.rawValue, isSelected: selectedMuscle == group) {
                                selectedMuscle = selectedMuscle == group ? nil : group
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                Divider()

                List {
                    ForEach(filtered) { exercise in
                        NavigationLink {
                            ExerciseDetailView(exercise: exercise)
                        } label: {
                            ExerciseRow(exercise: exercise)
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "Search exercises")
            .navigationTitle("Exercises")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateExercise = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateExercise) {
                CreateExerciseView()
            }
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: exercise.muscleGroup.icon)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(Color.blue.opacity(0.1))
                .foregroundStyle(.blue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 6) {
                    Text(exercise.muscleGroup.rawValue)
                    Text("·")
                    Text(exercise.equipment.rawValue)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct ExerciseDetailView: View {
    let exercise: Exercise

    var body: some View {
        List {
            Section {
                LabeledContent("Muscle Group", value: exercise.muscleGroup.rawValue)
                LabeledContent("Equipment", value: exercise.equipment.rawValue)
            }

            if !exercise.instructions.isEmpty {
                Section("Instructions") {
                    Text(exercise.instructions)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CreateExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var muscleGroup: Exercise.MuscleGroup = .chest
    @State private var equipment: Exercise.Equipment = .barbell
    @State private var instructions = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Exercise name", text: $name)
                    Picker("Muscle Group", selection: $muscleGroup) {
                        ForEach(Exercise.MuscleGroup.allCases, id: \.self) { group in
                            Text(group.rawValue).tag(group)
                        }
                    }
                    Picker("Equipment", selection: $equipment) {
                        ForEach(Exercise.Equipment.allCases, id: \.self) { eq in
                            Text(eq.rawValue).tag(eq)
                        }
                    }
                }

                Section("Instructions (optional)") {
                    TextEditor(text: $instructions)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let exercise = Exercise(
                            name: name,
                            muscleGroup: muscleGroup,
                            equipment: equipment,
                            instructions: instructions,
                            isCustom: true
                        )
                        modelContext.insert(exercise)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview("Exercise Library") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Exercise.self, configurations: config)
    DataManager.seedExercisesIfNeeded(context: container.mainContext)
    return ExerciseLibraryView().modelContainer(container)
}
