import SwiftUI
import SwiftData

struct WorkoutTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var workoutVM = ActiveWorkoutViewModel()
    @State private var showingActiveWorkout = false
    @State private var showingRoutinePicker = false

    @Query(sort: \Routine.createdAt, order: .reverse) private var routines: [Routine]
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var sessions: [WorkoutSession]

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    private var streak: Int {
        var count = 0
        var day = Calendar.current.startOfDay(for: Date())
        let completed = sessions.filter { $0.endDate != nil }
        while completed.contains(where: { Calendar.current.isDate($0.startDate, inSameDayAs: day) }) {
            count += 1
            day = Calendar.current.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }

    private var lastWorkout: WorkoutSession? {
        sessions.first { $0.endDate != nil }
    }

    private var recommendation: WorkoutRecommendation {
        WorkoutRecommendationEngine.recommend(from: sessions.filter { $0.endDate != nil }, routines: routines)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VoltColor.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: VoltSpacing.xl) {
                        heroSection
                        startSection
                        recommendationSection
                        if !routines.isEmpty { routinesSection }
                        if let last = lastWorkout { lastWorkoutSection(last) }
                    }
                    .padding(.bottom, VoltSpacing.xxl)
                }
                .scrollIndicators(.hidden)

                // Floating active workout bar
                if workoutVM.isActive {
                    VStack {
                        Spacer()
                        ActiveWorkoutBar(vm: workoutVM)
                            .onTapGesture { showingActiveWorkout = true }
                            .padding(.horizontal, VoltSpacing.md)
                            .padding(.bottom, VoltSpacing.sm)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { DataManager.seedExercisesIfNeeded(context: modelContext) }
            .fullScreenCover(isPresented: $showingActiveWorkout) {
                ActiveWorkoutView(vm: workoutVM)
            }
            .sheet(isPresented: $showingRoutinePicker) {
                RoutinePickerSheet(workoutVM: workoutVM, showingActiveWorkout: $showingActiveWorkout)
            }
        }
        .environment(workoutVM)
    }

    // MARK: - Hero
    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: VoltSpacing.radiusLg)
                .fill(VoltGradient.brand)
                .frame(maxWidth: .infinity)
                .frame(height: 160)

            // Subtle texture dots
            GeometryReader { geo in
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(0.04))
                        .frame(width: CGFloat(40 + i * 20))
                        .offset(x: geo.size.width - 40 - CGFloat(i * 30),
                                y: CGFloat(i * 15) - 20)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.75))
                Text("Ready to train?")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                if streak > 0 {
                    HStack(spacing: 5) {
                        Image(systemName: "flame.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.orange)
                        Text("\(streak)-day streak")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            .padding(VoltSpacing.lg)
        }
        .padding(.horizontal, VoltSpacing.md)
        .padding(.top, VoltSpacing.md)
    }

    // MARK: - Start section
    private var startSection: some View {
        VStack(spacing: 10) {
            // Primary CTA
            Button {
                guard !workoutVM.isActive else { showingActiveWorkout = true; return }
                workoutVM.startWorkout(context: modelContext)
                showingActiveWorkout = true
            } label: {
                HStack(spacing: VoltSpacing.sm) {
                    Image(systemName: workoutVM.isActive ? "arrow.up.right.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text(workoutVM.isActive ? "Resume Workout" : "Start Empty Workout")
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(VoltGradient.brand)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: VoltSpacing.radius))
            }

            HStack(spacing: 10) {
                // Recommendation
                Button { showingRoutinePicker = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                        Text(recommendation.buttonLabel)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(VoltColor.accentPurple.opacity(0.12))
                    .foregroundStyle(VoltColor.accentPurple)
                    .clipShape(RoundedRectangle(cornerRadius: VoltSpacing.radius))
                    .overlay(RoundedRectangle(cornerRadius: VoltSpacing.radius)
                        .stroke(VoltColor.accentPurple.opacity(0.3), lineWidth: 0.5))
                }

                // From Routine
                Button { showingRoutinePicker = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "repeat")
                            .font(.system(size: 14, weight: .semibold))
                        Text("From Routine")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(VoltColor.surface)
                    .foregroundStyle(VoltColor.labelSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: VoltSpacing.radius))
                    .overlay(RoundedRectangle(cornerRadius: VoltSpacing.radius)
                        .stroke(VoltColor.border, lineWidth: 0.5))
                }
            }
        }
        .padding(.horizontal, VoltSpacing.md)
    }

    // MARK: - Recommendation
    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: VoltSpacing.sm) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(VoltColor.accentPurple)
                Text("Suggested Next")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(VoltColor.label)
            }
            .padding(.horizontal, VoltSpacing.md)

            HStack(spacing: VoltSpacing.md) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(recommendation.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(VoltColor.label)
                    Text(recommendation.reason)
                        .font(.caption)
                        .foregroundStyle(VoltColor.labelSecondary)
                        .lineLimit(2)
                }
                Spacer()
                HStack(spacing: 6) {
                    ForEach(recommendation.muscleGroups.prefix(3), id: \.self) { group in
                        if let g = Exercise.MuscleGroup(rawValue: group) {
                            MuscleBadge(group: g)
                        }
                    }
                }
            }
            .voltCard()
            .padding(.horizontal, VoltSpacing.md)
        }
    }

    // MARK: - Routines
    private var routinesSection: some View {
        VStack(alignment: .leading, spacing: VoltSpacing.sm) {
            HStack {
                Text("My Routines")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(VoltColor.label)
                Spacer()
            }
            .padding(.horizontal, VoltSpacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(routines) { routine in
                        RoutineQuickCard(routine: routine) {
                            guard !workoutVM.isActive else { showingActiveWorkout = true; return }
                            workoutVM.startFromRoutine(routine, context: modelContext)
                            showingActiveWorkout = true
                        }
                    }
                }
                .padding(.horizontal, VoltSpacing.md)
            }
        }
    }

    // MARK: - Last workout
    private func lastWorkoutSection(_ session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: VoltSpacing.sm) {
            Text("Last Workout")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(VoltColor.label)
                .padding(.horizontal, VoltSpacing.md)

            HStack(spacing: VoltSpacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(VoltColor.label)
                    Text(session.startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(VoltColor.labelSecondary)
                }
                Spacer()
                HStack(spacing: 14) {
                    miniStat(value: session.formattedDuration, icon: "clock")
                    miniStat(value: "\(session.totalSets) sets", icon: "dumbbell")
                }
            }
            .voltCard()
            .padding(.horizontal, VoltSpacing.md)
        }
    }

    private func miniStat(value: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2).foregroundStyle(VoltColor.labelTertiary)
            Text(value).font(.caption.weight(.medium)).foregroundStyle(VoltColor.labelSecondary)
        }
    }
}

// MARK: - Floating active bar
struct ActiveWorkoutBar: View {
    let vm: ActiveWorkoutViewModel

    var body: some View {
        HStack(spacing: VoltSpacing.md) {
            HStack(spacing: 8) {
                Circle()
                    .fill(VoltColor.success)
                    .frame(width: 8, height: 8)
                    .shadow(color: VoltColor.success, radius: 4)
                VStack(alignment: .leading, spacing: 1) {
                    Text(vm.session?.title ?? "Active Workout")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(VoltColor.label)
                    Text(vm.formattedElapsed)
                        .font(VoltFont.mono(13))
                        .foregroundStyle(VoltColor.labelSecondary)
                }
            }
            Spacer()
            Text("Tap to open")
                .font(.caption.weight(.medium))
                .foregroundStyle(VoltColor.accent)
        }
        .padding(.horizontal, VoltSpacing.md)
        .padding(.vertical, 12)
        .background(VoltColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: VoltSpacing.radiusLg))
        .overlay(RoundedRectangle(cornerRadius: VoltSpacing.radiusLg)
            .stroke(VoltColor.success.opacity(0.4), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 16, y: 4)
    }
}

// MARK: - Routine quick card
struct RoutineQuickCard: View {
    let routine: Routine
    let onStart: () -> Void

    private var topMuscles: [Exercise.MuscleGroup] {
        Array(Set(routine.exercises.map(\.exerciseMuscleGroup)))
            .compactMap { Exercise.MuscleGroup(rawValue: $0) }
            .prefix(2)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: VoltSpacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(routine.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(VoltColor.label)
                        .lineLimit(1)
                    Text("\(routine.exerciseCount) exercises")
                        .font(.caption)
                        .foregroundStyle(VoltColor.labelSecondary)
                }
                Spacer()
            }
            if !topMuscles.isEmpty {
                HStack(spacing: 5) {
                    ForEach(topMuscles, id: \.self) { MuscleBadge(group: $0) }
                }
            }
            Button(action: onStart) {
                Text("Start")
                    .font(.caption.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(VoltGradient.brand)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: VoltSpacing.radiusSm))
            }
        }
        .padding(VoltSpacing.md)
        .frame(width: 170)
        .background(VoltColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: VoltSpacing.radius))
        .overlay(RoundedRectangle(cornerRadius: VoltSpacing.radius)
            .stroke(VoltColor.border, lineWidth: 0.5))
    }
}

// MARK: - Routine picker sheet
struct RoutinePickerSheet: View {
    let workoutVM: ActiveWorkoutViewModel
    @Binding var showingActiveWorkout: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var routines: [Routine]

    var body: some View {
        NavigationStack {
            ZStack {
                VoltColor.bg.ignoresSafeArea()
                if routines.isEmpty {
                    EmptyStateView(icon: "repeat", title: "No Routines", message: "Create routines in the Routines tab to quick-start structured workouts.")
                } else {
                    List(routines) { routine in
                        Button {
                            workoutVM.startFromRoutine(routine, context: modelContext)
                            dismiss()
                            showingActiveWorkout = true
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(routine.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(VoltColor.label)
                                Text("\(routine.exerciseCount) exercises")
                                    .font(.caption)
                                    .foregroundStyle(VoltColor.labelSecondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(VoltColor.surface)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Choose a Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(VoltColor.labelSecondary)
                }
            }
        }
    }
}

#Preview("Workout Tab") {
    WorkoutTabView()
        .modelContainer(for: [WorkoutSession.self, Exercise.self, Routine.self], inMemory: true)
        .environment(SupabaseManager.shared)
        .preferredColorScheme(.dark)
}
