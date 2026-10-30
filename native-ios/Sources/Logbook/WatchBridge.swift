import Foundation
import WatchConnectivity

@MainActor
final class WatchBridge: NSObject, WCSessionDelegate {
    static let shared = WatchBridge()
    var onAction: (([String: Any]) -> Void)?
    private var pendingState: LogbookState?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func send(state: LogbookState) {
        pendingState = state
        publishPendingState()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard activationState == .activated else { return }
        publishPendingState()
    }

    private func publishPendingState() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        guard let state = pendingState,
              let data = try? JSONEncoder.logbook.encode(WatchSnapshot.make(from: state)) else { return }
        do { try session.updateApplicationContext(["snapshot": data]) } catch { }
    }

    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        receiveAction(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        receiveAction(userInfo)
    }

    private nonisolated func receiveAction(_ message: [String: Any]) {
        guard message["action"] is String else { return }
        Task { @MainActor [weak self] in self?.onAction?(message) }
    }
}
