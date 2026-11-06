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
        XCTAssertEqual(widgets[0].variant, "Calories & Macros Remaining")
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

    func testMigrationRelabelsOnlyUntouchedNamedCaloriesWidgetAndKeepsItsIdentity() throws {
        let repository = temporaryRepository()
        var legacy = LogbookState.empty
        legacy.home.pages[0] = previousNamedDailyPage(id: legacy.home.pages[0].id)
        try repository.save(legacy)

        let loaded = LogbookStore(repository: repository).state
        let daily = try XCTUnwrap(loaded.home.pages.first)
        XCTAssertEqual(daily.widgets.first(where: { $0.kind == .calories })?.variant, "Calories & Macros Remaining")
        XCTAssertEqual(daily.widgets.map(\.id), legacy.home.pages[0].widgets.map(\.id))
    }

    func testDailyHabitDenominatorTreatsNoDueSupplementsAsNeutral() {
        var state = LogbookState.empty
        let today = Calendar.current.startOfDay(for: .now)
        let day = LocalDay.string(today)
        let sleepEnd = today.addingTimeInterval(8 * 60 * 60)
        state.checkins.sleep = [SleepLog(wakeDate: day, bedtime: today, wakeTime: sleepEnd)]
        state.checkins.weights = [WeightLog(date: day, kilograms: 80)]
        let weekday = Calendar.current.component(.weekday, from: today)
        state.checkins.supplements = [Supplement(name: "Weekday-only", schedule: "weekdays", weekdays: [weekday == 1 ? 2 : 1])]

        let metrics = DailyHomeMetrics(state: state, date: today)
        XCTAssertEqual(metrics.eligibleCount, 2)
        XCTAssertEqual(metrics.completedCount, 2)
        XCTAssertTrue(metrics.supplementsComplete)
        XCTAssertTrue(metrics.isPerfectDay)
    }

    func testDailyHabitCompletionRequiresEveryDueSupplementAndKeepsYesterdayStreak() {
        var state = LogbookState.empty
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let supplement = Supplement(name: "Daily", schedule: "daily")
        state.checkins.supplements = [supplement]
        for offset in 1...3 {
            guard let dayDate = calendar.date(byAdding: .day, value: -offset, to: today),
                  let bedtime = calendar.date(byAdding: .hour, value: -8, to: dayDate),
                  let wake = calendar.date(byAdding: .hour, value: 8, to: dayDate) else { continue }
            let key = LocalDay.string(dayDate)
            state.checkins.sleep.append(SleepLog(wakeDate: key, bedtime: bedtime, wakeTime: wake))
            state.checkins.weights.append(WeightLog(date: key, kilograms: 80))
            state.checkins.doses.append(SupplementDose(supplementID: supplement.id, supplementName: supplement.name, date: key, taken: true, explicitlyMarked: true))
        }
        let todayKey = LocalDay.string(today)
        state.checkins.sleep.append(SleepLog(wakeDate: todayKey, bedtime: today, wakeTime: today.addingTimeInterval(8 * 60 * 60)))
        state.checkins.weights.append(WeightLog(date: todayKey, kilograms: 80))

        let metrics = DailyHomeMetrics(state: state, date: today)
        XCTAssertEqual(metrics.eligibleCount, 3)
        XCTAssertEqual(metrics.completedCount, 2)
        XCTAssertFalse(metrics.supplementsComplete)
        XCTAssertFalse(metrics.isPerfectDay)
        XCTAssertEqual(metrics.perfectDayStreak, 3, "An incomplete current day keeps the preceding consecutive perfect-day streak visible")
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

    private func previousNamedDailyPage(id: UUID) -> HomePage {
        HomePage(id: id, name: "Daily", widgets: [
            HomeWidget(kind: .calories, size: .large, row: 0, column: 0, variant: "Calories & Protein Remaining"),
            HomeWidget(kind: .nextWorkout, size: .medium, row: 2, column: 0),
            HomeWidget(kind: .trainingStreak, size: .small, row: 3, column: 0, variant: "Habits Streak"),
            HomeWidget(kind: .vitals, size: .small, row: 3, column: 1, variant: "Daily Check-in")
        ])
    }
}
