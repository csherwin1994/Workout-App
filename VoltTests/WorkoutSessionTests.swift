import XCTest
import SwiftData
@testable import Volt

final class WorkoutSessionTests: XCTestCase {

    // MARK: - formattedDuration

    func test_formattedDuration_lessThanOneHour() {
        let session = WorkoutSession(title: "Test")
        session.startDate = Date()
        // Simulate a 5 min 30 sec workout
        session.endDate = session.startDate.addingTimeInterval(5 * 60 + 30)
        XCTAssertEqual(session.formattedDuration, "05:30")
    }

    func test_formattedDuration_moreThanOneHour() {
        let session = WorkoutSession(title: "Test")
        session.startDate = Date()
        session.endDate = session.startDate.addingTimeInterval(1 * 3600 + 2 * 60 + 5)
        XCTAssertEqual(session.formattedDuration, "1:02:05")
    }

    func test_formattedDuration_exactHour() {
        let session = WorkoutSession(title: "Test")
        session.startDate = Date()
        session.endDate = session.startDate.addingTimeInterval(3600)
        XCTAssertEqual(session.formattedDuration, "1:00:00")
    }

    func test_formattedDuration_zeroDuration() {
        let session = WorkoutSession(title: "Test")
        session.startDate = Date()
        session.endDate = session.startDate
        XCTAssertEqual(session.formattedDuration, "00:00")
    }

    // MARK: - totalVolume

    func test_totalVolume_empty() {
        let session = WorkoutSession(title: "Test")
        XCTAssertEqual(session.totalVolume, 0)
    }

    func test_totalVolume_singleSet() {
        let session = WorkoutSession(title: "Test")
        let log = ExerciseLog(exerciseName: "Bench Press", exerciseMuscleGroup: "Chest")
        let set = WorkoutSet(orderIndex: 0, weight: 100, reps: 8)
        set.isCompleted = true
        log.sets.append(set)
        session.exerciseLogs.append(log)
        // totalVolume counts ALL sets (completed + not), not just completed
        XCTAssertEqual(session.totalVolume, 800)
    }

    func test_totalVolume_multipleSets() {
        let session = WorkoutSession(title: "Test")
        let log = ExerciseLog(exerciseName: "Squat", exerciseMuscleGroup: "Legs")
        let set1 = WorkoutSet(orderIndex: 0, weight: 100, reps: 5)
        let set2 = WorkoutSet(orderIndex: 1, weight: 100, reps: 5)
        let set3 = WorkoutSet(orderIndex: 2, weight: 80, reps: 8)
        log.sets.append(contentsOf: [set1, set2, set3])
        session.exerciseLogs.append(log)
        // (100*5) + (100*5) + (80*8) = 500 + 500 + 640 = 1640
        XCTAssertEqual(session.totalVolume, 1640)
    }

    // MARK: - totalSets (only counts completed sets)

    func test_totalSets_noneCompleted() {
        let session = WorkoutSession(title: "Test")
        let log = ExerciseLog(exerciseName: "Bench Press", exerciseMuscleGroup: "Chest")
        let set1 = WorkoutSet(orderIndex: 0, weight: 60, reps: 8)
        let set2 = WorkoutSet(orderIndex: 1, weight: 60, reps: 8)
        log.sets.append(contentsOf: [set1, set2])
        session.exerciseLogs.append(log)
        XCTAssertEqual(session.totalSets, 0)
    }

    func test_totalSets_someCompleted() {
        let session = WorkoutSession(title: "Test")
        let log = ExerciseLog(exerciseName: "Bench Press", exerciseMuscleGroup: "Chest")
        let set1 = WorkoutSet(orderIndex: 0, weight: 60, reps: 8)
        set1.isCompleted = true
        let set2 = WorkoutSet(orderIndex: 1, weight: 60, reps: 8)
        log.sets.append(contentsOf: [set1, set2])
        session.exerciseLogs.append(log)
        XCTAssertEqual(session.totalSets, 1)
    }

    func test_totalSets_allCompleted() {
        let session = WorkoutSession(title: "Test")
        let log = ExerciseLog(exerciseName: "Deadlift", exerciseMuscleGroup: "Back")
        for i in 0..<3 {
            let set = WorkoutSet(orderIndex: i, weight: 140, reps: 5)
            set.isCompleted = true
            log.sets.append(set)
        }
        session.exerciseLogs.append(log)
        XCTAssertEqual(session.totalSets, 3)
    }

    // MARK: - WorkoutSession init defaults

    func test_init_defaultTitle() {
        let session = WorkoutSession()
        XCTAssertEqual(session.title, "My Workout")
        XCTAssertNil(session.endDate)
        XCTAssertEqual(session.notes, "")
        XCTAssertTrue(session.exerciseLogs.isEmpty)
    }

    func test_init_customTitle() {
        let session = WorkoutSession(title: "Push Day")
        XCTAssertEqual(session.title, "Push Day")
    }
}
