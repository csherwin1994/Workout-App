import XCTest
import SwiftData
@testable import Volt

@MainActor
final class ActiveWorkoutViewModelTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: WorkoutSession.self, Exercise.self, Routine.self,
            configurations: config
        )
        context = container.mainContext
    }

    override func tearDown() async throws {
        container = nil
        context = nil
    }

    // MARK: - startWorkout

    func test_startWorkout_setsIsActive() {
        let vm = ActiveWorkoutViewModel()
        vm.startWorkout(context: context)
        XCTAssertTrue(vm.isActive)
    }

    func test_startWorkout_createsSession() {
        let vm = ActiveWorkoutViewModel()
        vm.startWorkout(context: context)
        XCTAssertNotNil(vm.session)
    }

    func test_startWorkout_defaultTitle() {
        let vm = ActiveWorkoutViewModel()
        vm.startWorkout(context: context)
        XCTAssertEqual(vm.session?.title, "My Workout")
    }

    func test_startWorkout_customTitle() {
        let vm = ActiveWorkoutViewModel()
        vm.startWorkout(title: "Push Day", context: context)
        XCTAssertEqual(vm.session?.title, "Push Day")
    }

    func test_startWorkout_resetsElapsedSeconds() {
        let vm = ActiveWorkoutViewModel()
        vm.elapsedSeconds = 120
        vm.startWorkout(context: context)
        XCTAssertEqual(vm.elapsedSeconds, 0)
    }

    // MARK: - finishWorkout

    func test_finishWorkout_setsEndDate() {
        let vm = ActiveWorkoutViewModel()
        vm.startWorkout(context: context)
        vm.finishWorkout(context: context)
        XCTAssertNotNil(vm.session?.endDate)
    }

    func test_finishWorkout_setsIsActiveFalse() {
        let vm = ActiveWorkoutViewModel()
        vm.startWorkout(context: context)
        vm.finishWorkout(context: context)
        XCTAssertFalse(vm.isActive)
    }

    // MARK: - discardWorkout

    func test_discardWorkout_clearsSession() {
        let vm = ActiveWorkoutViewModel()
        vm.startWorkout(context: context)
        vm.discardWorkout(context: context)
        XCTAssertNil(vm.session)
    }

    func test_discardWorkout_setsIsActiveFalse() {
        let vm = ActiveWorkoutViewModel()
        vm.startWorkout(context: context)
        vm.discardWorkout(context: context)
        XCTAssertFalse(vm.isActive)
    }

    func test_discardWorkout_resetsElapsedSeconds() {
        let vm = ActiveWorkoutViewModel()
        vm.startWorkout(context: context)
        vm.elapsedSeconds = 300
        vm.discardWorkout(context: context)
        XCTAssertEqual(vm.elapsedSeconds, 0)
    }

    // MARK: - addExercise

    func test_addExercise_appendsToSession() {
        let vm = ActiveWorkoutViewModel()
        vm.startWorkout(context: context)
        let exercise = Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell)
        context.insert(exercise)
        vm.addExercise(exercise, context: context)
        XCTAssertEqual(vm.session?.exerciseLogs.count, 1)
        XCTAssertEqual(vm.session?.exerciseLogs.first?.exerciseName, "Bench Press")
    }

    func test_addExercise_startsWithOneSet() {
        let vm = ActiveWorkoutViewModel()
        vm.startWorkout(context: context)
        let exercise = Exercise(name: "Squat", muscleGroup: .legs, equipment: .barbell)
        context.insert(exercise)
        vm.addExercise(exercise, context: context)
        XCTAssertEqual(vm.session?.exerciseLogs.first?.sets.count, 1)
    }

    func test_addExercise_doesNothingWithoutActiveSession() {
        let vm = ActiveWorkoutViewModel()
        let exercise = Exercise(name: "Squat", muscleGroup: .legs, equipment: .barbell)
        context.insert(exercise)
        vm.addExercise(exercise, context: context) // should not crash
        XCTAssertNil(vm.session)
    }

    func test_addMultipleExercises_orderIndexIncrements() {
        let vm = ActiveWorkoutViewModel()
        vm.startWorkout(context: context)
        let ex1 = Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell)
        let ex2 = Exercise(name: "Pull Up", muscleGroup: .back, equipment: .bodyweight)
        context.insert(ex1)
        context.insert(ex2)
        vm.addExercise(ex1, context: context)
        vm.addExercise(ex2, context: context)
        let logs = vm.session?.exerciseLogs.sorted { $0.orderIndex < $1.orderIndex }
        XCTAssertEqual(logs?[0].orderIndex, 0)
        XCTAssertEqual(logs?[1].orderIndex, 1)
    }

    // MARK: - addSet

    func test_addSet_incrementsSetCount() {
        let vm = ActiveWorkoutViewModel()
        vm.startWorkout(context: context)
        let exercise = Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell)
        context.insert(exercise)
        vm.addExercise(exercise, context: context)
        let log = vm.session!.exerciseLogs.first!
        vm.addSet(to: log, context: context)
        XCTAssertEqual(log.sets.count, 2)
    }

    func test_addSet_copiesWeightAndRepsFromLastSet() {
        let vm = ActiveWorkoutViewModel()
        vm.startWorkout(context: context)
        let exercise = Exercise(name: "Squat", muscleGroup: .legs, equipment: .barbell)
        context.insert(exercise)
        vm.addExercise(exercise, context: context)
        let log = vm.session!.exerciseLogs.first!
        log.sets.first?.weight = 100
        log.sets.first?.reps = 5
        vm.addSet(to: log, context: context)
        let newSet = log.sets.sorted { $0.orderIndex < $1.orderIndex }.last!
        XCTAssertEqual(newSet.weight, 100)
        XCTAssertEqual(newSet.reps, 5)
    }

    // MARK: - removeSet

    func test_removeSet_decrementsSetCount() {
        let vm = ActiveWorkoutViewModel()
        vm.startWorkout(context: context)
        let exercise = Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell)
        context.insert(exercise)
        vm.addExercise(exercise, context: context)
        let log = vm.session!.exerciseLogs.first!
        vm.addSet(to: log, context: context) // now 2 sets
        let setToRemove = log.sets.first!
        vm.removeSet(setToRemove, from: log, context: context)
        XCTAssertEqual(log.sets.count, 1)
    }

    // MARK: - toggleSetComplete

    func test_toggleSetComplete_marksCompleted() {
        let vm = ActiveWorkoutViewModel()
        vm.startWorkout(context: context)
        let exercise = Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell)
        context.insert(exercise)
        vm.addExercise(exercise, context: context)
        let set = vm.session!.exerciseLogs.first!.sets.first!
        XCTAssertFalse(set.isCompleted)
        vm.toggleSetComplete(set, context: context)
        XCTAssertTrue(set.isCompleted)
        XCTAssertNotNil(set.completedAt)
    }

    func test_toggleSetComplete_startsRestTimer() {
        let vm = ActiveWorkoutViewModel()
        vm.startWorkout(context: context)
        let exercise = Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell)
        context.insert(exercise)
        vm.addExercise(exercise, context: context)
        let set = vm.session!.exerciseLogs.first!.sets.first!
        vm.toggleSetComplete(set, context: context)
        XCTAssertTrue(vm.isRestTimerRunning)
        XCTAssertEqual(vm.restTimerSeconds, 90)
    }

    func test_toggleSetComplete_uncompletes() {
        let vm = ActiveWorkoutViewModel()
        vm.startWorkout(context: context)
        let exercise = Exercise(name: "Bench Press", muscleGroup: .chest, equipment: .barbell)
        context.insert(exercise)
        vm.addExercise(exercise, context: context)
        let set = vm.session!.exerciseLogs.first!.sets.first!
        vm.toggleSetComplete(set, context: context) // complete
        vm.toggleSetComplete(set, context: context) // uncomplete
        XCTAssertFalse(set.isCompleted)
    }

    // MARK: - startFromRoutine

    func test_startFromRoutine_setsTitle() {
        let vm = ActiveWorkoutViewModel()
        let routine = Routine(name: "Push Day")
        context.insert(routine)
        vm.startFromRoutine(routine, context: context)
        XCTAssertEqual(vm.session?.title, "Push Day")
    }

    func test_startFromRoutine_populatesExercises() {
        let vm = ActiveWorkoutViewModel()
        let routine = Routine(name: "Push Day")
        let re1 = RoutineExercise(exerciseName: "Bench Press", exerciseMuscleGroup: "Chest", orderIndex: 0, targetSets: 3, targetReps: 8, targetWeight: 60)
        let re2 = RoutineExercise(exerciseName: "Overhead Press", exerciseMuscleGroup: "Shoulders", orderIndex: 1, targetSets: 3, targetReps: 10, targetWeight: 40)
        routine.exercises.append(contentsOf: [re1, re2])
        context.insert(routine)
        vm.startFromRoutine(routine, context: context)
        XCTAssertEqual(vm.session?.exerciseLogs.count, 2)
    }

    func test_startFromRoutine_correctSetCount() {
        let vm = ActiveWorkoutViewModel()
        let routine = Routine(name: "Leg Day")
        let re = RoutineExercise(exerciseName: "Squat", exerciseMuscleGroup: "Legs", orderIndex: 0, targetSets: 4, targetReps: 5, targetWeight: 100)
        routine.exercises.append(re)
        context.insert(routine)
        vm.startFromRoutine(routine, context: context)
        XCTAssertEqual(vm.session?.exerciseLogs.first?.sets.count, 4)
    }

    // MARK: - formattedElapsed

    func test_formattedElapsed_minutes() {
        let vm = ActiveWorkoutViewModel()
        vm.elapsedSeconds = 5 * 60 + 30
        XCTAssertEqual(vm.formattedElapsed, "05:30")
    }

    func test_formattedElapsed_hours() {
        let vm = ActiveWorkoutViewModel()
        vm.elapsedSeconds = 1 * 3600 + 2 * 60 + 5
        XCTAssertEqual(vm.formattedElapsed, "1:02:05")
    }

    func test_formattedElapsed_zero() {
        let vm = ActiveWorkoutViewModel()
        vm.elapsedSeconds = 0
        XCTAssertEqual(vm.formattedElapsed, "00:00")
    }

    // MARK: - formattedRest

    func test_formattedRest_90seconds() {
        let vm = ActiveWorkoutViewModel()
        vm.restTimerSeconds = 90
        XCTAssertEqual(vm.formattedRest, "1:30")
    }

    func test_formattedRest_zero() {
        let vm = ActiveWorkoutViewModel()
        vm.restTimerSeconds = 0
        XCTAssertEqual(vm.formattedRest, "0:00")
    }

    // MARK: - stopRestTimer

    func test_stopRestTimer_clearsState() {
        let vm = ActiveWorkoutViewModel()
        vm.startRestTimer(seconds: 60)
        vm.stopRestTimer()
        XCTAssertFalse(vm.isRestTimerRunning)
        XCTAssertEqual(vm.restTimerSeconds, 0)
    }
}
