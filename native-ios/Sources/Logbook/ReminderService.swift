import Foundation
import UserNotifications

enum ReminderService {
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func scheduleNutrition(at time: String?) {
        schedule(id: "nutrition-reminder", title: "Logbook food check-in", body: "Add today’s meals and keep your nutrition log up to date.", time: time)
    }

    static func scheduleTraining(at time: String?) {
        schedule(id: "training-reminder", title: "Logbook training", body: "Check your plan and choose a time for your next workout.", time: time)
    }

    private static func schedule(id: String, title: String, body: String, time: String?) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        guard let time, let parts = time.split(separator: ":").compactMap({ Int($0) }).asPair else { return }
        var components = DateComponents()
        components.hour = parts.0
        components.minute = parts.1
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
