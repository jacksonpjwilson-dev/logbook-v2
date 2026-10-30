import SwiftUI

@main
struct LogbookApp: App {
    @StateObject private var store = LogbookStore()
    @State private var path: [LogbookRoute] = []

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $path) {
                HomeScreen(path: $path)
                    .navigationDestination(for: LogbookRoute.self) { route in
                        switch route {
                        case .training: TrainingScreen()
                        case .food: FoodScreen()
                        case .history: HistoryScreen()
                        case .checkins: CheckInScreen()
                        case .settings: SettingsScreen()
                        }
                    }
            }
            .environmentObject(store)
            .preferredColorScheme(store.state.home.theme.palette.light ? .light : .dark)
            .tint(store.state.home.theme.palette.accentColor)
            .task {
                WatchBridge.shared.activate()
                WatchBridge.shared.send(state: store.state)
                if let active = store.state.training.activeSession {
                    WorkoutActivityController.shared.start(session: active)
                }
                WatchBridge.shared.onAction = { [weak store] message in
                    guard let action = message["action"] as? String else { return }
                    switch action {
                    case "startWorkout": store?.startQuickWorkout()
                    case "finishWorkout": _ = store?.finishWorkout(confirmIncomplete: true)
                    default: break
                    }
                }
            }
            .onOpenURL { url in
                guard url.scheme == "logbook", let route = LogbookRoute(rawValue: url.host ?? "") else { return }
                path = [route]
            }
            .alert("Data needs attention", isPresented: Binding(
                get: { store.persistenceError != nil },
                set: { if !$0 { store.clearPersistenceError() } }
            )) {
                Button("OK", role: .cancel) { store.clearPersistenceError() }
            } message: {
                Text(store.persistenceError ?? "")
            }
        }
    }
}
