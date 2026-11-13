import XCTest
@testable import Logbook

final class DailyReminderPlannerTests: XCTestCase {
    func testDailyReminderPreferencesAreOffByDefault() {
        let state = LogbookState.empty
        XCTAssertFalse(state.notificationsEnabled)
        XCTAssertNil(state.nutritionReminderTime)
        XCTAssertNil(state.sleepReminderTime)
        XCTAssertNil(state.weightReminderTime)
        XCTAssertNil(state.supplementReminderTime)
        XCTAssertTrue(ReminderService.planDailyReminders(state: state, now: .now).isEmpty)
    }

    func testPlannerUsesLocalTimesAndSuppressesCompletedFoodSleepWeightAndSupplements() throws {
        var calendar = Calendar.current
        calendar.timeZone = .current
        let now = try date(hour: 1, minute: 0, calendar: calendar)
        let today = LocalDay.string(now)
        let tomorrow = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: now))
        let tomorrowKey = LocalDay.string(tomorrow)

        var state = configuredState()
        state.nutrition.targets = NutritionTargets(calories: 2_000, protein: 100, carbohydrates: nil, fat: nil)
        state.nutrition.logs = [FoodLog(
            foodID: "qa-food", foodName: "QA meal", mealID: UUID(), mealName: "Dinner",
            date: today, quantity: 1, unit: "serving", calories: 2_000, protein: 100,
            carbohydrates: 0, fat: 0, confirmedAt: now
        )]
        state.checkins.sleep = [SleepLog(wakeDate: today, bedtime: now.addingTimeInterval(-8 * 3600), wakeTime: now)]
        state.checkins.weights = [WeightLog(date: today, kilograms: 75)]
        let creatine = Supplement(id: UUID(), name: "Creatine", schedule: "daily")
        let vitamin = Supplement(id: UUID(), name: "Vitamin D", schedule: "daily")
        state.checkins.supplements = [creatine, vitamin]
        state.checkins.doses = [
            SupplementDose(supplementID: creatine.id, supplementName: creatine.name, date: today, taken: true),
            SupplementDose(supplementID: vitamin.id, supplementName: vitamin.name, date: today, taken: true)
        ]

        let planned = ReminderService.planDailyReminders(state: state, now: now, calendar: calendar)
        for kind in [ReminderKind.food, .sleep, .weight, .supplements] {
            XCTAssertFalse(planned.contains { $0.kind == kind && LocalDay.string($0.date) == today }, "\(kind.rawValue) is suppressed when today's requirement is complete")
            let next = try XCTUnwrap(planned.first { $0.kind == kind && LocalDay.string($0.date) == tomorrowKey })
            XCTAssertEqual(calendar.component(.hour, from: next.date), 23)
            XCTAssertEqual(calendar.component(.minute, from: next.date), 15)
        }
    }

    func testNapDoesNotCompleteSleepAndWeightAndDeletedRecordsDoNotSuppress() throws {
        let calendar = Calendar.current
        let now = try date(hour: 1, minute: 0, calendar: calendar)
        let key = LocalDay.string(now)
        var state = configuredState()
        state.sleepReminderTime = "23:15"
        state.weightReminderTime = "23:15"
        state.checkins.sleep = [SleepLog(wakeDate: key, bedtime: now.addingTimeInterval(-45 * 60), wakeTime: now, isNap: true)]
        state.checkins.weights = [WeightLog(date: key, kilograms: 75, deletedAt: now.addingTimeInterval(-60))]

        let planned = ReminderService.planDailyReminders(state: state, now: now, calendar: calendar)
        XCTAssertTrue(planned.contains { $0.kind == .sleep && LocalDay.string($0.date) == key })
        XCTAssertTrue(planned.contains { $0.kind == .weight && LocalDay.string($0.date) == key })
    }

    func testSupplementsOnlyRemindOnScheduledDaysUntilEveryDueDoseIsTaken() throws {
        let calendar = Calendar.current
        let now = try date(hour: 1, minute: 0, calendar: calendar)
        let key = LocalDay.string(now)
        let weekday = calendar.component(.weekday, from: now)
        var state = configuredState()
        state.supplementReminderTime = "23:15"
        let first = Supplement(id: UUID(), name: "Creatine", schedule: "selected-days", weekdays: [weekday])
        let second = Supplement(id: UUID(), name: "Vitamin D", schedule: "selected-days", weekdays: [weekday])
        state.checkins.supplements = [first, second]
        state.checkins.doses = [SupplementDose(supplementID: first.id, supplementName: first.name, date: key, taken: true)]

        let incomplete = ReminderService.planDailyReminders(state: state, now: now, calendar: calendar)
        XCTAssertTrue(incomplete.contains { $0.kind == .supplements && LocalDay.string($0.date) == key })
        XCTAssertTrue(incomplete.allSatisfy { reminder in
            reminder.kind != .supplements || state.checkins.supplements.contains { supplement in
                supplement.weekdays.contains(calendar.component(.weekday, from: reminder.date))
            }
        }, "Supplement reminders are only scheduled for eligible weekdays")

        state.checkins.doses.append(SupplementDose(supplementID: second.id, supplementName: second.name, date: key, taken: true))
        let completed = ReminderService.planDailyReminders(state: state, now: now, calendar: calendar)
        XCTAssertFalse(completed.contains { $0.kind == .supplements && LocalDay.string($0.date) == key })
    }

    private func configuredState() -> LogbookState {
        var state = LogbookState.empty
        state.notificationsEnabled = true
        state.nutritionReminderTime = "23:15"
        state.sleepReminderTime = "23:15"
        state.weightReminderTime = "23:15"
        state.supplementReminderTime = "23:15"
        return state
    }

    private func date(hour: Int, minute: Int, calendar: Calendar = .current) throws -> Date {
        let day = calendar.startOfDay(for: .now)
        return try XCTUnwrap(calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day))
    }
}
