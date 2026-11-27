import XCTest
@testable import Logbook

@MainActor
final class SetupProgressTests: XCTestCase {
    func testEveryThemePersistsWithoutChangingTheLayout() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        let repository = LogbookRepository(url: url)
        let store = LogbookStore(repository: repository)
        let pages = store.state.home.pages
        for theme in LogbookTheme.allCases {
            store.setTheme(theme)
            let reloaded = LogbookStore(repository: repository)
            XCTAssertEqual(reloaded.state.home.theme, theme)
            XCTAssertEqual(reloaded.state.home.pages, pages)
        }
    }

    func testLegacyStateAndExistingPreferencesSurviveSetup() throws {
        var original = LogbookState.empty
        original.nutrition.targets = NutritionTargets(calories: 2100, protein: 135.5, carbohydrates: 240, fat: 70)
        original.home.theme = .oceanBreeze
        original.home.preferredWeightUnit = "lb"
        original.checkins.weights = [WeightLog(date: "2026-11-01", kilograms: 80)]
        let json = try JSONEncoder().encode(original)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: json) as? [String: Any])
        object.removeValue(forKey: "setup")
        let legacy = try JSONDecoder().decode(LogbookState.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertNil(legacy.setup)
        let draft = SetupProgress.existing(legacy)
        XCTAssertEqual(Double(draft.calories), 2100)
        XCTAssertEqual(Double(draft.protein), 135.5)
        XCTAssertEqual(draft.weightUnit, "lb")
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let repository = LogbookRepository(url: folder.appendingPathComponent("state.json"))
        try repository.save(legacy)
        let store = LogbookStore(repository: repository)
        var progress = draft
        progress.step = 4
        progress.name = "Synthetic athlete"
        store.saveSetupProgress(progress)
        XCTAssertEqual(LogbookStore(repository: repository).state.setup?.step, 4)
        store.completeSetup(progress)
        let reloaded = LogbookStore(repository: repository)
        XCTAssertTrue(reloaded.state.setup?.completed == true)
        XCTAssertEqual(reloaded.state.nutrition.targets, original.nutrition.targets)
        XCTAssertEqual(reloaded.state.checkins.weights.first?.id, original.checkins.weights.first?.id)
        XCTAssertEqual(reloaded.state.home.pages, original.home.pages)
        XCTAssertEqual(reloaded.state.home.theme, .oceanBreeze)
    }

    func testSetupRejectsInvalidTargetsAndPersistsManualTargets() throws {
        var progress = SetupProgress()
        progress.calories = "-5"
        XCTAssertNotNil(progress.validationMessage)
        progress.calories = "2200"
        progress.protein = "160"
        progress.waterMilliliters = "2000"
        progress.workoutName = "Synthetic workout"
        progress.supplementName = "Synthetic supplement"
        XCTAssertNil(progress.validationMessage)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = LogbookStore(repository: LogbookRepository(url: url))
        store.completeSetup(progress)
        XCTAssertEqual(store.state.nutritionTargets(on: LocalDay.string()).calories, 2200)
        XCTAssertEqual(store.state.nutritionTargets(on: LocalDay.string()).protein, 160)
        XCTAssertEqual(store.state.nutrition.waterGoalMilliliters, 2000)
        store.completeSetup(progress)
        XCTAssertEqual(store.state.training.templates.filter { $0.name == progress.workoutName }.count, 1)
        XCTAssertEqual(store.state.checkins.supplements.filter { $0.name == progress.supplementName }.count, 1)
    }
}
