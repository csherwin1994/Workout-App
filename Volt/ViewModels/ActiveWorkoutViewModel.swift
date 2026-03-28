import SwiftUI
import SwiftData

@Observable
final class ActiveWorkoutViewModel {
    var session: WorkoutSession?
    var isActive: Bool = false
    var elapsedSeconds: Int = 0
    var restTimerSeconds: Int = 0
    var isRestTimerRunning: Bool = false

    private var workoutTimer: Timer?
    private var restTimer: Timer?
    private var modelContext: ModelContext?

    func startWorkout(title: String = "My Workout", context: ModelContext) {
        let newSession = WorkoutSession(title: title)
        context.insert(newSession)
        self.session = newSession
        self.modelContext = context
        self.isActive = true
        self.elapsedSeconds = 0
        startWorkoutTimer()
    }

    func startFromRoutine(_ routine: Routine, context: ModelContext) {
        routine.lastUsedAt = Date()
        startWorkout(title: routine.name, context: context)
        guard let session else { return }

        let sorted = routine.exercises.sorted { $0.orderIndex < $1.orderIndex }
        for (index, routineExercise) in sorted.enumerated() {
            let log = ExerciseLog(
                exerciseName: routineExercise.exerciseName,
                exerciseMuscleGroup: routineExercise.exerciseMuscleGroup,
                orderIndex: index
            )
            context.insert(log)
            for i in 0..<routineExercise.targetSets {
                let set = WorkoutSet(
                    orderIndex: i,
                    weight: routineExercise.targetWeight,
                    reps: routineExercise.targetReps
                )
                context.insert(set)
                log.sets.append(set)
            }
            session.exerciseLogs.append(log)
        }
        try? context.save()
    }

    func addExercise(_ exercise: Exercise, context: ModelContext) {
        guard let session else { return }
        let log = ExerciseLog(
            exerciseName: exercise.name,
            exerciseMuscleGroup: exercise.muscleGroup.rawValue,
            orderIndex: session.exerciseLogs.count
        )
        context.insert(log)
        let firstSet = WorkoutSet(orderIndex: 0)
        context.insert(firstSet)
        log.sets.append(firstSet)
        session.exerciseLogs.append(log)
        try? context.save()
    }

    func addSet(to log: ExerciseLog, context: ModelContext) {
        let lastSet = log.sets.sorted { $0.orderIndex < $1.orderIndex }.last
        let newSet = WorkoutSet(
            orderIndex: log.sets.count,
            weight: lastSet?.weight ?? 0,
            reps: lastSet?.reps ?? 0
        )
        context.insert(newSet)
        log.sets.append(newSet)
        try? context.save()
    }

    func removeSet(_ set: WorkoutSet, from log: ExerciseLog, context: ModelContext) {
        log.sets.removeAll { $0.id == set.id }
        context.delete(set)
        try? context.save()
    }

    func toggleSetComplete(_ set: WorkoutSet, context: ModelContext) {
        set.isCompleted.toggle()
        if set.isCompleted {
            set.completedAt = Date()
            startRestTimer(seconds: 90)
        }
        try? context.save()
    }

    func finishWorkout() {
        session?.endDate = Date()
        try? modelContext?.save()
        stopTimers()
        isActive = false
    }

    func discardWorkout(context: ModelContext) {
        if let session {
            context.delete(session)
            try? context.save()
        }
        stopTimers()
        session = nil
        isActive = false
        elapsedSeconds = 0
    }

    func startRestTimer(seconds: Int) {
        restTimerSeconds = seconds
        isRestTimerRunning = true
        restTimer?.invalidate()
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.restTimerSeconds > 0 {
                self.restTimerSeconds -= 1
            } else {
                self.isRestTimerRunning = false
                self.restTimer?.invalidate()
            }
        }
    }

    func stopRestTimer() {
        restTimer?.invalidate()
        isRestTimerRunning = false
        restTimerSeconds = 0
    }

    private func startWorkoutTimer() {
        workoutTimer?.invalidate()
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
        }
    }

    private func stopTimers() {
        workoutTimer?.invalidate()
        restTimer?.invalidate()
        workoutTimer = nil
        restTimer = nil
    }

    var formattedElapsed: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    var formattedRest: String {
        let m = restTimerSeconds / 60
        let s = restTimerSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
