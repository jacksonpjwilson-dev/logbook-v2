import Foundation

struct WatchSnapshot: Codable {
    var updatedAt: Date
    var calorieTotal: Double
    var proteinTotal: Double
    var calorieGoal: Double?
    var proteinGoal: Double?
    var activeWorkoutName: String?
    var completedSets: Int
    var plannedSets: Int

    static func make(from state: LogbookState) -> WatchSnapshot {
        let today = LocalDay.string()
        let totals = state.nutritionTotals(on: today)
        let active = state.training.activeSession
        let sets = active?.exercises.flatMap(\.sets) ?? []
        return WatchSnapshot(
            updatedAt: .now,
            calorieTotal: totals.calories ?? 0,
            proteinTotal: totals.protein ?? 0,
            calorieGoal: state.nutrition.targets.calories,
            proteinGoal: state.nutrition.targets.protein,
            activeWorkoutName: active?.templateName,
            completedSets: sets.filter(\.completed).count,
            plannedSets: sets.count
        )
    }
}
