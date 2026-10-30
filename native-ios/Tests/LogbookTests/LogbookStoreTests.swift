import XCTest
@testable import Logbook

@MainActor
final class LogbookStoreTests: XCTestCase {
    func testFoodAdditionRequiresQuantityConfirmationAndPersistsSnapshot() throws {
        let repository = temporaryRepository()
        let store = LogbookStore(repository: repository)
        let meal = try XCTUnwrap(store.state.nutrition.meals.first)
        let food = FoodDefinition(id: "test-oats", name: "Oats", basisAmount: 100, basisUnit: "g", calories: 380, protein: 13, carbohydrates: 68, fat: 7)

        store.addFoodDefinition(food)
        XCTAssertFalse(store.logFood(food, meal: meal, quantity: 50, unit: "g", confirmed: false))
        XCTAssertTrue(store.state.nutrition.logs.isEmpty)
        XCTAssertTrue(store.logFood(food, meal: meal, quantity: 50, unit: "g", confirmed: true))
        XCTAssertEqual(store.state.nutritionTotals(on: LocalDay.string()).calories ?? 0, 190, accuracy: 0.001)
        XCTAssertEqual(store.state.nutritionTotals(on: LocalDay.string()).protein ?? 0, 6.5, accuracy: 0.001)

        let reopened = LogbookStore(repository: repository)
        let log = try XCTUnwrap(reopened.state.nutrition.logs.first)
        XCTAssertEqual(log.foodName, "Oats")
        XCTAssertEqual(log.quantity, 50)
        XCTAssertEqual(log.calories, 190, accuracy: 0.001)
        XCTAssertEqual(log.mealName, meal.name)
    }

    func testWorkoutSetCanBeLoggedAndFinishedThenReopened() throws {
        let repository = temporaryRepository()
        let store = LogbookStore(repository: repository)
        let templateID = try XCTUnwrap(store.addTemplate(name: "Upper A"))
        let exercise = ExerciseDefinition(id: "test-bench", name: "Bench Press", group: "Chest", equipment: "Barbell")
        store.appendExercise(exercise, toTemplate: templateID)
        let template = try XCTUnwrap(store.state.training.templates.first)
        store.startWorkout(template)

        let active = try XCTUnwrap(store.state.training.activeSession)
        let row = try XCTUnwrap(active.exercises.first)
        let set = try XCTUnwrap(row.sets.first)
        store.updateSet(exerciseID: row.id, setID: set.id, weightKg: 60, reps: 8)
        XCTAssertTrue(store.toggleSet(exerciseID: row.id, setID: set.id))
        XCTAssertEqual(store.finishWorkout(confirmIncomplete: false), -1)

        let reopened = LogbookStore(repository: repository)
        XCTAssertNil(reopened.state.training.activeSession)
        let saved = try XCTUnwrap(reopened.state.training.completedSessions.first)
        XCTAssertEqual(saved.templateName, "Upper A")
        XCTAssertEqual(saved.exercises.first?.sets.first?.weightKg, 60)
        XCTAssertEqual(saved.exercises.first?.sets.first?.reps, 8)
        XCTAssertEqual(saved.exercises.first?.sets.first?.completed, true)
    }

    func testApprovedThemeAndWidgetInventoryCounts() {
        XCTAssertEqual(LogbookTheme.allCases.count, 16)
        XCTAssertEqual(WidgetKind.allCases.count, 38)
        XCTAssertEqual(HomeState().theme, .premiumGlass)
        XCTAssertEqual(HomeState().pages.map(\.name), ["Daily", "Training", "Food", "Progress & History"])
    }

    private func temporaryRepository() -> LogbookRepository {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("LogbookTests-\(UUID().uuidString)", isDirectory: true)
        return LogbookRepository(url: directory.appendingPathComponent("state.json"))
    }
}
