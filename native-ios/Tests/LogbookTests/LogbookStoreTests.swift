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
        XCTAssertFalse(row.sets.isEmpty)
        for plannedSet in row.sets {
            store.updateSet(exerciseID: row.id, setID: plannedSet.id, weightKg: 60, reps: 8)
            XCTAssertTrue(store.toggleSet(exerciseID: row.id, setID: plannedSet.id))
        }
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
        XCTAssertEqual(LogbookTheme.allCases.count, 17)
        XCTAssertEqual(LogbookTheme.allCases.filter { $0 != .defaultTheme }.count, 16, "Preserve all existing themes while staging v2 Default")
        XCTAssertEqual(WidgetKind.allCases.count, 38)
        XCTAssertEqual(HomeState().theme, .defaultTheme)
        XCTAssertEqual(HomeState().pages.map(\.name), ["Daily", "Training", "Food", "Progress & History"])
        XCTAssertEqual(LogbookTheme.defaultTheme.tokens.cardOpacity, 0.86, accuracy: 0.001)
        XCTAssertEqual(LogbookTheme.premiumGlass.tokens.cardOpacity, 0.78, accuracy: 0.001)
    }

    func testDailyDefaultUsesApprovedWidgetSizesAndPositions() throws {
        let widgets = try XCTUnwrap(HomeState.defaultPages.first?.widgets.sorted {
            $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row
        })
        XCTAssertEqual(widgets.map(\.kind), [.calories, .nextWorkout, .trainingStreak, .vitals])
        XCTAssertEqual(widgets.map(\.size), [.large, .medium, .small, .small])
        XCTAssertEqual(widgets.map { [$0.row, $0.column] }, [[0, 0], [2, 0], [3, 0], [3, 1]])
        XCTAssertEqual(widgets[0].variant, "Calories & Protein Remaining")
        XCTAssertEqual(widgets[2].variant, "Habits Streak")
        XCTAssertEqual(widgets[3].variant, "Daily Check-in")
    }

    func testMigrationUpdatesOnlyUntouchedPreviousDailyDefault() throws {
        let repository = temporaryRepository()
        var legacy = LogbookState.empty
        legacy.home.pages[0] = previousDailyPage(id: legacy.home.pages[0].id)
        legacy.home.pages[2].name = "My Food Page"
        legacy.home.theme = .oceanBreeze
        try repository.save(legacy)

        let migrated = LogbookStore(repository: repository).state
        let daily = try XCTUnwrap(migrated.home.pages.first)
        XCTAssertEqual(daily.name, "Daily")
        XCTAssertEqual(daily.widgets.map(\.size), [.large, .medium, .small, .small])
        XCTAssertEqual(daily.widgets.map { [$0.row, $0.column] }, [[0, 0], [2, 0], [3, 0], [3, 1]])
        XCTAssertEqual(migrated.home.theme, .oceanBreeze)
        XCTAssertEqual(migrated.home.pages[1], legacy.home.pages[1])
        XCTAssertEqual(migrated.home.pages[2], legacy.home.pages[2])
        XCTAssertEqual(migrated.home.pages[3], legacy.home.pages[3])
        XCTAssertEqual(migrated.home.pages[0].id, legacy.home.pages[0].id)
        XCTAssertEqual(migrated.home.pages[0].widgets.map(\.id), legacy.home.pages[0].widgets.map(\.id))
    }

    func testMigrationDoesNotOverwriteCustomizedDailyLayout() throws {
        let repository = temporaryRepository()
        var legacy = LogbookState.empty
        legacy.home.pages[0] = previousDailyPage(id: legacy.home.pages[0].id)
        legacy.home.pages[0].widgets[3].row = 3
        try repository.save(legacy)

        let loaded = LogbookStore(repository: repository).state
        XCTAssertEqual(loaded.home.pages, legacy.home.pages)
    }

    private func temporaryRepository() -> LogbookRepository {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("LogbookTests-\(UUID().uuidString)", isDirectory: true)
        return LogbookRepository(url: directory.appendingPathComponent("state.json"))
    }

    private func previousDailyPage(id: UUID) -> HomePage {
        HomePage(id: id, name: "Daily", widgets: [
            HomeWidget(kind: .calories, size: .medium, row: 0, column: 0),
            HomeWidget(kind: .nextWorkout, size: .medium, row: 1, column: 0),
            HomeWidget(kind: .trainingStreak, size: .small, row: 2, column: 0, variant: "Habits Streak"),
            HomeWidget(kind: .vitals, size: .small, row: 2, column: 1, variant: "Daily Check-in")
        ])
    }
}
