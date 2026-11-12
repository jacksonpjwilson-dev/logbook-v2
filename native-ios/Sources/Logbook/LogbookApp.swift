import SwiftUI

@main
struct LogbookApp: App {
    @StateObject private var store = Self.makeStore()
    @State private var path: [LogbookRoute] = []
    @State private var showLaunchScreen = !Self.isUITesting

    private static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--ui-testing")
    }

    private static func makeStore() -> LogbookStore {
        guard isUITesting else { return LogbookStore() }

        let storageID = ProcessInfo.processInfo.arguments
            .first(where: { $0.hasPrefix("--qa-storage-id=") })
            .map { String($0.dropFirst("--qa-storage-id=".count)) }
            ?? UUID().uuidString
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Logbook-QA-\(storageID).json")
        let shouldSeedFixture = !FileManager.default.fileExists(atPath: url.path)
        let store = LogbookStore(repository: LogbookRepository(url: url))
        guard shouldSeedFixture else { return store }
        if let themeArgument = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--qa-theme=") }),
           let theme = LogbookTheme(rawValue: String(themeArgument.dropFirst("--qa-theme=".count))) {
            store.setTheme(theme)
        }
        store.setNutritionTargets(calories: 2_000, protein: 150, carbohydrates: 220, fat: 65)
        if let meal = store.state.nutrition.meals.first {
            let fixture = FoodDefinition(
                id: "qa-breakfast",
                name: "QA breakfast",
                basisAmount: 1,
                basisUnit: "serving",
                calories: 450,
                protein: 35,
                carbohydrates: 50,
                fat: 12,
                source: "Synthetic QA fixture"
            )
            store.addFoodDefinition(fixture)
            _ = store.logFood(fixture, meal: meal, quantity: 1, unit: "serving", confirmed: true)
        }
        #if DEBUG
        store.installDefaultDailyQAFixture()
        #else
        _ = store.addTemplate(name: "Upper Body")
        #endif
        return store
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                NavigationStack(path: $path) {
                    HomeScreen(path: $path)
                        .navigationDestination(for: LogbookRoute.self) { route in
                            switch route {
                            case .training: TrainingScreen()
                            case .food: FoodScreen()
                            case .history: HistoryScreen()
                            case .historyDate(let date): HistoryScreen(initialDate: date)
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
                    guard url.scheme == "logbook" else { return }
                    switch url.host {
                    case "training": path = [.training]
                    case "food": path = [.food]
                    case "history": path = [.history]
                    case "checkins": path = [.checkins]
                    case "settings": path = [.settings]
                    default: break
                    }
                }
                .alert("Data needs attention", isPresented: Binding(
                    get: { store.persistenceError != nil },
                    set: { if !$0 { store.clearPersistenceError() } }
                )) {
                    Button("OK", role: .cancel) { store.clearPersistenceError() }
                } message: {
                    Text(store.persistenceError ?? "")
                }

                if showLaunchScreen {
                    LaunchSplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                guard !Self.isUITesting else { return }
                try? await Task.sleep(for: .seconds(3))
                withAnimation(.easeOut(duration: 0.35)) { showLaunchScreen = false }
            }
        }
    }
}
