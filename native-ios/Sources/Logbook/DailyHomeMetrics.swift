import Foundation

/// Values shared by the Daily Habits and Check-in widgets. A scheduled dose
/// is required only on its scheduled weekday; no due dose is a neutral state.
struct DailyHomeMetrics {
    let date: Date
    let sleep: SleepLog?
    let weight: WeightLog?
    let dueSupplements: [Supplement]
    let takenSupplementCount: Int
    let completedCount: Int
    let eligibleCount: Int
    let perfectDayStreak: Int

    var supplementsComplete: Bool {
        dueSupplements.isEmpty || takenSupplementCount == dueSupplements.count
    }

    var isPerfectDay: Bool {
        sleep != nil && weight != nil && supplementsComplete
    }

    init(state: LogbookState, date: Date = .now, calendar: Calendar = .current) {
        self.date = calendar.startOfDay(for: date)
        let dayKey = LocalDay.string(date)
        let daySleep = state.checkins.sleep.first { $0.deletedAt == nil && !$0.isNap && $0.wakeDate == dayKey && $0.durationMinutes > 0 }
        let dayWeight = state.checkins.weights.first { $0.deletedAt == nil && $0.date == dayKey && $0.kilograms > 0 }
        sleep = daySleep
        weight = dayWeight
        let dayDueSupplements = state.checkins.supplements.filter { supplement in
            if supplement.deletedAt == nil && supplement.schedule.lowercased() == "daily" { return true }
            let weekday = calendar.component(.weekday, from: date)
            return supplement.deletedAt == nil && supplement.weekdays.contains(weekday)
        }
        dueSupplements = dayDueSupplements
        let dueIDs = Set(dayDueSupplements.map(\.id))
        let dayDoses = state.checkins.doses.filter {
            $0.deletedAt == nil && $0.date == dayKey && dueIDs.contains($0.supplementID) && $0.explicitlyMarked && $0.taken
        }
        let takenIDs = Set(dayDoses.map(\.supplementID))
        takenSupplementCount = takenIDs.count
        let hasDueSupplements = !dayDueSupplements.isEmpty
        eligibleCount = hasDueSupplements ? 3 : 2
        completedCount = (daySleep == nil ? 0 : 1) + (dayWeight == nil ? 0 : 1) +
            (hasDueSupplements && dueIDs.isSubset(of: takenIDs) ? 1 : 0)

        func perfect(on day: Date) -> Bool {
            let key = LocalDay.string(day)
            let hasSleep = state.checkins.sleep.contains { $0.deletedAt == nil && !$0.isNap && $0.wakeDate == key && $0.durationMinutes > 0 }
            let hasWeight = state.checkins.weights.contains { $0.deletedAt == nil && $0.date == key && $0.kilograms > 0 }
            let weekday = calendar.component(.weekday, from: day)
            let due = state.checkins.supplements.filter {
                $0.deletedAt == nil && ($0.schedule.lowercased() == "daily" || $0.weekdays.contains(weekday))
            }
            let dueIDs = Set(due.map(\.id))
            let takenIDs = Set(state.checkins.doses.filter {
                $0.deletedAt == nil && $0.date == key && dueIDs.contains($0.supplementID) && $0.explicitlyMarked && $0.taken
            }.map(\.supplementID))
            return hasSleep && hasWeight && dueIDs.isSubset(of: takenIDs)
        }

        var cursor = calendar.startOfDay(for: date)
        if !perfect(on: cursor) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor), perfect(on: yesterday) else {
                perfectDayStreak = 0
                return
            }
            cursor = yesterday
        }
        var streak = 0
        while streak < 366 && perfect(on: cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        perfectDayStreak = streak
    }
}
