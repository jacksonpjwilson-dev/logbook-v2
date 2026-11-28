import SwiftUI

struct SetupScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft: SetupProgress
    @State private var error: String?
    @State private var showThemes = false
    private let titles = ["Welcome", "Your account", "About you", "Nutrition targets", "Training", "Daily wellbeing", "Apple Health", "Your theme", "Ready to begin"]

    init(progress: SetupProgress) {
        var restored = progress
        restored.step = max(0, min(8, restored.step))
        _draft = State(initialValue: restored)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ProgressView(value: Double(draft.step), total: Double(titles.count - 1))
                        .tint(store.state.home.theme.palette.accentColor)
                        .accessibilityLabel("Setup step \(draft.step + 1) of \(titles.count)")
                }
                stage
                if let error { Text(error).foregroundStyle(.red).accessibilityIdentifier("setup-error") }
                if let message = store.persistenceError { Text(message).foregroundStyle(.red) }
                Section {
                    Button(draft.step == titles.count - 1 ? "Open Logbook" : "Continue") { advance() }
                        .accessibilityIdentifier("setup-continue")
                    if (2...7).contains(draft.step) {
                        Button("Skip this step") { changeStep(by: 1) }
                            .accessibilityIdentifier("setup-skip")
                    }
                    if draft.step > 0 {
                        Button("Back") { changeStep(by: -1) }
                            .accessibilityIdentifier("setup-back")
                    }
                }
            }
            .navigationTitle(titles[draft.step])
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Finish later") {
                        saveProgress()
                        if store.persistenceError == nil { dismiss() }
                    }
                }
            }
            .sheet(isPresented: $showThemes) { ThemeGalleryScreen() }
        }
        .interactiveDismissDisabled()
        .tint(store.state.home.theme.palette.accentColor)
    }

    @ViewBuilder private var stage: some View {
        switch draft.step {
        case 0:
            Section {
                Label("Welcome to Logbook", systemImage: "book.closed.fill").font(.title2.bold())
                Text("Make room for your food, training and daily wellbeing. Set your goals now or come back whenever you’re ready.")
                Text("Your existing records and layouts stay with you. Preferences take effect when you finish setup.")
            }
        case 1:
            Section {
                Label("Accounts are coming later", systemImage: "person.crop.circle")
                Text("Account registration and sign-in are deferred while we choose a provider. You can set up and use Logbook on this iPhone.")
                Text("Your records are saved locally. Account sync is unavailable.")
            }
        case 2:
            Section("Personal profile") {
                TextField("Preferred name", text: persisted(\.name)).textContentType(.givenName)
                Picker("Fitness objective", selection: persisted(\.objective)) {
                    ForEach(["General fitness", "Build strength", "Build muscle", "Improve endurance", "Manage weight"], id: \.self) { Text($0) }
                }
            }
        case 3:
            Section("Your daily targets") {
                Text("Enter your own targets. Leave any target blank to keep it unset.")
                target("Calories (kcal)", text: persisted(\.calories))
                target("Protein (g)", text: persisted(\.protein))
                target("Carbohydrates (g)", text: persisted(\.carbohydrates))
                target("Fat (g)", text: persisted(\.fat))
            }
        case 4:
            Section("Training preferences") {
                Picker("Approach", selection: persisted(\.trainingPreference)) {
                    ForEach(["Flexible", "Strength", "Hypertrophy", "Endurance"], id: \.self) { Text($0) }
                }
                TextField("Optional first workout name", text: persisted(\.workoutName))
                Text("Your workout will be added to your active program.")
                NavigationLink("Configure workout split", destination: TrainingScreen())
                Text("Workouts edited here are saved immediately in Training.")
            }
        case 5:
            Section("Daily wellbeing") {
                target("Sleep goal (hours)", text: persisted(\.sleepHours))
                target("Hydration goal (mL)", text: persisted(\.waterMilliliters))
                Picker("Weight unit", selection: persisted(\.weightUnit)) {
                    Text("Kilograms").tag("kg")
                    Text("Pounds").tag("lb")
                }
                TextField("Optional daily supplement", text: persisted(\.supplementName))
                Text("Existing measurements, sleep records and supplement schedules are preserved.")
            }
        case 6:
            Section {
                Label("Apple Health access is off", systemImage: "heart.slash")
                Text("This build uses manual entries. Health permission and import setup remain deferred; continuing will not request access.")
            }
        case 7:
            Section {
                Button { showThemes = true } label: {
                    HStack { Text("Choose your theme"); Spacer(); Text(store.state.home.theme.title).foregroundStyle(.secondary) }
                }
                Text("Every theme uses the same widgets and controls.")
            }
        default:
            Section {
                Label(draft.name.isEmpty ? "Your Logbook is ready" : "Ready, \(draft.name)", systemImage: "checkmark.circle.fill")
                    .font(.title2.bold())
                LabeledContent("Objective", value: draft.objective)
                LabeledContent("Training", value: draft.trainingPreference)
                LabeledContent("Theme", value: store.state.home.theme.title)
                Text("Your targets and preferences will appear across Logbook. Revisit setup from Settings at any time.")
            }
        }
    }

    private func target(_ title: String, text: Binding<String>) -> some View {
        TextField(title, text: text).keyboardType(.decimalPad)
    }

    private func changeStep(by amount: Int) {
        error = nil
        draft.step = max(0, min(titles.count - 1, draft.step + amount))
        saveProgress()
    }

    // Persist inside the edit binding: a later render callback can be lost
    // when the process exits immediately after the final keystroke.
    private func persisted<Value>(_ keyPath: WritableKeyPath<SetupProgress, Value>) -> Binding<Value> {
        Binding(get: { draft[keyPath: keyPath] }, set: { value in
            draft[keyPath: keyPath] = value
            saveProgress()
        })
    }

    private func saveProgress() { store.saveSetupProgress(draft) }

    private func advance() {
        guard draft.validationMessage == nil else { error = draft.validationMessage; return }
        if draft.step < titles.count - 1 { changeStep(by: 1); return }
        store.completeSetup(draft)
        if store.persistenceError == nil { dismiss() }
    }
}
