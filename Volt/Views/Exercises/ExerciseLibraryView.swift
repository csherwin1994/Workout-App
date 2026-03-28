import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var search = ""
    @State private var selectedMuscle: Exercise.MuscleGroup?
    @State private var showingCreate = false

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
                    // Muscle filter
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

                    if filtered.isEmpty {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "No Exercises Found",
                            message: "Try a different search or muscle group filter.",
                            actionTitle: "Create Exercise",
                            action: { showingCreate = true }
                        )
                    } else {
                        List(filtered) { exercise in
                            NavigationLink { ExerciseDetailView(exercise: exercise) } label: {
                                ExerciseRow(exercise: exercise)
                            }
                            .listRowBackground(VoltColor.surface)
                            .listRowSeparatorTint(VoltColor.border)
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .searchable(text: $search, prompt: "Search exercises")
            .navigationTitle("Exercises")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingCreate = true } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(VoltColor.accent)
                    }
                }
            }
            .sheet(isPresented: $showingCreate) { CreateExerciseView() }
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(VoltColor.muscle(exercise.muscleGroup).opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: exercise.muscleGroup.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(VoltColor.muscle(exercise.muscleGroup))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(VoltColor.label)
                HStack(spacing: 6) {
                    MuscleBadge(group: exercise.muscleGroup)
                    Text(exercise.equipment.rawValue)
                        .font(.caption)
                        .foregroundStyle(VoltColor.labelTertiary)
                }
            }
            if exercise.isCustom {
                Spacer()
                Text("Custom")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(VoltColor.accentPurple)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(VoltColor.accentPurple.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

struct ExerciseDetailView: View {
    let exercise: Exercise

    var body: some View {
        ZStack {
            VoltColor.bg.ignoresSafeArea()
            List {
                Section {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: VoltSpacing.radiusSm)
                                .fill(VoltColor.muscle(exercise.muscleGroup).opacity(0.12))
                                .frame(width: 56, height: 56)
                            Image(systemName: exercise.muscleGroup.icon)
                                .font(.system(size: 26))
                                .foregroundStyle(VoltColor.muscle(exercise.muscleGroup))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name).font(.headline).foregroundStyle(VoltColor.label)
                            MuscleBadge(group: exercise.muscleGroup)
                        }
                        .padding(.leading, 4)
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(VoltColor.surface)

                Section("Details") {
                    detailRow("Muscle Group", value: exercise.muscleGroup.rawValue)
                    detailRow("Equipment", value: exercise.equipment.rawValue)
                    if exercise.isCustom { detailRow("Type", value: "Custom Exercise") }
                }
                .listRowBackground(VoltColor.surface)
                .listRowSeparatorTint(VoltColor.border)

                if !exercise.instructions.isEmpty {
                    Section("Instructions") {
                        Text(exercise.instructions)
                            .font(.subheadline)
                            .foregroundStyle(VoltColor.labelSecondary)
                            .lineSpacing(4)
                    }
                    .listRowBackground(VoltColor.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(VoltColor.labelSecondary).font(.subheadline)
            Spacer()
            Text(value).foregroundStyle(VoltColor.label).font(.subheadline.weight(.medium))
        }
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
            ZStack {
                VoltColor.bg.ignoresSafeArea()
                List {
                    Section("Exercise Details") {
                        TextField("Name (e.g. Cable Fly)", text: $name)
                            .foregroundStyle(VoltColor.label)
                            .listRowBackground(VoltColor.surface)
                        Picker("Muscle Group", selection: $muscleGroup) {
                            ForEach(Exercise.MuscleGroup.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        .foregroundStyle(VoltColor.label)
                        .listRowBackground(VoltColor.surface)
                        Picker("Equipment", selection: $equipment) {
                            ForEach(Exercise.Equipment.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        .foregroundStyle(VoltColor.label)
                        .listRowBackground(VoltColor.surface)
                    }
                    .listRowSeparatorTint(VoltColor.border)

                    Section("Instructions (Optional)") {
                        TextEditor(text: $instructions)
                            .frame(minHeight: 80)
                            .foregroundStyle(VoltColor.label)
                            .listRowBackground(VoltColor.surface)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(VoltColor.labelSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let ex = Exercise(name: name.trimmingCharacters(in: .whitespaces),
                                         muscleGroup: muscleGroup, equipment: equipment,
                                         instructions: instructions, isCustom: true)
                        modelContext.insert(ex); try? modelContext.save(); dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundStyle(VoltColor.accent)
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
