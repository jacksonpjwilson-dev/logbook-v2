import SwiftUI

struct TrainingScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @State private var showCreate = false
    @State private var creatingProgram = false
    @State private var workoutName = ""
    @State private var showActiveWorkout = false
    @State private var showDeleteTemplate: UUID?
    @State private var pendingProgramID: UUID?
    @State private var editingProgramID: UUID?

    private var activeProgram: WorkoutProgram? { store.state.training.activeProgram }
    private var activeTemplates: [WorkoutTemplate] {
        guard let activeProgram else { return store.state.training.templates }
        let templates = Dictionary(uniqueKeysWithValues: store.state.training.templates.map { ($0.id, $0) })
        return activeProgram.templateIDs.compactMap { templates[$0] }
    }

    var body: some View {
        List {
            if let active = store.state.training.activeSession {
                Section("Workout in progress") {
                    Button { showActiveWorkout = true } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle.fill").font(.system(size: 28)).foregroundStyle(store.state.home.theme.palette.accentColor)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(active.templateName).font(.headline)
                                Text("\(active.exercises.flatMap(\.sets).filter(\.completed).count) of \(active.exercises.flatMap(\.sets).count) sets · Started \(active.startedAt.formatted(date: .omitted, time: .shortened))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("training-active-session")
                }
            }

            Section("Programs") {
                ForEach(store.state.training.availablePrograms) { program in
                    Button { requestProgramSwitch(program.id) } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(program.name).font(.headline)
                                let next = program.scheduledTemplate(in: store.state.training.templates)?.name ?? "No workouts in this program"
                                Text("Next · \(next)").font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer(minLength: 8)
                            if program.id == activeProgram?.id {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(store.state.home.theme.palette.accentColor)
                                    .accessibilityLabel("Active program")
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("training-program-\(program.id.uuidString)")
                    .contextMenu {
                        Button("Rename program", systemImage: "pencil") {
                            editingProgramID = program.id
                            workoutName = program.name
                            showCreate = true
                        }
                    }
                }
                Button {
                    creatingProgram = true
                    editingProgramID = nil
                    showCreate = true
                } label: { Label("New program", systemImage: "plus.circle") }
                if store.state.training.activeSession == nil, store.state.training.scheduledTemplate != nil {
                    Button(role: .destructive) { _ = store.skipScheduledWorkout() } label: {
                        Label("Skip scheduled workout", systemImage: "forward.fill")
                    }
                    .accessibilityIdentifier("skip-scheduled-workout")
                }
            }

            Section {
                if activeTemplates.isEmpty {
                    ContentUnavailableView("Create your first workout", systemImage: "dumbbell", description: Text("Choose a name, add exercises from the built-in library, then start a session. Your history begins when you save a workout."))
                        .listRowBackground(Color.clear)
                }
                ForEach(activeTemplates) { template in
                    NavigationLink(destination: WorkoutTemplateScreen(templateID: template.id)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name).font(.headline)
                            Text("\(template.exercises.count) exercises · \(template.exercises.reduce(0) { $0 + $1.sets.count }) planned sets")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .contextMenu {
                        ForEach(store.state.training.availablePrograms.filter { $0.id != activeProgram?.id }) { destination in
                            Button("Move to \(destination.name)", systemImage: "folder") {
                                store.moveTemplate(template.id, toProgram: destination.id, at: destination.templateIDs.count)
                            }
                        }
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) { showDeleteTemplate = template.id }
                    }
                }
                .onMove { sources, destination in
                    guard let programID = activeProgram?.id else { return }
                    var orderedIDs = activeTemplates.map(\.id)
                    let moving = sources.map { orderedIDs[$0] }
                    orderedIDs.remove(atOffsets: sources)
                    let adjustedDestination = destination - sources.filter { $0 < destination }.count
                    orderedIDs.insert(contentsOf: moving, at: adjustedDestination)
                    store.reorderProgramTemplates(programID: programID, orderedIDs: orderedIDs)
                }
            } header: {
                HStack {
                    Text("Your workouts")
                        .accessibilityIdentifier("training-workouts-heading")
                    Spacer()
                    Button { creatingProgram = false; editingProgramID = nil; showCreate = true } label: { Label("New", systemImage: "plus") }
                        .labelStyle(.titleAndIcon)
                }
            }

            Section("Recent sessions") {
                if store.state.training.visibleCompletedSessions.isEmpty {
                    Text("Completed workouts will appear here.").foregroundStyle(.secondary)
                } else {
                    ForEach(store.state.training.visibleCompletedSessions.sorted { $0.startedAt > $1.startedAt }.prefix(8)) { session in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.templateName).font(.headline)
                                Text("\(session.localDate) · \(session.exercises.flatMap(\.sets).filter(\.completed).count) completed sets")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(volume(session)).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Exercise library") {
                Label("\(store.state.training.exercises.count) exercises available", systemImage: "figure.strengthtraining.traditional")
                Text("Built-in exercise names and instructions come from the existing Logbook library. Add custom exercises from a workout plan.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Training")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { EditButton() }
            ToolbarItem(placement: .topBarTrailing) { Button { creatingProgram = false; editingProgramID = nil; showCreate = true } label: { Image(systemName: "plus") }.accessibilityLabel("New workout") }
        }
        .alert(creatingProgram ? "New program" : (editingProgramID == nil ? "New workout" : "Rename program"), isPresented: $showCreate) {
            TextField("Workout name", text: $workoutName)
            Button(editingProgramID == nil ? "Create" : "Save") {
                if creatingProgram {
                    if let id = store.addProgram(name: workoutName, activate: false) {
                        if store.state.training.activeSession == nil { store.setActiveProgram(id) }
                        else { pendingProgramID = id }
                    }
                } else if let editingProgramID {
                    store.renameProgram(editingProgramID, name: workoutName)
                } else {
                    _ = store.addTemplate(name: workoutName)
                }
                workoutName = ""
                creatingProgram = false
                editingProgramID = nil
            }
            Button("Cancel", role: .cancel) { workoutName = ""; creatingProgram = false; editingProgramID = nil }
        } message: { Text(creatingProgram ? "Each program keeps its own workout order and next scheduled workout." : (editingProgramID == nil ? "You can add exercises after creating it." : "Workout history is unchanged when a program is renamed.")) }
        .confirmationDialog("Switch workout program?", isPresented: Binding(
            get: { pendingProgramID != nil },
            set: { if !$0 { pendingProgramID = nil } }
        ), titleVisibility: .visible) {
            Button("Switch program") {
                if let pendingProgramID { store.setActiveProgram(pendingProgramID) }
                pendingProgramID = nil
            }
            Button("Keep current program", role: .cancel) { pendingProgramID = nil }
        } message: {
            Text("Your unfinished workout stays attached to its original program and will not be moved.")
        }
        .confirmationDialog("Delete this workout plan?", isPresented: Binding(
            get: { showDeleteTemplate != nil },
            set: { if !$0 { showDeleteTemplate = nil } }
        ), titleVisibility: .visible) {
            Button("Delete plan", role: .destructive) {
                if let id = showDeleteTemplate { store.deleteTemplate(id) }
                showDeleteTemplate = nil
            }
        } message: { Text("Completed sessions keep their saved workout details.") }
        .sheet(isPresented: $showActiveWorkout) {
            ActiveWorkoutScreen().presentationDetents([.large]).presentationDragIndicator(.visible)
        }
        .onAppear { presentRequestedWorkoutIfNeeded() }
        .onChange(of: store.activeWorkoutPresentationRequest) { _, _ in presentRequestedWorkoutIfNeeded() }
    }

    private func requestProgramSwitch(_ id: UUID) {
        guard id != activeProgram?.id else { return }
        if store.state.training.activeSession != nil { pendingProgramID = id }
        else { store.setActiveProgram(id) }
    }

    private func presentRequestedWorkoutIfNeeded() {
        guard store.activeWorkoutPresentationRequest != nil,
              store.state.training.activeSession != nil else { return }
        showActiveWorkout = true
        store.consumeActiveWorkoutPresentationRequest()
    }

    private func volume(_ session: WorkoutSession) -> String {
        let value = session.exercises.flatMap(\.sets).filter(\.completed).reduce(0.0) { $0 + ($1.weightKg ?? 0) * Double($1.reps) }
        return value > 0 ? "\(Int(value)) kg" : "Saved"
    }
}

struct WorkoutTemplateScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    let templateID: UUID
    @State private var showExercisePicker = false
    @State private var startSession = false
    @State private var editingName = false
    @State private var nameDraft = ""

    private var template: WorkoutTemplate? { store.state.training.templates.first { $0.id == templateID } }

    var body: some View {
        Group {
            if let template {
                List {
                    Section {
                        Button { startSession = true } label: {
                            Label("Start \(template.name)", systemImage: "play.fill").frame(maxWidth: .infinity, alignment: .center)
                        }
                        .font(.headline).listRowBackground(store.state.home.theme.palette.accentColor.opacity(0.22))
                    }
                    Section {
                        if template.exercises.isEmpty {
                            Text("Add exercises to make this plan ready to start.").foregroundStyle(.secondary)
                        }
                        ForEach(template.exercises) { exercise in
                            DisclosureGroup {
                                Picker("Tracking mode", selection: Binding(
                                    get: { exercise.trackingMode ?? .weightAndReps },
                                    set: { store.configurePlannedExercise(templateID: templateID, exerciseID: exercise.id, setCount: exercise.sets.count, reps: exercise.sets.first?.reps ?? 8, restSeconds: exercise.restSeconds, trackingMode: $0) }
                                )) {
                                    ForEach(ExerciseTrackingMode.allCases) { mode in Text(mode.title).tag(mode) }
                                }
                                Stepper("Sets · \(exercise.sets.count)", value: Binding(
                                    get: { exercise.sets.count },
                                    set: { store.configurePlannedExercise(templateID: templateID, exerciseID: exercise.id, setCount: $0, reps: exercise.sets.first?.reps ?? 8, restSeconds: exercise.restSeconds) }
                                ), in: 1...30)
                                Stepper("Reps · \(exercise.sets.first?.reps ?? 8)", value: Binding(
                                    get: { exercise.sets.first?.reps ?? 8 },
                                    set: { store.configurePlannedExercise(templateID: templateID, exerciseID: exercise.id, setCount: exercise.sets.count, reps: $0, restSeconds: exercise.restSeconds) }
                                ), in: 1...100)
                                Stepper("Rest · \(exercise.restSeconds.map { "\($0)s" } ?? "90s default")", value: Binding(
                                    get: { exercise.restSeconds ?? 90 },
                                    set: { store.configurePlannedExercise(templateID: templateID, exerciseID: exercise.id, setCount: exercise.sets.count, reps: exercise.sets.first?.reps ?? 8, restSeconds: $0) }
                                ), in: 15...600, step: 15)
                                if exercise.restSeconds != nil {
                                    Button("Use workout default rest") {
                                        store.configurePlannedExercise(templateID: templateID, exerciseID: exercise.id, setCount: exercise.sets.count, reps: exercise.sets.first?.reps ?? 8, restSeconds: nil)
                                    }
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name).font(.headline)
                                Text("\(exercise.muscle) · \(exercise.sets.count) sets · \(exercise.trackingMode?.title ?? "Weight + reps") · \(exercise.equipment)").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .swipeActions {
                                Button("Remove", role: .destructive) { store.removeExercise(exercise.id, fromTemplate: templateID) }
                            }
                            .contextMenu {
                                if let index = template.exercises.firstIndex(where: { $0.id == exercise.id }), index > 0 {
                                    let previous = template.exercises[index - 1]
                                    Button("Superset with \(previous.name)", systemImage: "link") {
                                        store.setSuperset(templateID: templateID, exerciseIDs: [previous.id, exercise.id])
                                    }
                                }
                                if exercise.supersetID != nil {
                                    Button("Remove from superset", systemImage: "link.slash") {
                                        store.ungroupExercise(templateID: templateID, exerciseID: exercise.id)
                                    }
                                }
                            }
                        }
                        .onMove { sources, destination in
                            var orderedIDs = template.exercises.map(\.id)
                            let moving = sources.map { orderedIDs[$0] }
                            orderedIDs.remove(atOffsets: sources)
                            let adjustedDestination = destination - sources.filter { $0 < destination }.count
                            orderedIDs.insert(contentsOf: moving, at: adjustedDestination)
                            store.reorderTemplateExercises(templateID: templateID, orderedIDs: orderedIDs)
                        }
                        Button { showExercisePicker = true } label: { Label("Add exercise", systemImage: "plus.circle.fill") }
                    } header: { Text("Exercise plan") }
                    Section("Plan") {
                        Button("Rename workout") { nameDraft = template.name; editingName = true }
                        Text("Editing this plan creates a new version. Workouts already saved keep their original exercise and set details.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .navigationTitle(template.name)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { EditButton() } }
            } else {
                ContentUnavailableView("Workout plan unavailable", systemImage: "dumbbell")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerScreen { exercise in store.appendExercise(exercise, toTemplate: templateID) }
                .presentationDetents([.large]).presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $startSession) {
            Group {
                if let template { ActiveWorkoutScreen(onStart: { store.startWorkout(template) }) }
            }
            .presentationDetents([.large]).presentationDragIndicator(.visible)
        }
        .alert("Rename workout", isPresented: $editingName) {
            TextField("Workout name", text: $nameDraft)
            Button("Save") { store.renameTemplate(templateID, name: nameDraft) }
            Button("Cancel", role: .cancel) { }
        }
    }
}

struct ExercisePickerScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    let select: (ExerciseDefinition) -> Void
    @State private var search = ""
    @State private var showCustom = false

    private var filtered: [ExerciseDefinition] {
        guard !search.isEmpty else { return store.state.training.exercises }
        return store.state.training.exercises.filter {
            $0.name.localizedCaseInsensitiveContains(search) || $0.group.localizedCaseInsensitiveContains(search) ||
                $0.equipment.localizedCaseInsensitiveContains(search) || $0.description.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { showCustom = true } label: { Label("Create custom exercise", systemImage: "plus.circle") }
                }
                Section("Built-in exercises · \(filtered.count)") {
                    ForEach(filtered) { exercise in
                        Button {
                            select(exercise)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(exercise.name).font(.headline)
                                Text("\(exercise.group) · \(exercise.equipment)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("Choose exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .searchable(text: $search, prompt: "Exercise, muscle, or equipment")
            .sheet(isPresented: $showCustom) {
                CustomExerciseScreen { item in select(item); dismiss() }
                    .presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
            }
        }
    }
}

struct CustomExerciseScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    let onCreate: (ExerciseDefinition) -> Void
    @State private var name = ""
    @State private var muscle = "Other"
    @State private var equipment = ""
    @State private var instructions = ""
    @State private var trackingMode: ExerciseTrackingMode = .weightAndReps

    var body: some View {
        NavigationStack {
            Form {
                TextField("Exercise name", text: $name)
                TextField("Primary muscle", text: $muscle)
                TextField("Equipment", text: $equipment)
                Picker("Tracking mode", selection: $trackingMode) {
                    ForEach(ExerciseTrackingMode.allCases) { mode in Text(mode.title).tag(mode) }
                }
                TextField("Optional instructions", text: $instructions, axis: .vertical).lineLimit(2...5)
            }
            .navigationTitle("Custom exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let item = store.addCustomExercise(name: name, muscle: muscle, equipment: equipment.isEmpty ? "Other" : equipment, instructions: instructions, trackingMode: trackingMode) else { return }
                        onCreate(item); dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct ActiveWorkoutScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    @State private var showExercisePicker = false
    @State private var replacingExerciseID: UUID?
    @State private var showFinishConfirmation = false
    @State private var showDiscardConfirmation = false
    @State private var incompleteCount = 0
    @State private var expandedExerciseID: UUID?
    @State private var showCompletionSummary = false
    @State private var completedSessionForSummary: WorkoutSession?
    var onStart: (() -> Void)?

    private var session: WorkoutSession? { store.state.training.activeSession }
    private var focusedExerciseID: UUID? { session?.currentExerciseID }

    var body: some View {
        NavigationStack {
            Group {
                if let session {
                    List {
                        Section {
                            TimelineView(.periodic(from: .now, by: 1)) { context in
                                let timer = session.restTimer ?? WorkoutRestTimer()
                                let remaining = timer.remainingSeconds(at: context.date)
                                VStack(alignment: .leading, spacing: 9) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Label("Rest timer", systemImage: "timer")
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                        Text(remaining > 0 ? restTime(remaining) : "Ready")
                                            .font(.system(.title3, design: .rounded, weight: .semibold).monospacedDigit())
                                            .accessibilityIdentifier("rest-timer-value")
                                    }
                                    ProgressView(value: timer.baseDurationSeconds > 0
                                        ? Double(min(timer.currentDurationSeconds, remaining)) / Double(max(1, timer.currentDurationSeconds))
                                        : 0)
                                        .tint(Color.blue)
                                    HStack(spacing: 8) {
                                        if timer.isPaused {
                                            Button { store.resumeRestTimer() } label: { Label("Resume", systemImage: "play.fill") }
                                                .accessibilityIdentifier("rest-resume")
                                        } else {
                                            Button { store.pauseRestTimer() } label: { Label("Pause", systemImage: "pause.fill") }
                                                .disabled(remaining == 0)
                                                .accessibilityIdentifier("rest-pause")
                                        }
                                        Button("+15 sec") { store.addFifteenSecondsToRestTimer() }
                                            .accessibilityIdentifier("rest-add-15")
                                        Button("Skip") { store.skipRestTimer() }
                                            .disabled(remaining == 0)
                                            .accessibilityIdentifier("rest-skip")
                                        Spacer(minLength: 0)
                                        Menu("\(timer.baseDurationSeconds)s") {
                                            ForEach([60, 90, 120, 150, 180], id: \.self) { seconds in
                                                Button("\(seconds) seconds") { store.setWorkoutRestDuration(seconds) }
                                            }
                                        }
                                        .accessibilityLabel("Default rest duration, \(timer.baseDurationSeconds) seconds")
                                        .accessibilityIdentifier("rest-duration-menu")
                                    }
                                    .font(.caption.weight(.medium))
                                }
                                .padding(12)
                                .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        } header: {
                            Text("Rest")
                        }
                        Section("Workout notes") {
                            TextField("Notes for this workout", text: Binding(
                                get: { session.notes },
                                set: { store.updateWorkoutNotes($0) }
                            ), axis: .vertical)
                                .lineLimit(2...5)
                                .accessibilityIdentifier("active-workout-notes")
                        }
                        Section {
                            HStack {
                                Label("\(session.exercises.flatMap(\.sets).filter(\.completed).count) / \(session.exercises.flatMap(\.sets).count) sets", systemImage: "checkmark.circle.fill")
                                Spacer()
                                TimelineView(.periodic(from: .now, by: 1)) { context in
                                    Text(elapsed(session, now: context.date)).monospacedDigit().fontWeight(.semibold)
                                }
                            }
                            HStack {
                                Button { session.pausedAt == nil ? store.pauseWorkout() : store.resumeWorkout() } label: { Label(session.pausedAt == nil ? "Pause" : "Resume", systemImage: session.pausedAt == nil ? "pause.fill" : "play.fill") }
                                Spacer()
                                Button { showExercisePicker = true } label: { Label("Add exercise", systemImage: "plus") }
                            }
                        }
                        ForEach(session.exercises) { exercise in
                            let isExpanded = (expandedExerciseID ?? focusedExerciseID) == exercise.id
                            Section {
                                if isExpanded {
                                    setTableHeader(for: exercise)
                                    ForEach(exercise.sets) { set in
                                        WorkoutSetEditor(exercise: exercise, set: set)
                                    }
                                    if let suggestion = suggestedProgression(for: exercise) {
                                        Button {
                                            _ = store.acceptProgressionSuggestion(exerciseID: exercise.id, weightKg: suggestion)
                                        } label: {
                                            Label("Accept progression · \(suggestion.formatted(.number.precision(.fractionLength(0...1)))) kg", systemImage: "arrow.up.right")
                                                .font(.caption.weight(.semibold))
                                        }
                                        .accessibilityIdentifier("accept-progression-suggestion")
                                    }
                                    TextField("Exercise notes", text: Binding(
                                        get: { exercise.notes },
                                        set: { store.updateExerciseNotes($0, exerciseID: exercise.id) }
                                    ), axis: .vertical)
                                        .lineLimit(1...3)
                                        .accessibilityIdentifier("exercise-notes-\(exercise.id.uuidString)")
                                    Button { store.addSet(toExercise: exercise.id) } label: { Label("Add set", systemImage: "plus") }
                                } else {
                                    Button { expandedExerciseID = exercise.id } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(exercise.name).font(.subheadline.weight(.semibold))
                                                Text("\(exercise.sets.filter(\.completed).count) of \(exercise.sets.count) sets complete")
                                                    .font(.caption).foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.down").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            } header: {
                                Button {
                                    expandedExerciseID = isExpanded ? nil : exercise.id
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(exercise.name)
                                            Text("\(exercise.muscle) · \(exercise.equipment)")
                                                .font(.caption2).textCase(nil).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                            .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    if exercise.hasStarted != true && exercise.sets.allSatisfy({ !$0.completed && $0.weightKg == nil }) {
                                        Button("Replace exercise", systemImage: "arrow.2.squarepath") {
                                            replacingExerciseID = exercise.id
                                            showExercisePicker = true
                                        }
                                    }
                                }
                            }
                        }
                        Section {
                            Button("Discard workout", role: .destructive) { showDiscardConfirmation = true }
                                .frame(maxWidth: .infinity, alignment: .center)
                        } footer: {
                            Text("The full plan is saved, including unfinished sets. Only completed sets count toward workout statistics.")
                        }
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        ActiveWorkoutSummaryBar(session: session) {
                            let result = store.finishWorkout(confirmIncomplete: false)
                            if result == -1 {
                                completedSessionForSummary = store.state.training.completedSessions.first { $0.id == session.id }
                                showCompletionSummary = completedSessionForSummary != nil
                                if completedSessionForSummary == nil { dismiss() }
                            }
                            else if result > 0 { incompleteCount = result; showFinishConfirmation = true }
                        }
                    }
                    .navigationTitle(session.templateName)
                } else {
                    ContentUnavailableView("No active workout", systemImage: "dumbbell")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismiss() } } }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerScreen { exercise in
                    if let replacingExerciseID {
                        _ = store.replaceUnstartedActiveExercise(replacingExerciseID, with: exercise)
                        self.replacingExerciseID = nil
                    } else {
                        store.addExerciseToActive(exercise)
                    }
                }
                    .presentationDetents([.large]).presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showCompletionSummary, onDismiss: { dismiss() }) {
                if let completedSessionForSummary {
                    WorkoutCompletionSummaryScreen(session: completedSessionForSummary)
                        .presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
                }
            }
            .confirmationDialog("Save this workout with unfinished sets?", isPresented: $showFinishConfirmation, titleVisibility: .visible) {
                Button("Finish & Save", role: .destructive) {
                    _ = store.finishWorkout(confirmIncomplete: true)
                    completedSessionForSummary = store.state.training.completedSessions.last
                    showCompletionSummary = completedSessionForSummary != nil
                    if completedSessionForSummary == nil { dismiss() }
                }
                Button("Return to workout", role: .cancel) { }
            } message: { Text("\(incompleteCount) planned sets will remain saved as unfinished. Only completed sets count in statistics.") }
            .confirmationDialog("Discard this workout?", isPresented: $showDiscardConfirmation, titleVisibility: .visible) {
                Button("Discard workout", role: .destructive) { store.discardWorkout(); dismiss() }
                Button("Keep working", role: .cancel) { }
            }
            .onAppear { if session == nil { onStart?() } }
            .onChange(of: focusedExerciseID) { _, newID in
                if newID != nil { expandedExerciseID = newID }
            }
        }
    }

    @ViewBuilder
    private func setTableHeader(for exercise: WorkoutExercise) -> some View {
        HStack(spacing: 4) {
            Text("Set").frame(width: 20, alignment: .center)
            Text("Previous").frame(width: 55, alignment: .leading)
            switch exercise.trackingMode ?? .weightAndReps {
            case .weightAndReps:
                Text("Weight").frame(maxWidth: .infinity, alignment: .leading)
                Text("Reps").frame(maxWidth: .infinity, alignment: .leading)
            case .repsOnly:
                Text("Reps").frame(maxWidth: .infinity, alignment: .leading)
            case .duration:
                Text("Seconds").frame(maxWidth: .infinity, alignment: .leading)
            case .weightAndDistance:
                Text("Weight").frame(maxWidth: .infinity, alignment: .leading)
                Text("Distance").frame(maxWidth: .infinity, alignment: .leading)
            }
            Text("Done").frame(width: 28, alignment: .center)
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(.secondary)
        .accessibilityIdentifier("workout-set-table-header")
    }

    private func suggestedProgression(for exercise: WorkoutExercise) -> Double? {
        guard (exercise.trackingMode ?? .weightAndReps) == .weightAndReps,
              exercise.sets.allSatisfy({ !$0.completed && $0.weightKg == nil }),
              let prior = store.state.training.visibleCompletedSessions
                .filter({ $0.finishedAt != nil })
                .sorted(by: { $0.startedAt > $1.startedAt })
                .compactMap({ $0.exercises.first(where: { $0.exerciseID == exercise.exerciseID }) })
                .first,
              let priorBest = prior.sets.filter(\.completed).compactMap(\.weightKg).max(), priorBest > 0 else { return nil }
        return priorBest + 2.5
    }

    private func elapsed(_ session: WorkoutSession, now: Date) -> String {
        let end = session.pausedAt ?? now
        let seconds = max(0, Int(end.timeIntervalSince(session.startedAt) - session.pausedSeconds))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func restTime(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

private struct WorkoutCompletionSummaryScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    let session: WorkoutSession

    private var sets: [WorkoutSet] { session.exercises.flatMap(\.sets) }
    private var completedSets: [WorkoutSet] { sets.filter(\.completed) }
    private var volume: Double {
        completedSets.reduce(0) { $0 + ($1.weightKg ?? 0) * Double($1.reps) }
    }
    private var durationMinutes: Int {
        guard let finishedAt = session.finishedAt else { return 0 }
        return max(0, Int(finishedAt.timeIntervalSince(session.startedAt) - session.pausedSeconds) / 60)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Duration", value: "\(durationMinutes) min")
                    LabeledContent("Sets completed", value: "\(completedSets.count) of \(sets.count)")
                    LabeledContent("Exercises", value: "\(session.exercises.count)")
                    if volume > 0 { LabeledContent("Lifting volume", value: "\(Int(volume)) kg") }
                } header: { Text(session.templateName) }
                let records = store.state.training.personalRecordEvents.filter { $0.sessionID == session.id }
                if !records.isEmpty {
                    Section("Personal records") {
                        ForEach(records) { record in
                            LabeledContent(record.exerciseName, value: "e1RM \(record.estimatedOneRepMaxKg.formatted(.number.precision(.fractionLength(1)))) kg")
                        }
                    }
                }
                if !session.notes.isEmpty { Section("Workout notes") { Text(session.notes) } }
            }
            .navigationTitle("Workout saved")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}

private struct ActiveWorkoutSummaryBar: View {
    let session: WorkoutSession
    let finish: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let sets = session.exercises.flatMap(\.sets)
            let completed = sets.filter(\.completed)
            let wallElapsed = max(0, context.date.timeIntervalSince(session.startedAt))
            let pausedNow = session.pausedAt.map { max(0, context.date.timeIntervalSince($0)) } ?? 0
            let activeSeconds = max(0, Int(wallElapsed - session.pausedSeconds - pausedNow))
            let volume = completed.reduce(0.0) { total, set in
                total + ((set.weightKg ?? 0) * Double(set.reps))
            }
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Active \(String(format: "%d:%02d", activeSeconds / 60, activeSeconds % 60))")
                        .font(.caption.weight(.semibold).monospacedDigit())
                    Text("\(completed.count)/\(sets.count) sets · \(Int(volume)) kg")
                        .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer(minLength: 4)
                Button(action: finish) {
                    Label("Finish & Save", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("finish-workout")
            }
            .padding(.horizontal, 16)
            .padding(.top, 9)
            .padding(.bottom, 8)
            .background(.regularMaterial)
            .overlay(alignment: .top) { Rectangle().fill(.quaternary).frame(height: 0.5) }
        }
    }
}

private struct WorkoutSetEditor: View {
    @EnvironmentObject private var store: LogbookStore
    let exercise: WorkoutExercise
    let set: WorkoutSet

    private var setIndex: Int { exercise.sets.firstIndex(of: set) ?? 0 }

    private var previous: String {
        let session = store.state.training.visibleCompletedSessions
            .sorted { $0.startedAt > $1.startedAt }
            .first { candidate in candidate.exercises.contains { $0.exerciseID == exercise.exerciseID } }
        guard let previousExercise = session?.exercises.first(where: { $0.exerciseID == exercise.exerciseID }),
              previousExercise.sets.indices.contains(setIndex) else { return "—" }
        let previousSet = previousExercise.sets[setIndex]
        switch exercise.trackingMode ?? .weightAndReps {
        case .weightAndReps:
            guard let weight = previousSet.weightKg else { return "—" }
            return "\(weight.formatted(.number.precision(.fractionLength(0...1)))) × \(previousSet.reps)"
        case .repsOnly:
            return "\(previousSet.reps) reps"
        case .duration:
            guard let seconds = previousSet.durationSeconds else { return "—" }
            return "\(seconds)s"
        case .weightAndDistance:
            guard let weight = previousSet.weightKg, let distance = previousSet.distanceMeters else { return "—" }
            return "\(Int(weight)) kg · \(Int(distance)) m"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Text("\(setIndex + 1)")
                .font(.caption.monospacedDigit().weight(.semibold))
                .frame(width: 20)
            Text(previous)
                .font(.system(size: 9, weight: .regular).monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(width: 55, alignment: .leading)
                .accessibilityLabel("Previous: \(previous)")
            trackingInputs
            Button { _ = store.toggleSet(exerciseID: exercise.id, setID: set.id) } label: {
                Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24)).foregroundStyle(set.completed ? Color.green : Color.secondary)
            }
            .buttonStyle(.plain)
            .frame(width: 28)
            .accessibilityLabel(set.completed ? "Mark set not done" : "Mark set complete")
        }
    }

    @ViewBuilder
    private var trackingInputs: some View {
        switch exercise.trackingMode ?? .weightAndReps {
        case .weightAndReps:
            weightField
            repsField
        case .repsOnly:
            repsField
        case .duration:
            TextField("sec", value: duration, format: .number)
                .keyboardType(.numberPad).textFieldStyle(.roundedBorder).frame(maxWidth: .infinity)
                .accessibilityLabel("Duration in seconds")
        case .weightAndDistance:
            weightField
            TextField("m", value: distance, format: .number.precision(.fractionLength(0...1)))
                .keyboardType(.decimalPad).textFieldStyle(.roundedBorder).frame(maxWidth: .infinity)
                .accessibilityLabel("Distance in meters")
        }
    }

    private var weightField: some View {
        TextField("kg", value: weight, format: .number.precision(.fractionLength(0...2)))
            .keyboardType(.decimalPad).textFieldStyle(.roundedBorder).frame(maxWidth: .infinity)
            .accessibilityLabel("Weight in kilograms")
    }

    private var repsField: some View {
        TextField("Reps", value: reps, format: .number)
            .keyboardType(.numberPad).textFieldStyle(.roundedBorder).frame(maxWidth: .infinity)
            .accessibilityLabel("Repetitions")
    }

    private var weight: Binding<Double> {
        Binding(get: { set.weightKg ?? 0 }, set: { store.updateSet(exerciseID: exercise.id, setID: set.id, weightKg: $0 > 0 ? $0 : nil, reps: set.reps) })
    }

    private var reps: Binding<Int> {
        Binding(get: { set.reps }, set: { store.updateSet(exerciseID: exercise.id, setID: set.id, weightKg: set.weightKg, reps: $0) })
    }

    private var duration: Binding<Int> {
        Binding(get: { set.durationSeconds ?? 0 }, set: { store.updateSetDuration(exerciseID: exercise.id, setID: set.id, seconds: $0 > 0 ? $0 : nil) })
    }

    private var distance: Binding<Double> {
        Binding(get: { set.distanceMeters ?? 0 }, set: { store.updateSetDistance(exerciseID: exercise.id, setID: set.id, weightKg: set.weightKg, distanceMeters: $0 > 0 ? $0 : nil) })
    }
}

struct FoodScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @State private var showFoodPicker = false
    @State private var showTargets = false
    @State private var selectedMealID: UUID?

    private var today: String { LocalDay.string() }
    private var logs: [FoodLog] { store.state.nutrition.logs.filter { $0.date == today } }
    private var totals: NutritionTargets { store.state.nutritionTotals(on: today) }
    private var waterTotal: Int { store.state.nutrition.water.filter { $0.date == today }.reduce(0) { $0 + $1.milliliters } }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 3) { Text("Calories").font(.caption).foregroundStyle(.secondary); Text("\(Int(totals.calories ?? 0))").font(.system(size: 31, weight: .bold, design: .rounded)) }
                        Spacer()
                        if let target = store.state.nutrition.targets.calories { Text("of \(Int(target)) kcal").font(.caption).foregroundStyle(.secondary) }
                    }
                    ProgressView(value: min(1, (totals.calories ?? 0) / max(1, store.state.nutrition.targets.calories ?? 1)))
                    HStack(spacing: 7) {
                        MacroTile(name: "Protein", value: totals.protein ?? 0, goal: store.state.nutrition.targets.protein, color: .teal)
                        MacroTile(name: "Carbs", value: totals.carbohydrates ?? 0, goal: store.state.nutrition.targets.carbohydrates, color: .blue)
                        MacroTile(name: "Fat", value: totals.fat ?? 0, goal: store.state.nutrition.targets.fat, color: .orange)
                    }
                }
                .padding(.vertical, 5)
            } header: {
                HStack { Text("Nutrition today · \(today)"); Spacer(); Button("Targets") { showTargets = true } }
            }

            Section {
                ForEach(store.state.nutrition.meals) { meal in
                    let mealLogs = logs.filter { $0.mealID == meal.id }
                    DisclosureGroup {
                        if mealLogs.isEmpty { Text("Nothing logged yet.").font(.caption).foregroundStyle(.secondary) }
                        ForEach(mealLogs) { log in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) { Text(log.foodName); Text("\(format(log.quantity)) \(log.unit) · \(Int(log.calories)) kcal · \(Int(log.protein)) g protein").font(.caption).foregroundStyle(.secondary) }
                                Spacer()
                            }
                            .swipeActions { Button("Delete", role: .destructive) { store.deleteFoodLog(log.id) } }
                        }
                        Button { selectedMealID = meal.id; showFoodPicker = true } label: { Label("Add food to \(meal.name)", systemImage: "plus") }
                    } label: {
                        HStack { Text(meal.name).font(.headline); Spacer(); Text("\(mealLogs.count) items").font(.caption).foregroundStyle(.secondary) }
                    }
                    .tint(store.state.home.theme.palette.accentColor)
                }
                Button { selectedMealID = store.state.nutrition.meals.first?.id; showFoodPicker = true } label: { Label("Add food", systemImage: "plus.circle.fill") }
                Button { store.addMeal(name: "Meal \(store.state.nutrition.meals.count + 1)") } label: { Label("Add meal", systemImage: "rectangle.stack.badge.plus") }
            } header: { Text("Meals") }

            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 3) { Text("Water").font(.headline); Text("\(waterTotal) mL logged").font(.caption).foregroundStyle(.secondary) }
                    Spacer()
                    ForEach([250, 500, 750], id: \.self) { amount in
                        Button("+\(amount)") { store.addWater(amount) }.buttonStyle(.bordered).controlSize(.small)
                    }
                }
            } header: { Text("Hydration") }

            if !logs.isEmpty {
                Section("Today’s total") {
                    LabeledContent("Calories", value: "\(Int(totals.calories ?? 0)) kcal")
                    LabeledContent("Protein", value: "\(Int(totals.protein ?? 0)) g")
                    LabeledContent("Carbohydrates", value: "\(Int(totals.carbohydrates ?? 0)) g")
                    LabeledContent("Fat", value: "\(Int(totals.fat ?? 0)) g")
                }
            }
        }
        .navigationTitle("Food")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showTargets = true } label: { Image(systemName: "slider.horizontal.3") }.accessibilityLabel("Nutrition targets") } }
        .sheet(isPresented: $showFoodPicker) {
            FoodPickerScreen(mealID: selectedMealID ?? store.state.nutrition.meals[0].id)
                .presentationDetents([.large]).presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTargets) { NutritionTargetsScreen().presentationDetents([.medium, .large]).presentationDragIndicator(.visible) }
    }

    private func format(_ value: Double) -> String { value.formatted(.number.precision(.fractionLength(0...2))) }
}

private struct MacroTile: View {
    let name: String
    let value: Double
    let goal: Double?
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(name).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            Text("\(Int(value)) g").font(.system(size: 15, weight: .bold, design: .rounded))
            if let goal { ProgressView(value: min(1, value / max(1, goal))).tint(color) }
            else { Text("No goal").font(.system(size: 9)).foregroundStyle(.tertiary) }
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(9)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 13))
    }
}

struct FoodPickerScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    let mealID: UUID
    @State private var search = ""
    @State private var selectedFood: FoodDefinition?
    @State private var showNewFood = false

    private var foods: [FoodDefinition] {
        store.state.nutrition.foods.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }
    }
    private var meal: MealSlot { store.state.nutrition.meals.first(where: { $0.id == mealID }) ?? store.state.nutrition.meals[0] }

    var body: some View {
        NavigationStack {
            List {
                Section { Button { showNewFood = true } label: { Label("Create a food", systemImage: "plus.circle.fill") } }
                Section("Foods · \(foods.count)") {
                    ForEach(foods) { food in
                        Button { selectedFood = food } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(food.name).font(.headline)
                                Text("\(Int(food.calories)) kcal · \(Int(food.protein)) g protein per \(food.basisAmount.formatted()) \(food.basisUnit)")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("Add to \(meal.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .searchable(text: $search, prompt: "Food name")
            .sheet(item: $selectedFood) { food in
                FoodQuantityConfirmationScreen(food: food, meal: meal)
                    .presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showNewFood) {
                NewFoodScreen().presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
            }
        }
    }
}

struct FoodQuantityConfirmationScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    let food: FoodDefinition
    let meal: MealSlot
    @State private var quantity: Double
    @State private var confirmed = false

    init(food: FoodDefinition, meal: MealSlot) {
        self.food = food
        self.meal = meal
        _quantity = State(initialValue: food.basisAmount)
    }

    private var multiplier: Double { quantity / max(food.basisAmount, 0.0001) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Confirm amount · \(meal.name)") {
                    Text(food.name).font(.headline)
                    HStack {
                        TextField("Amount", value: $quantity, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                        Text(food.basisUnit).foregroundStyle(.secondary)
                    }
                }
                Section("Nutrition preview") {
                    LabeledContent("Calories", value: "\(Int(food.calories * multiplier)) kcal")
                    LabeledContent("Protein", value: "\(Int(food.protein * multiplier)) g")
                    LabeledContent("Carbohydrates", value: "\(Int(food.carbohydrates * multiplier)) g")
                    LabeledContent("Fat", value: "\(Int(food.fat * multiplier)) g")
                }
                Section {
                    Text("Check the quantity and food label before logging. The values above are saved as an immutable snapshot for this entry.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Review food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log food") {
                        confirmed = true
                        if store.logFood(food, meal: meal, quantity: quantity, unit: food.basisUnit, confirmed: confirmed) { dismiss() }
                    }
                    .disabled(quantity <= 0)
                }
            }
        }
    }
}

struct NewFoodScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var quantity = 100.0
    @State private var unit = "g"
    @State private var calories = 0.0
    @State private var protein = 0.0
    @State private var carbs = 0.0
    @State private var fat = 0.0

    var body: some View {
        NavigationStack {
            Form {
                Section("Food and serving") {
                    TextField("Name", text: $name)
                    HStack { TextField("Amount", value: $quantity, format: .number).keyboardType(.decimalPad); TextField("Unit", text: $unit).frame(width: 80) }
                }
                Section("Nutrition per serving above") {
                    numeric("Calories", value: $calories, suffix: "kcal")
                    numeric("Protein", value: $protein, suffix: "g")
                    numeric("Carbohydrates", value: $carbs, suffix: "g")
                    numeric("Fat", value: $fat, suffix: "g")
                }
                Text("For foods from a package, enter the label values for this exact serving. No unit conversion or nutrition estimate is assumed.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .navigationTitle("New food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let item = FoodDefinition(id: "custom-\(UUID().uuidString)", name: name.trimmingCharacters(in: .whitespacesAndNewlines), basisAmount: quantity, basisUnit: unit, calories: calories, protein: protein, carbohydrates: carbs, fat: fat)
                        store.addFoodDefinition(item)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || quantity <= 0)
                }
            }
        }
    }

    private func numeric(_ title: String, value: Binding<Double>, suffix: String) -> some View {
        HStack { TextField(title, value: value, format: .number).keyboardType(.decimalPad); Text(suffix).foregroundStyle(.secondary) }
    }
}

struct NutritionTargetsScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbohydrates = ""
    @State private var fat = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily targets") {
                    targetField("Calories", text: $calories, unit: "kcal")
                    targetField("Protein", text: $protein, unit: "g")
                    targetField("Carbohydrates", text: $carbohydrates, unit: "g")
                    targetField("Fat", text: $fat, unit: "g")
                }
                Section { Text("New target values apply from today onward. Past food logs remain unchanged.").font(.footnote).foregroundStyle(.secondary) }
            }
            .navigationTitle("Nutrition targets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.setNutritionTargets(calories: Double(calories), protein: Double(protein), carbohydrates: Double(carbohydrates), fat: Double(fat))
                        dismiss()
                    }
                }
            }
            .onAppear {
                let targets = store.state.nutrition.targets
                calories = targets.calories.map { String(Int($0)) } ?? ""
                protein = targets.protein.map { String(Int($0)) } ?? ""
                carbohydrates = targets.carbohydrates.map { String(Int($0)) } ?? ""
                fat = targets.fat.map { String(Int($0)) } ?? ""
            }
        }
    }

    private func targetField(_ label: String, text: Binding<String>, unit: String) -> some View {
        HStack { TextField(label, text: text).keyboardType(.decimalPad); Text(unit).foregroundStyle(.secondary) }
    }
}
