import Foundation
import UserNotifications

enum ReminderKind: String, CaseIterable, Identifiable {
    case food, training, sleep, weight, supplements
    var id: String { rawValue }
}

struct PlannedDailyReminder: Equatable {
    let kind: ReminderKind
    let date: Date
    var identifier: String { "logbook-daily-\(kind.rawValue)-\(LocalDay.string(date))" }
}

enum ReminderService {
    private static let pendingWindowDays = 15

    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func scheduleTraining(at time: String?) {
        schedule(id: "training-reminder", title: "Logbook training", body: "Check your plan and choose a time for your next workout.", time: time)
    }

    /// Pure schedule planning keeps local-day and completion rules testable without
    /// requesting notification permission or relying on simulator notification UI.
    static func planDailyReminders(state: LogbookState, now: Date, calendar: Calendar = .current) -> [PlannedDailyReminder] {
        guard state.notificationsEnabled else { return [] }
        let kinds: [ReminderKind] = [.food, .sleep, .weight, .supplements]
        var result: [PlannedDailyReminder] = []
        for offset in 0..<pendingWindowDays {
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)) else { continue }
            let key = LocalDay.string(day)
            for kind in kinds {
                guard let time = reminderTime(kind, state: state),
                      let fireDate = fireDate(for: time, on: day, calendar: calendar),
                      fireDate > now,
                      !isComplete(kind, state: state, date: day, dateKey: key, calendar: calendar) else { continue }
                result.append(PlannedDailyReminder(kind: kind, date: fireDate))
            }
        }
        return result
    }

    static func refreshDailyReminders(for state: LogbookState, now: Date = .now, calendar: Calendar = .current) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let existingIDs = pending.map(\.identifier).filter { $0.hasPrefix("logbook-daily-") || $0 == "nutrition-reminder" }
        if !existingIDs.isEmpty { center.removePendingNotificationRequests(withIdentifiers: existingIDs) }
        guard state.notificationsEnabled else { return }

        for planned in planDailyReminders(state: state, now: now, calendar: calendar) {
            let content = UNMutableNotificationContent()
            content.title = title(for: planned.kind)
            content.body = body(for: planned.kind)
            content.sound = .default
            content.userInfo = ["category": planned.kind.rawValue, "localDate": LocalDay.string(planned.date)]
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .timeZone], from: planned.date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            let request = UNNotificationRequest(identifier: planned.identifier, content: content, trigger: trigger)
            do { try await center.add(request) } catch { /* Keep reminders best-effort; core logging remains available. */ }
        }
    }

    private static func reminderTime(_ kind: ReminderKind, state: LogbookState) -> String? {
        switch kind {
        case .food: state.nutritionReminderTime
        case .sleep: state.sleepReminderTime
        case .weight: state.weightReminderTime
        case .supplements: state.supplementReminderTime
        case .training: nil
        }
    }

    private static func fireDate(for time: String, on day: Date, calendar: Calendar) -> Date? {
        let values = time.split(separator: ":").compactMap { Int($0) }
        guard values.count == 2, (0..<24).contains(values[0]), (0..<60).contains(values[1]) else { return nil }
        return calendar.date(bySettingHour: values[0], minute: values[1], second: 0, of: day)
    }

    private static func isComplete(_ kind: ReminderKind, state: LogbookState, date: Date, dateKey: String, calendar: Calendar) -> Bool {
        switch kind {
        case .food:
            // Food is complete when its configured adherence target is met.
            return state.nutritionAdherence(on: dateKey) == .onTarget
        case .sleep:
            return state.checkins.sleep.contains { $0.deletedAt == nil && !$0.isNap && $0.wakeDate == dateKey }
        case .weight:
            return state.checkins.weights.contains { $0.deletedAt == nil && $0.date == dateKey }
        case .supplements:
            let weekday = calendar.component(.weekday, from: date)
            let due = state.checkins.supplements.filter {
                $0.deletedAt == nil && ($0.schedule.lowercased() == "daily" || $0.weekdays.contains(weekday))
            }
            guard !due.isEmpty else { return true }
            let activeTakenIDs = Set(state.checkins.doses.filter {
                $0.deletedAt == nil && $0.date == dateKey && $0.taken
            }.map(\.supplementID))
            return due.allSatisfy { activeTakenIDs.contains($0.id) }
        case .training:
            return false
        }
    }

    private static func title(for kind: ReminderKind) -> String {
        switch kind {
        case .food: "Logbook food check-in"
        case .sleep: "Logbook sleep check-in"
        case .weight: "Logbook weight check-in"
        case .supplements: "Logbook supplements"
        case .training: "Logbook training"
        }
    }

    private static func body(for kind: ReminderKind) -> String {
        switch kind {
        case .food: "Add today’s meals and keep your nutrition log up to date."
        case .sleep: "Log last night’s sleep when you’re ready."
        case .weight: "Add today’s weight check-in."
        case .supplements: "Review the supplements scheduled for today."
        case .training: "Check your plan and choose a time for your next workout."
        }
    }

    private static func schedule(id: String, title: String, body: String, time: String?) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard let time, let values = time.split(separator: ":").compactMap({ Int($0) }).asPair,
              (0..<24).contains(values.0), (0..<60).contains(values.1) else { return }
        var components = DateComponents()
        components.hour = values.0
        components.minute = values.1
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}

private extension Array where Element == Int {
    var asPair: (Int, Int)? { count == 2 ? (self[0], self[1]) : nil }
}
