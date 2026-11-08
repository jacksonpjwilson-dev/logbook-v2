import SwiftUI
import UIKit

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
                    .accessibilityIdentifier("training-template-\(template.id.uuidString)")
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
    @State private var expandedExerciseIDs = Set<UUID>()
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
                            .accessibilityIdentifier("workout-template-start")
                    }
                    Section {
                        if template.exercises.isEmpty {
                            Text("Add exercises to make this plan ready to start.").foregroundStyle(.secondary)
                        }
                        ForEach(template.exercises) { exercise in
                            VStack(alignment: .leading, spacing: 0) {
                                Button {
                                    if expandedExerciseIDs.contains(exercise.id) {
                                        expandedExerciseIDs.remove(exercise.id)
                                    } else {
                                        expandedExerciseIDs.insert(exercise.id)
                                    }
                                } label: {
                                    HStack(alignment: .center, spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(exercise.name).font(.headline)
                                            Text("\(exercise.muscle) · \(exercise.sets.count) sets · \(exercise.trackingMode?.title ?? "Weight + reps") · \(exercise.equipment)")
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer(minLength: 8)
                                        Image(systemName: expandedExerciseIDs.contains(exercise.id) ? "chevron.up" : "chevron.down")
                                            .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                                    }
                                    .contentShape(Rectangle())
                                    .padding(.vertical, 5)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("planned-exercise-\(exercise.id.uuidString)")
                                .accessibilityValue(expandedExerciseIDs.contains(exercise.id) ? "Expanded" : "Collapsed")

                                if expandedExerciseIDs.contains(exercise.id) {
                                    Picker("Tracking mode", selection: Binding(
                                        get: { exercise.trackingMode ?? .weightAndReps },
                                        set: { store.configurePlannedExercise(templateID: templateID, exerciseID: exercise.id, setCount: exercise.sets.count, reps: exercise.sets.first?.reps ?? 8, restSeconds: exercise.restSeconds, trackingMode: $0) }
                                    )) {
                                        ForEach(ExerciseTrackingMode.allCases) { mode in Text(mode.title).tag(mode) }
                                    }
                                    .accessibilityIdentifier("planned-exercise-tracking-\(exercise.id.uuidString)")
                                    Stepper("Sets · \(exercise.sets.count)", value: Binding(
                                        get: { exercise.sets.count },
                                        set: { store.configurePlannedExercise(templateID: templateID, exerciseID: exercise.id, setCount: $0, reps: exercise.sets.first?.reps ?? 8, restSeconds: exercise.restSeconds) }
                                    ), in: 1...30)
                                    .accessibilityIdentifier("planned-exercise-sets-\(exercise.id.uuidString)")
                                    Stepper("Reps · \(exercise.sets.first?.reps ?? 8)", value: Binding(
                                        get: { exercise.sets.first?.reps ?? 8 },
                                        set: { store.configurePlannedExercise(templateID: templateID, exerciseID: exercise.id, setCount: exercise.sets.count, reps: $0, restSeconds: exercise.restSeconds) }
                                    ), in: 1...100)
                                    .accessibilityIdentifier("planned-exercise-reps-\(exercise.id.uuidString)")
                                    Stepper("Rest · \(exercise.restSeconds.map { "\($0)s" } ?? "90s default")", value: Binding(
                                        get: { exercise.restSeconds ?? 90 },
                                        set: { store.configurePlannedExercise(templateID: templateID, exerciseID: exercise.id, setCount: exercise.sets.count, reps: exercise.sets.first?.reps ?? 8, restSeconds: $0) }
                                    ), in: 15...600, step: 15)
                                    .accessibilityIdentifier("planned-exercise-rest-\(exercise.id.uuidString)")
                                    if exercise.restSeconds != nil {
                                        Button("Use workout default rest") {
                                            store.configurePlannedExercise(templateID: templateID, exerciseID: exercise.id, setCount: exercise.sets.count, reps: exercise.sets.first?.reps ?? 8, restSeconds: nil)
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
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
                            .accessibilityIdentifier("workout-template-add-exercise")
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
            ExercisePickerScreen { exercise in addExercise(exercise) }
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

    private func addExercise(_ exercise: ExerciseDefinition) {
        store.appendExercise(exercise, toTemplate: templateID)
        if let addedID = store.state.training.templates
            .first(where: { $0.id == templateID })?.exercises.last?.id {
            expandedExerciseIDs.insert(addedID)
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
                        .accessibilityIdentifier("exercise-picker-create-custom")
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
                            .accessibilityIdentifier("exercise-picker-result-\(exercise.id)")
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
                TextField("Exercise name", text: $name).accessibilityIdentifier("custom-exercise-name")
                TextField("Primary muscle", text: $muscle).accessibilityIdentifier("custom-exercise-muscle")
                TextField("Equipment", text: $equipment).accessibilityIdentifier("custom-exercise-equipment")
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
                        .accessibilityIdentifier("custom-exercise-save")
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
                    VStack(spacing: 0) {
                        restTimerCard(for: session)
                        List {
                            ForEach(session.exercises) { exercise in
                            let isExpanded = (expandedExerciseID ?? focusedExerciseID) == exercise.id
                            Section {
                                if isExpanded {
                                    setTableHeader(for: exercise)
                                    ForEach(exercise.sets) { set in
                                        WorkoutSetEditor(exercise: exercise, set: set)
                                    }
                                    if let suggestion = suggestedProgression(for: exercise) {
                                        HStack {
                                            Button {
                                                _ = store.acceptProgressionSuggestion(exerciseID: exercise.id, weightKg: suggestion)
                                            } label: {
                                                Label("Accept · \(suggestion.formatted(.number.precision(.fractionLength(0...1)))) kg", systemImage: "arrow.up.right")
                                                    .font(.caption.weight(.semibold))
                                            }
                                            .accessibilityIdentifier("accept-progression-suggestion")
                                            Spacer()
                                            Button("Not now") { store.declineProgressionSuggestion(exerciseID: exercise.id) }
                                                .font(.caption)
                                                .accessibilityIdentifier("decline-progression-suggestion")
                                        }
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
                                .accessibilityIdentifier("active-exercise-header-\(exercise.id.uuidString)")
                                .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
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
                        Section("Workout notes") {
                            TextField("Notes for this workout", text: Binding(
                                get: { session.notes },
                                set: { store.updateWorkoutNotes($0) }
                            ), axis: .vertical)
                                .lineLimit(2...5)
                                .accessibilityIdentifier("active-workout-notes")
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
                    }
                    .navigationTitle(session.templateName)
                } else {
                    ContentUnavailableView("No active workout", systemImage: "dumbbell")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismiss() } }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .accessibilityIdentifier("keyboard-done")
                }
            }
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
                .accessibilityIdentifier("confirm-finish-workout")
                Button("Return to workout", role: .cancel) { }
            } message: { Text("\(incompleteCount) planned sets will remain saved as unfinished. Only completed sets count in statistics.") }
            .confirmationDialog("Discard this workout?", isPresented: $showDiscardConfirmation, titleVisibility: .visible) {
                Button("Discard workout", role: .destructive) { store.discardWorkout(); dismiss() }
                Button("Keep working", role: .cancel) { }
            }
            .onAppear {
                if session == nil { onStart?() }
                expandCurrentExerciseIfNeeded()
            }
            .onChange(of: session?.id) { _, _ in
                expandCurrentExerciseIfNeeded()
            }
            .onChange(of: focusedExerciseID) { _, newID in
                if newID != nil { expandedExerciseID = newID }
            }
        }
    }

    private func expandCurrentExerciseIfNeeded() {
        guard expandedExerciseID == nil, let session else { return }
        expandedExerciseID = focusedExerciseID ?? session.exercises.first?.id
    }

    private func restTimerCard(for session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Rest")
                .font(.caption.weight(.medium))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .padding(.leading, 12)

            TimelineView(.periodic(from: .now, by: 1)) { context in
                let timer = store.state.training.activeSession?.restTimer ?? session.restTimer ?? WorkoutRestTimer()
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
                        Button {
                            if timer.isPaused { store.resumeRestTimer() }
                            else { store.pauseRestTimer() }
                        } label: {
                            Label(timer.isPaused ? "Resume" : "Pause",
                                  systemImage: timer.isPaused ? "play.fill" : "pause.fill")
                        }
                        .disabled(!timer.isPaused && remaining == 0)
                        .accessibilityIdentifier("rest-toggle")
                        .accessibilityLabel(timer.isPaused ? "Resume rest timer" : "Pause rest timer")
                        .accessibilityValue(timer.isPaused ? "Paused" : "Running")
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
        }
        .padding(.horizontal, 12)
        .padding(.top, 7)
        .padding(.bottom, 5)
        .frame(maxWidth: .infinity)
        .background(.background)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("active-workout-rest-card")
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
              session?.declinedProgressionExerciseIDs?.contains(exercise.id) != true,
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
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.accessibilityIdentifier("workout-summary-done") } }
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
            .accessibilityIdentifier("workout-set-weight-\(set.id.uuidString)")
    }

    private var repsField: some View {
        TextField("Reps", value: reps, format: .number)
            .keyboardType(.numberPad).textFieldStyle(.roundedBorder).frame(maxWidth: .infinity)
            .accessibilityLabel("Repetitions")
            .accessibilityIdentifier("workout-set-reps-\(set.id.uuidString)")
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
