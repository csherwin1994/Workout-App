import XCTest
import SwiftData
@testable import Volt

final class DataManagerTests: XCTestCase {

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

    // MARK: - seedExercisesIfNeeded

    func test_seed_insertsExercisesOnFirstLaunch() throws {
        DataManager.seedExercisesIfNeeded(context: context)
        let descriptor = FetchDescriptor<Exercise>()
        let count = try context.fetchCount(descriptor)
        XCTAssertGreaterThan(count, 0)
    }

    func test_seed_insertsAtLeast50Exercises() throws {
        DataManager.seedExercisesIfNeeded(context: context)
        let descriptor = FetchDescriptor<Exercise>()
        let count = try context.fetchCount(descriptor)
        XCTAssertGreaterThanOrEqual(count, 50)
    }

    func test_seed_doesNotDuplicateOnSecondCall() throws {
        DataManager.seedExercisesIfNeeded(context: context)
        DataManager.seedExercisesIfNeeded(context: context)
        let descriptor = FetchDescriptor<Exercise>()
        let countAfterTwoCalls = try context.fetchCount(descriptor)
        // Should be same count — second call is a no-op
        DataManager.seedExercisesIfNeeded(context: context)
        let countAfterThreeCalls = try context.fetchCount(descriptor)
        XCTAssertEqual(countAfterTwoCalls, countAfterThreeCalls)
    }

    func test_seed_allMuscleGroupsPresent() throws {
        DataManager.seedExercisesIfNeeded(context: context)
        let descriptor = FetchDescriptor<Exercise>()
        let exercises = try context.fetch(descriptor)
        let muscleGroups = Set(exercises.map(\.muscleGroup))
        for group in Exercise.MuscleGroup.allCases {
            XCTAssertTrue(muscleGroups.contains(group), "Missing muscle group: \(group.rawValue)")
        }
    }

    func test_seed_exercisesHaveNames() throws {
        DataManager.seedExercisesIfNeeded(context: context)
        let descriptor = FetchDescriptor<Exercise>()
        let exercises = try context.fetch(descriptor)
        for exercise in exercises {
            XCTAssertFalse(exercise.name.isEmpty, "Exercise has empty name")
        }
    }

    func test_seed_exercisesAreNotCustom() throws {
        DataManager.seedExercisesIfNeeded(context: context)
        let descriptor = FetchDescriptor<Exercise>()
        let exercises = try context.fetch(descriptor)
        for exercise in exercises {
            XCTAssertFalse(exercise.isCustom, "\(exercise.name) should not be marked as custom")
        }
    }
}
