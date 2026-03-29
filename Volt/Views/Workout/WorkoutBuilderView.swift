import SwiftUI
import SwiftData

// MARK: - Generated Exercise Model
struct GeneratedExercise {
    let name: String
    let muscleGroup: Exercise.MuscleGroup
    let sets: Int
    let reps: Int
    let icon: String
}

// MARK: - Workout Generator Engine
enum WorkoutGenerator {

    /// Ordered by priority — compounds first, isolation after.
    private static let compoundOrder: [String] = [
        // Legs
        "Squat", "Front Squat", "Box Squat", "Safety Bar Squat", "Pause Squat",
        "Trap Bar Deadlift", "Stiff Leg Deadlift", "Romanian Deadlift",
        "Hack Squat", "Pendulum Squat", "Leg Press", "Bulgarian Split Squat",
        "Nordic Curl", "Glute-Ham Raise", "Walking Lunge", "Lunge",
        // Glutes
        "Hip Thrust", "Smith Machine Hip Thrust", "Glute Bridge", "Sumo Deadlift",
        "Cable Pull-Through",
        // Back
        "Deadlift", "Barbell Row", "Pendlay Row", "T-Bar Row", "Meadows Row",
        "Pull Up", "Chin Up", "Neutral Grip Pull Up",
        "Lat Pulldown", "Wide Grip Lat Pulldown", "Reverse Grip Lat Pulldown",
        "Seated Cable Row", "Machine Row", "Chest Supported Row", "Incline Dumbbell Row",
        // Chest
        "Bench Press", "Incline Bench Press", "Decline Bench Press",
        "Dumbbell Bench Press", "Incline Dumbbell Press",
        // Shoulders
        "Overhead Press", "Push Press", "Dumbbell Shoulder Press", "Arnold Press",
        // Triceps
        "Skull Crusher", "EZ Bar Skull Crusher", "Tricep Dip", "Close Grip Bench Press",
        // Biceps
        "Barbell Curl", "EZ Bar Curl",
        // Full body
        "Power Clean", "Clean and Jerk", "Thruster", "Snatch"
    ]

    static func generate(
        muscleGroups: [Exercise.MuscleGroup],
        duration: Int,
        from library: [Exercise]
    ) -> [GeneratedExercise] {
        let target = exerciseCount(for: duration)
        let pool = library.filter { muscleGroups.contains($0.muscleGroup) }

        // Sort pool: known compounds first, then alphabetically
        let sorted = pool.sorted { a, b in
            let ai = compoundOrder.firstIndex(of: a.name) ?? Int.max
            let bi = compoundOrder.firstIndex(of: b.name) ?? Int.max
            return ai != bi ? ai < bi : a.name < b.name
        }

        var selected: [Exercise] = []
        var groupCounts: [Exercise.MuscleGroup: Int] = [:]
        let maxPerGroup = max(2, Int(ceil(Double(target) / Double(muscleGroups.count))))

        // Pass 1: best compound per group
        for group in muscleGroups {
            guard selected.count < target else { break }
            if let pick = sorted.first(where: { candidate in
                candidate.muscleGroup == group && !selected.contains(where: { $0.id == candidate.id })
            }) {
                selected.append(pick)
                groupCounts[group, default: 0] += 1
            }
        }

        // Pass 2: fill remaining evenly across groups
        for ex in sorted {
            guard selected.count < target else { break }
            guard !selected.contains(where: { $0.id == ex.id }) else { continue }
            let count = groupCounts[ex.muscleGroup, default: 0]
            if count < maxPerGroup {
                selected.append(ex)
                groupCounts[ex.muscleGroup, default: 0] += 1
            }
        }

        // Pass 3: fill any remaining slots
        for ex in sorted {
            guard selected.count < target else { break }
            if !selected.contains(where: { $0.id == ex.id }) {
                selected.append(ex)
            }
        }

        return selected.prefix(target).map { ex in
            let isCompound = compoundOrder.prefix(30).contains(ex.name)
            let (sets, reps) = setsReps(for: duration, isCompound: isCompound)
            return GeneratedExercise(
                name: ex.name,
                muscleGroup: ex.muscleGroup,
                sets: sets,
                reps: reps,
                icon: ex.icon
            )
        }
    }

    private static func exerciseCount(for duration: Int) -> Int {
        switch duration {
        case ..<35: return 3
        case ..<50: return 4
        case ..<65: return 5
        case ..<80: return 6
        default:    return 7
        }
    }

    private static func setsReps(for duration: Int, isCompound: Bool) -> (Int, Int) {
        let sets = duration >= 60 ? 4 : 3
        let reps = isCompound ? (duration >= 60 ? 6 : 8) : 12
        return (sets, reps)
    }

    static func title(for groups: [Exercise.MuscleGroup]) -> String {
        let g = Set(groups)
        if g.contains(.legs) && g.contains(.glutes) && !g.contains(.back) && !g.contains(.chest) { return "Leg Day" }
        if g.contains(.legs) && !g.contains(.back) && !g.contains(.chest) { return "Leg Day" }
        if g.contains(.glutes) && !g.contains(.legs) && !g.contains(.back)  { return "Glute Day" }
        if g.contains(.back) && g.contains(.biceps) && !g.contains(.chest)   { return "Pull Day" }
        if g.contains(.chest) && g.contains(.shoulders) && g.contains(.triceps) { return "Push Day" }
        if g.contains(.chest) && !g.contains(.back)      { return "Chest Day" }
        if g.contains(.back) && !g.contains(.chest)       { return "Back Day" }
        if g.contains(.shoulders) && !g.contains(.chest) && !g.contains(.back) { return "Shoulder Day" }
        if g == [.core]                                   { return "Core Day" }
        if (g.contains(.chest) || g.contains(.shoulders)) && (g.contains(.back) || g.contains(.biceps)) { return "Upper Body" }
        if groups.count >= 4 { return "Full Body" }
        return groups.first.map { "\($0.rawValue) Day" } ?? "Custom Workout"
    }
}

// MARK: - Main View
struct WorkoutBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    var workoutVM: ActiveWorkoutViewModel
    @Binding var showingActiveWorkout: Bool

    @State private var selectedGroups: Set<Exercise.MuscleGroup> = []
    @State private var duration: Int = 45
    @State private var generatedPlan: [GeneratedExercise] = []
    @State private var workoutTitle = ""
    @State private var showingPreview = false

    private let durations = [30, 45, 60, 75, 90]

    var body: some View {
        NavigationStack {
            ZStack {
                VoltColor.bg.ignoresSafeArea()
                if showingPreview {
                    previewView
                } else {
                    configureView
                }
            }
            .navigationTitle(showingPreview ? "Your Workout" : "Build a Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if showingPreview {
                        Button("Edit") { showingPreview = false }
                            .foregroundStyle(VoltColor.accent)
                    } else {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(VoltColor.labelSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Configure
    private var configureView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VoltSpacing.lg) {

                // Muscle group picker
                VStack(alignment: .leading, spacing: VoltSpacing.sm) {
                    Text("What do you want to train?")
                        .font(.headline)
                        .foregroundStyle(VoltColor.label)
                        .padding(.horizontal, VoltSpacing.md)
                    Text("Select one or more muscle groups")
                        .font(.caption)
                        .foregroundStyle(VoltColor.labelSecondary)
                        .padding(.horizontal, VoltSpacing.md)

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 10
                    ) {
                        ForEach(Exercise.MuscleGroup.allCases.filter { $0 != .cardio }, id: \.self) { group in
                            BuilderMuscleToggle(
                                group: group,
                                isSelected: selectedGroups.contains(group)
                            ) {
                                if selectedGroups.contains(group) {
                                    selectedGroups.remove(group)
                                } else {
                                    selectedGroups.insert(group)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, VoltSpacing.md)
                }

                // Duration picker
                VStack(alignment: .leading, spacing: VoltSpacing.sm) {
                    Text("How long?")
                        .font(.headline)
                        .foregroundStyle(VoltColor.label)
                    HStack(spacing: 8) {
                        ForEach(durations, id: \.self) { d in
                            Button { duration = d } label: {
                                Text("\(d)m")
                                    .font(.system(size: 14, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(duration == d ? VoltColor.accent : VoltColor.surface)
                                    .foregroundStyle(duration == d ? .white : VoltColor.labelSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: VoltSpacing.radiusSm))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: VoltSpacing.radiusSm)
                                            .stroke(duration == d ? VoltColor.accent : VoltColor.border, lineWidth: 0.5)
                                    )
                            }
                            .animation(.easeInOut(duration: 0.15), value: duration)
                        }
                    }
                }
                .padding(.horizontal, VoltSpacing.md)

                // Preview info
                if !selectedGroups.isEmpty {
                    let preview = WorkoutGenerator.generate(
                        muscleGroups: Array(selectedGroups), duration: duration, from: exercises)
                    HStack(spacing: VoltSpacing.md) {
                        infoChip(icon: "dumbbell.fill", text: "\(preview.count) exercises")
                        infoChip(icon: "repeat", text: "\(preview.reduce(0) { $0 + $1.sets }) total sets")
                    }
                    .padding(.horizontal, VoltSpacing.md)
                }

                // Build button
                Button { buildWorkout() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.stars")
                        Text("Build My Workout")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(selectedGroups.isEmpty ? VoltColor.surfaceHigh : VoltGradient.brand)
                    .foregroundStyle(selectedGroups.isEmpty ? VoltColor.labelTertiary : .white)
                    .clipShape(RoundedRectangle(cornerRadius: VoltSpacing.radius))
                }
                .disabled(selectedGroups.isEmpty)
                .padding(.horizontal, VoltSpacing.md)
            }
            .padding(.top, VoltSpacing.lg)
            .padding(.bottom, VoltSpacing.xxl)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Preview
    private var previewView: some View {
        VStack(spacing: 0) {
            // Stats strip
            HStack(spacing: VoltSpacing.xl) {
                statPill(value: "\(duration) min", label: "estimated")
                statPill(value: "\(generatedPlan.count)", label: "exercises")
                statPill(value: "\(generatedPlan.reduce(0) { $0 + $1.sets })", label: "total sets")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(VoltColor.surface)

            Divider().background(VoltColor.border)

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text(workoutTitle)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(VoltColor.label)
                        Text(selectedGroups.map(\.rawValue).sorted().joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(VoltColor.labelSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, VoltSpacing.md)
                    .padding(.vertical, VoltSpacing.md)

                    // Exercise list
                    VStack(spacing: 10) {
                        ForEach(Array(generatedPlan.enumerated()), id: \.offset) { idx, ex in
                            GeneratedExerciseRow(index: idx + 1, exercise: ex)
                        }
                    }
                    .padding(.horizontal, VoltSpacing.md)

                    // Action buttons
                    VStack(spacing: 10) {
                        Button { startGeneratedWorkout() } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "play.circle.fill")
                                Text("Start Workout")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(VoltGradient.brand)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: VoltSpacing.radius))
                        }

                        Button { saveAsRoutine(); dismiss() } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "bookmark.fill")
                                Text("Save as Routine")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(VoltColor.surface)
                            .foregroundStyle(VoltColor.accentPurple)
                            .clipShape(RoundedRectangle(cornerRadius: VoltSpacing.radius))
                            .overlay(RoundedRectangle(cornerRadius: VoltSpacing.radius)
                                .stroke(VoltColor.accentPurple.opacity(0.3), lineWidth: 0.5))
                        }
                    }
                    .padding(.horizontal, VoltSpacing.md)
                    .padding(.top, VoltSpacing.md)
                    .padding(.bottom, VoltSpacing.xxl)
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Helpers

    private func buildWorkout() {
        generatedPlan = WorkoutGenerator.generate(
            muscleGroups: Array(selectedGroups),
            duration: duration,
            from: exercises
        )
        workoutTitle = WorkoutGenerator.title(for: Array(selectedGroups))
        showingPreview = true
    }

    private func startGeneratedWorkout() {
        guard !workoutVM.isActive else { dismiss(); showingActiveWorkout = true; return }
        workoutVM.startWorkout(title: workoutTitle, context: modelContext)
        guard let session = workoutVM.session else { return }
        for (i, genEx) in generatedPlan.enumerated() {
            let log = ExerciseLog(
                exerciseName: genEx.name,
                exerciseMuscleGroup: genEx.muscleGroup.rawValue,
                orderIndex: i
            )
            modelContext.insert(log)
            for s in 0..<genEx.sets {
                let set = WorkoutSet(orderIndex: s, reps: genEx.reps)
                modelContext.insert(set)
                log.sets.append(set)
            }
            session.exerciseLogs.append(log)
        }
        try? modelContext.save()
        dismiss()
        showingActiveWorkout = true
    }

    private func saveAsRoutine() {
        let routine = Routine(name: workoutTitle)
        modelContext.insert(routine)
        for (i, genEx) in generatedPlan.enumerated() {
            let re = RoutineExercise(
                exerciseName: genEx.name,
                exerciseMuscleGroup: genEx.muscleGroup.rawValue,
                orderIndex: i,
                targetSets: genEx.sets,
                targetReps: genEx.reps
            )
            modelContext.insert(re)
            routine.exercises.append(re)
        }
        try? modelContext.save()
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 1) {
            Text(value).font(VoltFont.mono(14, weight: .bold)).foregroundStyle(VoltColor.label)
            Text(label).font(.system(size: 10)).foregroundStyle(VoltColor.labelTertiary)
        }
    }

    private func infoChip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption2).foregroundStyle(VoltColor.accent)
            Text(text).font(.caption.weight(.medium)).foregroundStyle(VoltColor.labelSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(VoltColor.surface)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(VoltColor.border, lineWidth: 0.5))
    }
}

// MARK: - Muscle group toggle tile
struct BuilderMuscleToggle: View {
    let group: Exercise.MuscleGroup
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected
                              ? VoltColor.muscle(group).opacity(0.2)
                              : VoltColor.surfaceHigh)
                        .frame(width: 44, height: 44)
                    Image(systemName: group.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected
                                         ? VoltColor.muscle(group)
                                         : VoltColor.labelTertiary)
                }
                Text(group.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isSelected ? VoltColor.label : VoltColor.labelSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected
                        ? VoltColor.muscle(group).opacity(0.08)
                        : VoltColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: VoltSpacing.radiusSm))
            .overlay(
                RoundedRectangle(cornerRadius: VoltSpacing.radiusSm)
                    .stroke(
                        isSelected ? VoltColor.muscle(group).opacity(0.4) : VoltColor.border,
                        lineWidth: isSelected ? 1 : 0.5
                    )
            )
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Generated exercise row
struct GeneratedExerciseRow: View {
    let index: Int
    let exercise: GeneratedExercise

    var body: some View {
        HStack(spacing: 12) {
            Text(String(format: "%02d", index))
                .font(VoltFont.mono(12))
                .foregroundStyle(VoltColor.labelTertiary)
                .frame(width: 22)

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
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(VoltColor.label)
                MuscleBadge(group: exercise.muscleGroup)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(exercise.sets) × \(exercise.reps)")
                    .font(VoltFont.mono(14, weight: .bold))
                    .foregroundStyle(VoltColor.label)
                Text("sets × reps")
                    .font(.system(size: 10))
                    .foregroundStyle(VoltColor.labelTertiary)
            }
        }
        .padding(VoltSpacing.md)
        .background(VoltColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: VoltSpacing.radius))
        .overlay(RoundedRectangle(cornerRadius: VoltSpacing.radius)
            .stroke(VoltColor.border, lineWidth: 0.5))
    }
}

#Preview("Workout Builder") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: WorkoutSession.self, Exercise.self, Routine.self,
        configurations: config
    )
    DataManager.seedExercisesIfNeeded(context: container.mainContext)
    let vm = ActiveWorkoutViewModel()
    return WorkoutBuilderView(workoutVM: vm, showingActiveWorkout: .constant(false))
        .modelContainer(container)
        .preferredColorScheme(.dark)
}
