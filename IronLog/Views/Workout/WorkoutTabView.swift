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
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    private var streakCount: Int {
        var streak = 0
        var checkDate = Calendar.current.startOfDay(for: Date())
        let completed = sessions.filter { $0.endDate != nil }
        while true {
            let hasWorkout = completed.contains {
                Calendar.current.isDate($0.startDate, inSameDayAs: checkDate)
            }
            if hasWorkout {
                streak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!
            } else { break }
        }
        return streak
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.sectionSpacing) {

                    // Hero header
                    heroHeader

                    // Active workout banner
                    if workoutVM.isActive {
                        ActiveWorkoutBanner(vm: workoutVM)
                            .onTapGesture { showingActiveWorkout = true }
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Start buttons
                    VStack(spacing: 10) {
                        Button {
                            workoutVM.startWorkout(context: modelContext)
                            showingActiveWorkout = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill").font(.title3)
                                Text("Start Empty Workout").fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.heroGradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                        }
                        .disabled(workoutVM.isActive)
                        .opacity(workoutVM.isActive ? 0.5 : 1)

                        Button {
                            showingRoutinePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "repeat").font(.title3)
                                Text("Start from Routine").fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.cardBackground)
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
                        }
                    }
                    .padding(.horizontal)

                    // Routines quick-start
                    if !routines.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("My Routines")
                                .font(.title3.bold())
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(routines) { routine in
                                        RoutineQuickStartCard(routine: routine) {
                                            workoutVM.startFromRoutine(routine, context: modelContext)
                                            showingActiveWorkout = true
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.top)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
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

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            AppTheme.heroGradient
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .frame(maxWidth: .infinity)
                .frame(height: 140)

            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                Text("Let's train 💪")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                if streakCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill").foregroundStyle(.orange)
                        Text("\(streakCount)-day streak")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
            .padding(20)
        }
        .padding(.horizontal)
    }
}

struct ActiveWorkoutBanner: View {
    let vm: ActiveWorkoutViewModel

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.green)
                .frame(width: 10, height: 10)
                .shadow(color: .green, radius: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(vm.session?.title ?? "Active Workout")
                    .font(.subheadline.bold())
                Text("In progress · \(vm.formattedElapsed)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right.circle.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
        }
        .padding()
        .background(Color.green.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

struct RoutineQuickStartCard: View {
    let routine: Routine
    let onStart: () -> Void

    private var topMuscles: [String] {
        Array(Set(routine.exercises.map(\.exerciseMuscleGroup))).prefix(2).map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name)
                        .font(.headline)
                        .lineLimit(1)
                    Text("\(routine.exerciseCount) exercises")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onStart) {
                    Text("Start")
                        .font(.caption.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(AppTheme.heroGradient)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }

            if !topMuscles.isEmpty {
                HStack(spacing: 6) {
                    ForEach(topMuscles, id: \.self) { muscle in
                        if let group = Exercise.MuscleGroup(rawValue: muscle) {
                            MuscleBadge(group: group)
                        }
                    }
                }
            }
        }
        .padding(AppTheme.cardPadding)
        .frame(width: 200)
        .ironCard()
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
                    VStack(alignment: .leading, spacing: 4) {
                        Text(routine.name).foregroundStyle(.primary).font(.headline)
                        Text("\(routine.exerciseCount) exercises")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
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

#Preview("Workout Tab – with routines") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutSession.self, Exercise.self, Routine.self, configurations: config)
    let context = container.mainContext

    for (name, exercises) in [
        ("Push Day", [("Bench Press","Chest"), ("Overhead Press","Shoulders"), ("Tricep Pushdown","Triceps")]),
        ("Pull Day", [("Deadlift","Back"), ("Pull Up","Back"), ("Barbell Curl","Biceps")]),
        ("Leg Day", [("Squat","Legs"), ("Leg Press","Legs")])
    ] {
        let r = Routine(name: name)
        context.insert(r)
        for (i, (ex, muscle)) in exercises.enumerated() {
            let re = RoutineExercise(exerciseName: ex, exerciseMuscleGroup: muscle, orderIndex: i, targetSets: 3, targetReps: 10)
            context.insert(re); r.exercises.append(re)
        }
    }
    try? context.save()
    return WorkoutTabView().modelContainer(container)
}
