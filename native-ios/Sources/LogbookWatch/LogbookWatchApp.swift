import SwiftUI
import WatchConnectivity

@main
struct LogbookWatchApp: App {
    @StateObject private var model = WatchProgressModel()

    var body: some Scene {
        WindowGroup { WatchHomeView().environmentObject(model) }
    }
}

@MainActor
final class WatchProgressModel: NSObject, ObservableObject, WCSessionDelegate {
    @Published private(set) var snapshot = WatchSnapshot.empty
    @Published private(set) var connectionState = "Connecting…"

    override init() {
        super.init()
        guard WCSession.isSupported() else { connectionState = "iPhone unavailable"; return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func send(_ action: String) {
        guard WCSession.isSupported() else { connectionState = "Pair with iPhone to record"; return }
        let session = WCSession.default
        guard session.activationState == .activated else { connectionState = "Connecting to iPhone…"; return }
        let message: [String: Any] = ["action": action]
        if session.isReachable {
            session.sendMessage(message, replyHandler: { [weak self] _ in
                Task { @MainActor in self?.connectionState = "Updated" }
            }, errorHandler: { [weak self] _ in
                session.transferUserInfo(message)
                Task { @MainActor in self?.connectionState = "Queued for iPhone" }
            })
        } else {
            session.transferUserInfo(message)
            connectionState = "Queued for iPhone"
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            connectionState = error == nil ? "Connected" : "iPhone unavailable"
            if let data = session.receivedApplicationContext["snapshot"] as? Data,
               let value = Self.decode(data) { snapshot = value }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext["snapshot"] as? Data,
              let value = Self.decode(data) else { return }
        Task { @MainActor in snapshot = value }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        guard let data = userInfo["snapshot"] as? Data,
              let value = Self.decode(data) else { return }
        Task { @MainActor in snapshot = value }
    }

    private static func decode(_ data: Data) -> WatchSnapshot? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WatchSnapshot.self, from: data)
    }
}

struct WatchHomeView: View {
    @EnvironmentObject private var model: WatchProgressModel
    private var active: Bool { model.snapshot.activeWorkoutName != nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("LOGBOOK").font(.system(size: 10, weight: .bold)).tracking(1.6).foregroundStyle(.secondary)
                Text("Today").font(.title3.bold())
                VStack(alignment: .leading, spacing: 7) {
                    Text("Nutrition").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    metric("Calories", value: "\(Int(model.snapshot.calorieTotal))", goal: model.snapshot.calorieGoal.map { "of \(Int($0))" })
                    metric("Protein", value: "\(Int(model.snapshot.proteinTotal)) g", goal: model.snapshot.proteinGoal.map { "of \(Int($0)) g" })
                }
                if active {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Workout").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        Text(model.snapshot.activeWorkoutName ?? "Workout").font(.headline).lineLimit(2)
                        Text("\(model.snapshot.completedSets) of \(model.snapshot.plannedSets) sets").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Button { model.send(active ? "finishWorkout" : "startWorkout") } label: {
                    Label(active ? "Finish workout" : "Start workout", systemImage: active ? "stop.fill" : "play.fill")
                        .font(.caption.bold()).frame(maxWidth: .infinity).padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                Text(model.connectionState).font(.system(size: 9)).foregroundStyle(.tertiary).frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 4)
        }
    }

    private func metric(_ title: String, value: String, goal: String?) -> some View {
        HStack(alignment: .firstTextBaseline) { Text(title).font(.caption2); Spacer(); Text(value).font(.headline.monospacedDigit()); if let goal { Text(goal).font(.system(size: 8)).foregroundStyle(.secondary) } }
    }
}

extension WatchSnapshot {
    static var empty: WatchSnapshot {
        WatchSnapshot(updatedAt: .distantPast, calorieTotal: 0, proteinTotal: 0, calorieGoal: nil, proteinGoal: nil, activeWorkoutName: nil, completedSets: 0, plannedSets: 0)
    }
}
