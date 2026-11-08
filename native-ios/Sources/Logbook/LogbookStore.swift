import Foundation
import Combine
import WidgetKit

@MainActor
final class LogbookStore: ObservableObject {
    @Published private(set) var state: LogbookState
    @Published private(set) var persistenceError: String?
    @Published private(set) var lastSavedAt: Date?
    @Published private(set) var focusedCheckInSection: CheckInSection?
    @Published private(set) var activeWorkoutPresentationRequest: UUID?

    private let repository: LogbookRepository
    private(set) var canEdit = true

    private static func bundledJSON(named name: String) -> URL? {
        var bundles = [Bundle.main, Bundle(for: LogbookStore.self)]
        bundles.append(contentsOf: Bundle.allBundles)
        bundles.append(contentsOf: Bundle.allFrameworks)
        var visited = Set<String>()
        for bundle in bundles where visited.insert(bundle.bundleURL.standardizedFileURL.path).inserted {
            if let url = bundle.url(forResource: name, withExtension: "json") { return url }
            if let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "Resources") { return url }
        }
        return nil
    }

    init(repository: LogbookRepository = .shared) {
        self.repository = repository
        do {
            var loaded = try repository.load()
            if loaded.training.exercises.isEmpty,
               let url = Self.bundledJSON(named: "exercise-catalog"),
               let data = try? Data(contentsOf: url),
               let catalogue = try? JSONDecoder().decode([ExerciseDefinition].self, from: data) {
                loaded.training.exercises = catalogue
            }
            if loaded.nutrition.foods.isEmpty,
               let url = Self.bundledJSON(named: "food-catalog"),
               let data = try? Data(contentsOf: url),
               let foods = try? JSONDecoder().decode([FoodDefinition].self, from: data) {
                loaded.nutrition.foods = foods
            }
            let migratedDailyLayout = loaded.home.migrateUntouchedDailyLayout()
            let migratedTrainingPrograms = Self.migrateLegacyPrograms(&loaded.training)
            let purgedWorkoutRecords = Self.purgeExpiredWorkoutRecords(&loaded.training, asOf: .now)
            let purgedFoodRecords = Self.purgeExpiredFoodRecords(&loaded.nutrition, asOf: .now)
            state = loaded
            lastSavedAt = FileManager.default.fileExists(atPath: repository.url.path) ? Date() : nil
            if migratedDailyLayout || migratedTrainingPrograms || purgedWorkoutRecords || purgedFoodRecords {
                do {
                    try repository.save(loaded)
                    lastSavedAt = .now
                } catch {
                    // Preserve the loaded data and disable edits until the layout migration can be saved.
                    persistenceError = "The Daily Home Screen update could not be saved. Your existing data is still loaded. \(error.localizedDescription)"
                    canEdit = false
                }
            }
        } catch {
            // Do not turn an unreadable or newer data file into a blank database.
            state = .empty
            persistenceError = error.localizedDescription
            canEdit = false
            lastSavedAt = nil
        }
    }

    func setTheme(_ theme: LogbookTheme) {
        transact { $0.home.theme = theme }
    }

    func focusCheckIn(_ section: CheckInSection) {
        focusedCheckInSection = section
    }

    func requestActiveWorkoutPresentation() {
        activeWorkoutPresentationRequest = UUID()
    }

    func consumeActiveWorkoutPresentationRequest() {
        activeWorkoutPresentationRequest = nil
    }

    func clearCheckInFocus() {
        focusedCheckInSection = nil
    }

    #if DEBUG
    /// Synthetic, isolated UI-test data. It is only installed in the temporary
    /// repository created for --ui-testing and never touches the App Group store.
    func installDefaultDailyQAFixture() {
        guard ProcessInfo.processInfo.arguments.contains("--ui-testing") else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let exerciseData: [(String, String, String)] = [
            ("qa-bench", "Bench Press", "Chest"),
            ("qa-row", "Seated Row", "Back"),
            ("qa-press", "Shoulder Press", "Shoulders"),
            ("qa-curl", "Dumbbell Curl", "Arms")
        ]
        let exercises = exerciseData.map { id, name, muscle in
            PlannedExercise(exerciseID: id, name: name, muscle: muscle, equipment: "Dumbbell")
        }
        let templateID = UUID(uuidString: "F0D8D0A0-33A2-4E7F-8B0A-318BE1F79F51")!
        let template = WorkoutTemplate(id: templateID, name: "Upper Body", exercises: exercises)
        let fullSplitNames = ["Upper Body", "Lower Body", "Push", "Pull", "Legs", "Upper Accessory", "Lower Accessory", "Full Body"]
        let fullSplitFixture = ProcessInfo.processInfo.arguments.contains("--qa-training-split-eight")
        let programRotationFixture = ProcessInfo.processInfo.arguments.contains("--qa-training-programs")
        let qaTemplates = fullSplitFixture
            ? [template] + fullSplitNames.dropFirst().map { WorkoutTemplate(name: $0, exercises: exercises) }
            : [template]
        let rotationTemplates: [WorkoutTemplate] = programRotationFixture
            ? [
                template,
                WorkoutTemplate(id: UUID(uuidString: "A2D8A513-9023-42AE-94A5-222E210F3C12")!, name: "Program A Workout 2", exercises: exercises),
                WorkoutTemplate(id: UUID(uuidString: "B1D8A513-9023-42AE-94A5-222E210F3C12")!, name: "Program B Workout 1", exercises: exercises),
                WorkoutTemplate(id: UUID(uuidString: "B2D8A513-9023-42AE-94A5-222E210F3C12")!, name: "Program B Workout 2", exercises: exercises)
            ]
            : qaTemplates
        let supplementID = UUID(uuidString: "D1B2B4F8-9B2A-493C-B60E-41E3587799A8")!
        let supplement = Supplement(id: supplementID, name: "Creatine", schedule: "daily")
        var sleepLogs: [SleepLog] = []
        var weightLogs: [WeightLog] = []
        var doses: [SupplementDose] = []
        for offset in 0..<5 {
            guard let wake = calendar.date(byAdding: .day, value: -offset, to: today),
                  let bedtimeDay = calendar.date(byAdding: .day, value: -1, to: wake),
                  let bedtime = calendar.date(bySettingHour: 22, minute: 30, second: 0, of: bedtimeDay),
                  let wakeTime = calendar.date(bySettingHour: 6, minute: 30, second: 0, of: wake) else { continue }
            let key = LocalDay.string(wake)
            sleepLogs.append(SleepLog(wakeDate: key, bedtime: bedtime, wakeTime: wakeTime))
            weightLogs.append(WeightLog(date: key, kilograms: 78.4 - Double(offset) * 0.1))
            doses.append(SupplementDose(supplementID: supplementID, supplementName: supplement.name, date: key, taken: true, explicitlyMarked: true))
        }
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return }
        let finished = calendar.date(bySettingHour: 16, minute: 20, second: 0, of: yesterday) ?? yesterday
        var fixture = state
        fixture.training.templates = rotationTemplates
        fixture.training.rotationIndex = 0
        if programRotationFixture {
            let firstProgram = WorkoutProgram(name: "Program A", templateIDs: Array(rotationTemplates.prefix(2)).map(\.id), rotationIndex: 0)
            let secondProgram = WorkoutProgram(name: "Program B", templateIDs: Array(rotationTemplates.suffix(2)).map(\.id), rotationIndex: 1)
            fixture.training.programs = [firstProgram, secondProgram]
            fixture.training.activeProgramID = firstProgram.id
        } else {
            let qaProgram = WorkoutProgram(name: "QA Program", templateIDs: qaTemplates.map(\.id), rotationIndex: 0)
            fixture.training.programs = [qaProgram]
            fixture.training.activeProgramID = qaProgram.id
        }
        let progressionSets = [WorkoutSet(weightKg: 60, reps: 8, completed: true)]
        let progressionExercise = WorkoutExercise(
            exerciseID: "qa-bench",
            name: "Bench Press",
            muscle: "Chest",
            equipment: "Dumbbell",
            sets: progressionSets
        )
        let progressionHistoryEnabled = ProcessInfo.processInfo.arguments.contains("--qa-progression-history")
        fixture.training.completedSessions = programRotationFixture ? [] : [WorkoutSession(
                templateID: templateID,
                templateName: template.name,
                templateVersion: template.version,
                localDate: LocalDay.string(yesterday),
                startedAt: finished.addingTimeInterval(-2_700),
                finishedAt: finished,
                exercises: progressionHistoryEnabled ? [progressionExercise] : []
            )]
        fixture.checkins.sleep = sleepLogs
        fixture.checkins.weights = weightLogs
        fixture.checkins.supplements = [supplement]
        fixture.checkins.doses = doses
        fixture.lastModified = .now
        do {
            try repository.save(fixture)
            state = fixture
            lastSavedAt = .now
        } catch {
            persistenceError = "Could not prepare isolated Daily Home test data. \(error.localizedDescription)"
        }
    }
    #endif

    func setNutritionTargets(calories: Double?, protein: Double?, carbohydrates: Double?, fat: Double?, effectiveDate: String = LocalDay.string()) {
        let values = [calories, protein, carbohydrates, fat]
        guard values.allSatisfy({ $0 == nil || ($0!.isFinite && $0! >= 0) }) else { return }
        let next = NutritionTargets(calories: calories, protein: protein, carbohydrates: carbohydrates, fat: fat)
        transact { state in
            if state.nutrition.targetHistory == nil {
                // Preserve the old global goal for earlier dates before recording
                // the first dated override.
                state.nutrition.targetHistory = [NutritionTargetSnapshot(effectiveDate: "0001-01-01", targets: state.nutrition.targets)]
            }
            state.nutrition.targetHistory?.removeAll { $0.effectiveDate == effectiveDate }
            state.nutrition.targetHistory?.append(NutritionTargetSnapshot(effectiveDate: effectiveDate, targets: next))
            state.nutrition.targetHistory?.sort { $0.effectiveDate < $1.effectiveDate }
            state.nutrition.targets = next
            state.home.dailyCalorieGoal = calories
            state.home.dailyProteinGoal = protein
        }
    }

    func setNotificationsEnabled(_ enabled: Bool) {
        transact { $0.notificationsEnabled = enabled }
        ReminderService.scheduleNutrition(at: enabled ? state.nutritionReminderTime : nil)
        ReminderService.scheduleTraining(at: enabled ? state.trainingReminderTime : nil)
    }

    func addTemplate(name: String) -> UUID? {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }
        let template = WorkoutTemplate(name: clean)
        transact { state in
            Self.migrateLegacyPrograms(&state.training)
            state.training.templates.append(template)
            guard let programIndex = state.training.programs?.firstIndex(where: { $0.id == state.training.activeProgramID }) else { return }
            state.training.programs?[programIndex].templateIDs.append(template.id)
        }
        return template.id
    }

    @discardableResult
    func addProgram(name: String, activate: Bool = true) -> UUID? {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }
        let program = WorkoutProgram(name: clean)
        transact { state in
            Self.migrateLegacyPrograms(&state.training)
            state.training.programs?.append(program)
            if activate {
                state.training.activeProgramID = program.id
                state.training.rotationIndex = 0
            }
        }
        return state.training.programs?.contains(where: { $0.id == program.id }) == true ? program.id : nil
    }

    func setActiveProgram(_ id: UUID) {
        transact { state in
            Self.migrateLegacyPrograms(&state.training)
            guard state.training.programs?.contains(where: { $0.id == id }) == true else { return }
            state.training.activeProgramID = id
            state.training.rotationIndex = state.training.programs?.first(where: { $0.id == id })?.rotationIndex ?? 0
        }
    }

    func renameProgram(_ id: UUID, name: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        transact { state in
            Self.migrateLegacyPrograms(&state.training)
            guard let index = state.training.programs?.firstIndex(where: { $0.id == id }) else { return }
            state.training.programs?[index].name = clean
        }
    }

    func moveTemplate(_ templateID: UUID, toProgram programID: UUID, at requestedIndex: Int) {
        transact { state in
            Self.migrateLegacyPrograms(&state.training)
            guard var programs = state.training.programs,
                  let targetIndex = programs.firstIndex(where: { $0.id == programID }),
                  let sourceIndex = programs.firstIndex(where: { $0.templateIDs.contains(templateID) }) else { return }
            let oldScheduled = programs.map { ($0.id, $0.scheduledTemplate(in: state.training.templates)?.id) }
            programs[sourceIndex].templateIDs.removeAll { $0 == templateID }
            let sourceScheduledID = oldScheduled.first(where: { $0.0 == programs[sourceIndex].id })?.1
            if let sourceScheduledID, let preservedIndex = programs[sourceIndex].templateIDs.firstIndex(of: sourceScheduledID) {
                programs[sourceIndex].rotationIndex = preservedIndex
            } else {
                // The scheduled item itself was moved; the item that followed it
                // now occupies the removed item's old index.
                programs[sourceIndex].rotationIndex = min(programs[sourceIndex].rotationIndex, max(0, programs[sourceIndex].templateIDs.count - 1))
            }
            guard let refreshedTargetIndex = programs.firstIndex(where: { $0.id == programID }) else { return }
            let insertionIndex = min(max(0, requestedIndex), programs[refreshedTargetIndex].templateIDs.count)
            programs[refreshedTargetIndex].templateIDs.insert(templateID, at: insertionIndex)
            if let old = oldScheduled.first(where: { $0.0 == programID })?.1,
               let newIndex = programs[refreshedTargetIndex].templateIDs.firstIndex(of: old) {
                programs[refreshedTargetIndex].rotationIndex = newIndex
            } else if sourceIndex == refreshedTargetIndex {
                programs[refreshedTargetIndex].rotationIndex = insertionIndex
            }
            state.training.programs = programs
            state.training.rotationIndex = programs.first(where: { $0.id == state.training.activeProgramID })?.rotationIndex ?? 0
        }
    }

    @discardableResult
    func skipScheduledWorkout() -> Bool {
        guard state.training.activeSession == nil,
              let activeID = state.training.activeProgramID,
              let program = state.training.programs?.first(where: { $0.id == activeID }),
              program.scheduledTemplate(in: state.training.templates) != nil else { return false }
        transact { state in
            guard var programs = state.training.programs,
                  let index = programs.firstIndex(where: { $0.id == activeID }),
                  !programs[index].templateIDs.isEmpty else { return }
            programs[index].rotationIndex = (programs[index].rotationIndex + 1) % programs[index].templateIDs.count
            state.training.programs = programs
            state.training.rotationIndex = programs[index].rotationIndex
        }
        return true
    }

    func renameTemplate(_ id: UUID, name: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        transact { state in
            guard let index = state.training.templates.firstIndex(where: { $0.id == id }) else { return }
            state.training.templates[index].name = clean
            state.training.templates[index].version += 1
        }
    }

    func reorderProgramTemplates(programID: UUID, orderedIDs: [UUID]) {
        transact { state in
            Self.migrateLegacyPrograms(&state.training)
            guard var programs = state.training.programs,
                  let index = programs.firstIndex(where: { $0.id == programID }) else { return }
            let original = programs[index].templateIDs
            let valid = Set(original)
            let scheduledID = programs[index].scheduledTemplate(in: state.training.templates)?.id
            var reordered = orderedIDs.filter { valid.contains($0) }
            for id in original where !reordered.contains(id) { reordered.append(id) }
            programs[index].templateIDs = reordered
            if let scheduledID, let position = reordered.firstIndex(of: scheduledID) { programs[index].rotationIndex = position }
            else { programs[index].rotationIndex = min(programs[index].rotationIndex, max(0, reordered.count - 1)) }
            state.training.programs = programs
            if state.training.activeProgramID == programID { state.training.rotationIndex = programs[index].rotationIndex }
        }
    }

    func deleteTemplate(_ id: UUID) {
        transact { state in
            Self.migrateLegacyPrograms(&state.training)
            state.training.templates.removeAll { $0.id == id }
            guard var programs = state.training.programs else { return }
            for index in programs.indices {
                let removedIndex = programs[index].templateIDs.firstIndex(of: id)
                programs[index].templateIDs.removeAll { $0 == id }
                if let removedIndex, removedIndex < programs[index].rotationIndex { programs[index].rotationIndex -= 1 }
                if !programs[index].templateIDs.isEmpty { programs[index].rotationIndex %= programs[index].templateIDs.count }
                else { programs[index].rotationIndex = 0 }
            }
            state.training.programs = programs
            state.training.rotationIndex = programs.first(where: { $0.id == state.training.activeProgramID })?.rotationIndex ?? 0
        }
    }

    func removeExercise(_ exerciseID: UUID, fromTemplate templateID: UUID) {
        transact { state in
            guard let index = state.training.templates.firstIndex(where: { $0.id == templateID }) else { return }
            state.training.templates[index].exercises.removeAll { $0.id == exerciseID }
            state.training.templates[index].version += 1
        }
    }

    func reorderTemplateExercises(templateID: UUID, orderedIDs: [UUID]) {
        transact { state in
            guard let templateIndex = state.training.templates.firstIndex(where: { $0.id == templateID }) else { return }
            let original = state.training.templates[templateIndex].exercises
            let byID = Dictionary(uniqueKeysWithValues: original.map { ($0.id, $0) })
            var reordered = orderedIDs.compactMap { byID[$0] }
            for exercise in original where !reordered.contains(where: { $0.id == exercise.id }) { reordered.append(exercise) }
            state.training.templates[templateIndex].exercises = reordered
            state.training.templates[templateIndex].version += 1
        }
    }

    func configurePlannedExercise(templateID: UUID, exerciseID: UUID, setCount: Int, reps: Int, restSeconds: Int?, trackingMode: ExerciseTrackingMode? = nil) {
        transact { state in
            guard let templateIndex = state.training.templates.firstIndex(where: { $0.id == templateID }),
                  let exerciseIndex = state.training.templates[templateIndex].exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
            var exercise = state.training.templates[templateIndex].exercises[exerciseIndex]
            let targetSetCount = min(30, max(1, setCount))
            if exercise.sets.count > targetSetCount { exercise.sets = Array(exercise.sets.prefix(targetSetCount)) }
            while exercise.sets.count < targetSetCount { exercise.sets.append(PlannedSet(reps: max(1, reps))) }
            for index in exercise.sets.indices { exercise.sets[index].reps = max(1, reps) }
            exercise.restSeconds = restSeconds.map { min(600, max(15, $0)) }
            if let trackingMode { exercise.trackingMode = trackingMode }
            state.training.templates[templateIndex].exercises[exerciseIndex] = exercise
            state.training.templates[templateIndex].version += 1
        }
    }

    func setSuperset(templateID: UUID, exerciseIDs: [UUID], groupID: UUID? = nil) {
        let unique = Array(Set(exerciseIDs))
        guard unique.count >= 2 else { return }
        transact { state in
            guard let templateIndex = state.training.templates.firstIndex(where: { $0.id == templateID }) else { return }
            let selected = state.training.templates[templateIndex].exercises.filter { unique.contains($0.id) }
            let mergedGroups = Set(selected.compactMap(\.supersetID) + (groupID.map { [$0] } ?? []))
            let resolvedGroup = groupID ?? mergedGroups.first ?? UUID()
            for index in state.training.templates[templateIndex].exercises.indices {
                let exercise = state.training.templates[templateIndex].exercises[index]
                if unique.contains(exercise.id) || exercise.supersetID.map(mergedGroups.contains) == true {
                    state.training.templates[templateIndex].exercises[index].supersetID = resolvedGroup
                }
            }
            state.training.templates[templateIndex].version += 1
        }
    }

    func ungroupExercise(templateID: UUID, exerciseID: UUID) {
        transact { state in
            guard let templateIndex = state.training.templates.firstIndex(where: { $0.id == templateID }),
                  let exerciseIndex = state.training.templates[templateIndex].exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
            state.training.templates[templateIndex].exercises[exerciseIndex].supersetID = nil
            state.training.templates[templateIndex].version += 1
        }
    }

    func appendExercise(_ exercise: ExerciseDefinition, toTemplate id: UUID) {
        transact { state in
            guard let index = state.training.templates.firstIndex(where: { $0.id == id }) else { return }
            state.training.templates[index].exercises.append(PlannedExercise(
                exerciseID: exercise.id,
                name: exercise.name,
                muscle: exercise.group,
                equipment: exercise.equipment,
                trackingMode: exercise.trackingMode
            ))
            state.training.templates[index].version += 1
        }
    }

    func addCustomExercise(name: String, muscle: String, equipment: String, instructions: String = "", trackingMode: ExerciseTrackingMode = .weightAndReps) -> ExerciseDefinition? {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return nil }
        let item = ExerciseDefinition(id: "custom-\(UUID().uuidString)", name: cleanName, group: muscle, equipment: equipment, description: instructions.trimmingCharacters(in: .whitespacesAndNewlines), isCustom: true, trackingMode: trackingMode)
        transact { $0.training.exercises.append(item) }
        return item
    }

    func startWorkout(_ template: WorkoutTemplate) {
        guard state.training.activeSession == nil else { return }
        let now = Date()
        let originProgram = state.training.activeProgram
        let scheduledTemplateID = originProgram?.scheduledTemplate(in: state.training.templates)?.id
        let isScheduled = scheduledTemplateID == template.id
        let exerciseRows = template.exercises.map { planned in
            WorkoutExercise(
                exerciseID: planned.exerciseID,
                name: planned.name,
                muscle: planned.muscle,
                equipment: planned.equipment,
                sets: planned.sets.map { WorkoutSet(reps: $0.reps, kind: $0.kind) },
                supersetID: planned.supersetID,
                restSeconds: planned.restSeconds,
                trackingMode: planned.trackingMode ?? state.training.exercises.first(where: { $0.id == planned.exerciseID })?.trackingMode
            )
        }
        let session = WorkoutSession(
            templateID: template.id,
            templateName: template.name,
            templateVersion: template.version,
            localDate: LocalDay.string(now),
            startedAt: now,
            exercises: exerciseRows,
            restTimer: WorkoutRestTimer(),
            programID: originProgram?.id,
            scheduledTemplateID: scheduledTemplateID,
            wasScheduledWorkout: isScheduled
        )
        transact { $0.training.activeSession = session }
        guard state.training.activeSession?.id == session.id else { return }
        WorkoutActivityController.shared.start(session: session)
        WatchBridge.shared.send(state: state)
    }

    func startQuickWorkout() {
        guard state.training.activeSession == nil else { return }
        let session = WorkoutSession(templateName: "Workout", templateVersion: 1, localDate: LocalDay.string(), startedAt: .now, exercises: [], restTimer: WorkoutRestTimer())
        transact { $0.training.activeSession = session }
        guard state.training.activeSession?.id == session.id else { return }
        WorkoutActivityController.shared.start(session: session)
    }

    func addExerciseToActive(_ exercise: ExerciseDefinition) {
        guard state.training.activeSession != nil else { return }
        transact { state in
            state.training.activeSession?.exercises.append(WorkoutExercise(
                exerciseID: exercise.id,
                name: exercise.name,
                muscle: exercise.group,
                equipment: exercise.equipment,
                sets: (0..<3).map { _ in WorkoutSet() },
                restSeconds: nil,
                trackingMode: exercise.trackingMode
            ))
        }
    }

    @discardableResult
    func replaceUnstartedActiveExercise(_ exerciseID: UUID, with exercise: ExerciseDefinition) -> Bool {
        guard let session = state.training.activeSession,
              let row = session.exercises.first(where: { $0.id == exerciseID }),
              row.hasStarted != true,
              row.sets.allSatisfy({ !$0.completed && $0.weightKg == nil && $0.durationSeconds == nil && $0.distanceMeters == nil }) else { return false }
        transact { state in
            guard let sessionIndex = state.training.activeSession?.exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
            state.training.activeSession?.exercises[sessionIndex].exerciseID = exercise.id
            state.training.activeSession?.exercises[sessionIndex].name = exercise.name
            state.training.activeSession?.exercises[sessionIndex].muscle = exercise.group
            state.training.activeSession?.exercises[sessionIndex].equipment = exercise.equipment
            state.training.activeSession?.exercises[sessionIndex].notes = ""
            state.training.activeSession?.exercises[sessionIndex].trackingMode = exercise.trackingMode
            state.training.activeSession?.exercises[sessionIndex].restSeconds = nil
        }
        return state.training.activeSession?.exercises.contains(where: { $0.id == exerciseID && $0.exerciseID == exercise.id }) == true
    }

    func addSet(toExercise exerciseID: UUID) {
        transact { state in
            guard let index = state.training.activeSession?.exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
            let previous = state.training.activeSession?.exercises[index].sets.last
            state.training.activeSession?.exercises[index].sets.append(WorkoutSet(weightKg: previous?.weightKg, reps: previous?.reps ?? 8, durationSeconds: previous?.durationSeconds, distanceMeters: previous?.distanceMeters))
        }
    }

    func updateSet(exerciseID: UUID, setID: UUID, weightKg: Double?, reps: Int) {
        transact { state in
            guard let exerciseIndex = state.training.activeSession?.exercises.firstIndex(where: { $0.id == exerciseID }),
                  let setIndex = state.training.activeSession?.exercises[exerciseIndex].sets.firstIndex(where: { $0.id == setID }) else { return }
            state.training.activeSession?.exercises[exerciseIndex].sets[setIndex].weightKg = weightKg
            state.training.activeSession?.exercises[exerciseIndex].sets[setIndex].reps = max(0, reps)
            state.training.activeSession?.exercises[exerciseIndex].hasStarted = true
        }
    }

    func updateSetDuration(exerciseID: UUID, setID: UUID, seconds: Int?) {
        transact { state in
            guard let exerciseIndex = state.training.activeSession?.exercises.firstIndex(where: { $0.id == exerciseID }),
                  let setIndex = state.training.activeSession?.exercises[exerciseIndex].sets.firstIndex(where: { $0.id == setID }) else { return }
            state.training.activeSession?.exercises[exerciseIndex].sets[setIndex].durationSeconds = seconds.map { max(1, $0) }
            state.training.activeSession?.exercises[exerciseIndex].hasStarted = true
        }
    }

    func updateSetDistance(exerciseID: UUID, setID: UUID, weightKg: Double?, distanceMeters: Double?) {
        transact { state in
            guard let exerciseIndex = state.training.activeSession?.exercises.firstIndex(where: { $0.id == exerciseID }),
                  let setIndex = state.training.activeSession?.exercises[exerciseIndex].sets.firstIndex(where: { $0.id == setID }) else { return }
            state.training.activeSession?.exercises[exerciseIndex].sets[setIndex].weightKg = weightKg.flatMap { $0 > 0 ? $0 : nil }
            state.training.activeSession?.exercises[exerciseIndex].sets[setIndex].distanceMeters = distanceMeters.flatMap { $0 > 0 ? $0 : nil }
            state.training.activeSession?.exercises[exerciseIndex].hasStarted = true
        }
    }

    @discardableResult
    func acceptProgressionSuggestion(exerciseID: UUID, weightKg: Double) -> Bool {
        guard weightKg > 0,
              let exercise = state.training.activeSession?.exercises.first(where: { $0.id == exerciseID }),
              (exercise.trackingMode ?? .weightAndReps) == .weightAndReps,
              exercise.sets.allSatisfy({ !$0.completed && $0.weightKg == nil }) else { return false }
        transact { state in
            guard let index = state.training.activeSession?.exercises.firstIndex(where: { $0.id == exerciseID }),
                  var exercises = state.training.activeSession?.exercises else { return }
            for setIndex in exercises[index].sets.indices { exercises[index].sets[setIndex].weightKg = weightKg }
            state.training.activeSession?.exercises = exercises
        }
        return state.training.activeSession?.exercises.first(where: { $0.id == exerciseID })?.sets.allSatisfy { $0.weightKg == weightKg } == true
    }

    func declineProgressionSuggestion(exerciseID: UUID) {
        transact { state in
            guard var session = state.training.activeSession else { return }
            var dismissed = session.declinedProgressionExerciseIDs ?? []
            guard !dismissed.contains(exerciseID) else { return }
            dismissed.append(exerciseID)
            session.declinedProgressionExerciseIDs = dismissed
            state.training.activeSession = session
        }
    }

    func toggleSet(exerciseID: UUID, setID: UUID) -> Bool {
        guard let exercise = state.training.activeSession?.exercises.first(where: { $0.id == exerciseID }),
              let set = exercise.sets.first(where: { $0.id == setID }) else { return false }
        let hasValidMeasurement: Bool
        switch exercise.trackingMode ?? .weightAndReps {
        case .weightAndReps: hasValidMeasurement = (set.weightKg ?? 0) > 0 && set.reps > 0
        case .repsOnly: hasValidMeasurement = set.reps > 0
        case .duration: hasValidMeasurement = (set.durationSeconds ?? 0) > 0
        case .weightAndDistance: hasValidMeasurement = (set.weightKg ?? 0) > 0 && (set.distanceMeters ?? 0) > 0
        }
        guard set.completed || hasValidMeasurement else { return false }
        let isCompleting = !set.completed
        let setIndex = exercise.sets.firstIndex(where: { $0.id == setID })
        transact { state in
            guard let exerciseIndex = state.training.activeSession?.exercises.firstIndex(where: { $0.id == exerciseID }),
                  let setIndex = state.training.activeSession?.exercises[exerciseIndex].sets.firstIndex(where: { $0.id == setID }) else { return }
            state.training.activeSession?.exercises[exerciseIndex].sets[setIndex].completed.toggle()
            state.training.activeSession?.exercises[exerciseIndex].hasStarted = true
        }
        if isCompleting, let setIndex, shouldStartRestTimer(after: exerciseID, setIndex: setIndex),
           let changedExercise = state.training.activeSession?.exercises.first(where: { $0.id == exerciseID }) {
            transact { state in
                var timer = state.training.activeSession?.restTimer ?? WorkoutRestTimer()
                timer.start(seconds: changedExercise.restSeconds)
                state.training.activeSession?.restTimer = timer
            }
        }
        if let active = state.training.activeSession { WorkoutActivityController.shared.update(session: active) }
        WatchBridge.shared.send(state: state)
        return true
    }

    func pauseRestTimer() {
        transact { state in
            var timer = state.training.activeSession?.restTimer ?? WorkoutRestTimer()
            timer.pause()
            state.training.activeSession?.restTimer = timer
        }
    }

    func resumeRestTimer() {
        guard state.training.activeSession?.pausedAt == nil else { return }
        transact { state in
            guard state.training.activeSession?.pausedAt == nil else { return }
            var timer = state.training.activeSession?.restTimer ?? WorkoutRestTimer()
            timer.resume()
            state.training.activeSession?.restTimer = timer
        }
    }

    func updateWorkoutNotes(_ notes: String) {
        transact { $0.training.activeSession?.notes = notes }
    }

    func updateExerciseNotes(_ notes: String, exerciseID: UUID) {
        transact { state in
            guard let index = state.training.activeSession?.exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
            state.training.activeSession?.exercises[index].notes = notes
        }
    }

    func addFifteenSecondsToRestTimer() {
        transact { state in
            var timer = state.training.activeSession?.restTimer ?? WorkoutRestTimer()
            timer.addFifteenSeconds()
            state.training.activeSession?.restTimer = timer
        }
    }

    func skipRestTimer() {
        transact { state in
            var timer = state.training.activeSession?.restTimer ?? WorkoutRestTimer()
            timer.skip()
            state.training.activeSession?.restTimer = timer
        }
    }

    func setWorkoutRestDuration(_ seconds: Int) {
        transact { state in
            var timer = state.training.activeSession?.restTimer ?? WorkoutRestTimer()
            timer.setBaseDuration(seconds)
            state.training.activeSession?.restTimer = timer
        }
    }

    func finishWorkout(confirmIncomplete: Bool) -> Int {
        guard var session = state.training.activeSession else { return 0 }
        let incomplete = session.exercises.flatMap(\.sets).filter { !$0.completed }.count
        guard incomplete == 0 || confirmIncomplete else { return incomplete }
        let finishedAt = Date.now
        if let pausedAt = session.pausedAt { session.pausedSeconds += finishedAt.timeIntervalSince(pausedAt) }
        session.finishedAt = finishedAt
        session.pausedAt = nil
        transact { state in
            state.training.completedSessions.append(session)
            state.training.activeSession = nil
            if let programID = session.programID,
               session.wasScheduledWorkout == true,
               let programIndex = state.training.programs?.firstIndex(where: { $0.id == programID }),
               let expectedID = session.scheduledTemplateID,
               state.training.programs?[programIndex].scheduledTemplate(in: state.training.templates)?.id == expectedID,
               let count = state.training.programs?[programIndex].templateIDs.count,
               count > 0 {
                let nextRotation = ((state.training.programs?[programIndex].rotationIndex ?? 0) + 1) % count
                state.training.programs?[programIndex].rotationIndex = nextRotation
                if state.training.activeProgramID == programID { state.training.rotationIndex = nextRotation }
            } else if session.programID == nil,
                      session.wasScheduledWorkout == nil,
                      let templateID = session.templateID,
                      let programIndex = state.training.programs?.firstIndex(where: { $0.templateIDs.contains(templateID) }),
                      state.training.programs?[programIndex].scheduledTemplate(in: state.training.templates)?.id == templateID,
                      let count = state.training.programs?[programIndex].templateIDs.count,
                      count > 0 {
                let nextRotation = ((state.training.programs?[programIndex].rotationIndex ?? 0) + 1) % count
                state.training.programs?[programIndex].rotationIndex = nextRotation
                if state.training.activeProgramID == state.training.programs?[programIndex].id { state.training.rotationIndex = nextRotation }
            }
        }
        guard state.training.activeSession == nil else { return -2 }
        WorkoutActivityController.shared.finish(session: session)
        WatchBridge.shared.send(state: state)
        return -1
    }

    func updateCompletedWorkoutSet(sessionID: UUID, exerciseID: UUID, setID: UUID, weightKg: Double?, reps: Int, completed: Bool, durationSeconds: Int? = nil, distanceMeters: Double? = nil) {
        transact { state in
            guard let sessionIndex = state.training.completedSessions.firstIndex(where: { $0.id == sessionID && $0.deletedAt == nil }),
                  let exerciseIndex = state.training.completedSessions[sessionIndex].exercises.firstIndex(where: { $0.id == exerciseID }),
                  let setIndex = state.training.completedSessions[sessionIndex].exercises[exerciseIndex].sets.firstIndex(where: { $0.id == setID }) else { return }
            state.training.completedSessions[sessionIndex].exercises[exerciseIndex].sets[setIndex].weightKg = weightKg.flatMap { $0 > 0 ? $0 : nil }
            state.training.completedSessions[sessionIndex].exercises[exerciseIndex].sets[setIndex].reps = max(0, reps)
            state.training.completedSessions[sessionIndex].exercises[exerciseIndex].sets[setIndex].completed = completed
            state.training.completedSessions[sessionIndex].exercises[exerciseIndex].sets[setIndex].durationSeconds = durationSeconds
            state.training.completedSessions[sessionIndex].exercises[exerciseIndex].sets[setIndex].distanceMeters = distanceMeters
        }
    }

    func updateCompletedWorkoutNotes(sessionID: UUID, notes: String) {
        transact { state in
            guard let index = state.training.completedSessions.firstIndex(where: { $0.id == sessionID && $0.deletedAt == nil }) else { return }
            state.training.completedSessions[index].notes = notes
        }
    }

    func updateCompletedExerciseNotes(sessionID: UUID, exerciseID: UUID, notes: String) {
        transact { state in
            guard let sessionIndex = state.training.completedSessions.firstIndex(where: { $0.id == sessionID && $0.deletedAt == nil }),
                  let exerciseIndex = state.training.completedSessions[sessionIndex].exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
            state.training.completedSessions[sessionIndex].exercises[exerciseIndex].notes = notes
        }
    }

    func deleteCompletedWorkout(_ id: UUID, at date: Date = .now) {
        transact { state in
            guard let index = state.training.completedSessions.firstIndex(where: { $0.id == id && $0.deletedAt == nil }) else { return }
            state.training.completedSessions[index].deletedAt = date
        }
    }

    @discardableResult
    func restoreDeletedWorkout(_ id: UUID, at date: Date = .now) -> Bool {
        guard let session = state.training.completedSessions.first(where: { $0.id == id }),
              let deletedAt = session.deletedAt,
              date.timeIntervalSince(deletedAt) >= 0,
              date.timeIntervalSince(deletedAt) < 30 * 24 * 60 * 60 else { return false }
        transact { state in
            guard let index = state.training.completedSessions.firstIndex(where: { $0.id == id }) else { return }
            state.training.completedSessions[index].deletedAt = nil
        }
        return state.training.completedSessions.first(where: { $0.id == id })?.deletedAt == nil
    }

    func permanentlyDeleteWorkout(_ id: UUID) {
        transact { $0.training.completedSessions.removeAll { $0.id == id && $0.deletedAt != nil } }
    }

    func purgeExpiredDeletedWorkouts(asOf date: Date = .now) {
        transact { state in _ = Self.purgeExpiredWorkoutRecords(&state.training, asOf: date) }
    }

    func discardWorkout() {
        guard state.training.activeSession != nil else { return }
        transact { $0.training.activeSession = nil }
        WorkoutActivityController.shared.cancel()
        WatchBridge.shared.send(state: state)
    }

    func pauseWorkout() {
        transact { state in
            guard state.training.activeSession?.pausedAt == nil else { return }
            state.training.activeSession?.pausedAt = .now
            var timer = state.training.activeSession?.restTimer ?? WorkoutRestTimer()
            timer.pause()
            state.training.activeSession?.restTimer = timer
        }
        if let session = state.training.activeSession { WorkoutActivityController.shared.update(session: session) }
    }

    func resumeWorkout() {
        transact { state in
            guard let pausedAt = state.training.activeSession?.pausedAt else { return }
            state.training.activeSession?.pausedSeconds += Date.now.timeIntervalSince(pausedAt)
            state.training.activeSession?.pausedAt = nil
            var timer = state.training.activeSession?.restTimer ?? WorkoutRestTimer()
            timer.resume()
            state.training.activeSession?.restTimer = timer
        }
        if let session = state.training.activeSession { WorkoutActivityController.shared.update(session: session) }
    }

    func addFoodDefinition(_ food: FoodDefinition) {
        guard !food.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              [food.calories, food.protein, food.carbohydrates, food.fat].allSatisfy({ $0.isFinite && $0 >= 0 }),
              food.basisAmount.isFinite, food.basisAmount > 0 else { return }
        transact { state in
            if let index = state.nutrition.foods.firstIndex(where: { $0.id == food.id }) { state.nutrition.foods[index] = food }
            else { state.nutrition.foods.append(food) }
        }
    }

    func cacheFoodDefinitions(_ foods: [FoodDefinition]) {
        let valid = foods.filter {
            !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            $0.basisAmount.isFinite && $0.basisAmount > 0 &&
            [$0.calories, $0.protein, $0.carbohydrates, $0.fat].allSatisfy { $0.isFinite && $0 >= 0 }
        }
        guard !valid.isEmpty else { return }
        transact { state in
            for food in valid {
                if let index = state.nutrition.foods.firstIndex(where: { $0.id == food.id }) { state.nutrition.foods[index] = food }
                else { state.nutrition.foods.append(food) }
            }
        }
    }

    func setFoodFavorite(_ foodID: String, isFavorite: Bool) {
        transact { state in
            var ids = state.nutrition.favoriteFoodIDs ?? []
            ids.removeAll { $0 == foodID }
            if isFavorite { ids.append(foodID) }
            state.nutrition.favoriteFoodIDs = ids
        }
    }

    func logFood(_ food: FoodDefinition, meal: MealSlot, quantity: Double, unit: String, confirmed: Bool, date: String = LocalDay.string()) -> Bool {
        guard confirmed, let factor = food.multiplier(for: quantity, unit: unit),
              [food.calories, food.protein, food.carbohydrates, food.fat].allSatisfy({ $0.isFinite && $0 >= 0 }) else { return false }
        let log = FoodLog(
            foodID: food.id,
            foodName: food.name,
            mealID: meal.id,
            mealName: meal.name,
            date: date,
            quantity: quantity,
            unit: unit,
            calories: food.calories * factor,
            protein: food.protein * factor,
            carbohydrates: food.carbohydrates * factor,
            fat: food.fat * factor,
            confirmedAt: .now
        )
        transact { state in
            state.nutrition.logs.append(log)
            if !state.nutrition.foods.contains(where: { $0.id == food.id }) { state.nutrition.foods.append(food) }
        }
        return true
    }

    func updateFoodLog(_ id: UUID, foodName: String, mealID: UUID, mealName: String, quantity: Double, unit: String, calories: Double, protein: Double, carbohydrates: Double, fat: Double, date: String) -> Bool {
        let name = foodName.trimmingCharacters(in: .whitespacesAndNewlines)
        let values = [quantity, calories, protein, carbohydrates, fat]
        guard !name.isEmpty, quantity.isFinite, quantity > 0,
              values.dropFirst().allSatisfy({ $0.isFinite && $0 >= 0 }) else { return false }
        transact { state in
            guard let index = state.nutrition.logs.firstIndex(where: { $0.id == id && $0.deletedAt == nil }) else { return }
            state.nutrition.logs[index].foodName = name
            state.nutrition.logs[index].mealID = mealID
            state.nutrition.logs[index].mealName = mealName
            state.nutrition.logs[index].quantity = quantity
            state.nutrition.logs[index].unit = unit
            state.nutrition.logs[index].calories = calories
            state.nutrition.logs[index].protein = protein
            state.nutrition.logs[index].carbohydrates = carbohydrates
            state.nutrition.logs[index].fat = fat
            state.nutrition.logs[index].date = date
        }
        return state.nutrition.logs.first(where: { $0.id == id })?.foodName == name
    }

    func addMeal(name: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        transact { $0.nutrition.meals.append(MealSlot(name: clean)) }
    }

    func renameMeal(_ id: UUID, name: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        transact { state in
            guard let index = state.nutrition.meals.firstIndex(where: { $0.id == id }) else { return }
            state.nutrition.meals[index].name = clean
        }
    }

    func makeRecipeIngredient(food: FoodDefinition, quantity: Double, unit: String) -> FoodRecipeIngredient? {
        guard let factor = food.multiplier(for: quantity, unit: unit) else { return nil }
        return FoodRecipeIngredient(foodID: food.id, foodName: food.name, amount: quantity, unit: unit,
            calories: food.calories * factor, protein: food.protein * factor,
            carbohydrates: food.carbohydrates * factor, fat: food.fat * factor)
    }

    @discardableResult
    func saveRecipe(name: String, ingredients: [FoodRecipeIngredient], yieldAmount: Double, yieldUnit: String, id: String? = nil) -> String? {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, !ingredients.isEmpty, yieldAmount.isFinite, yieldAmount > 0,
              ["servings", "g"].contains(yieldUnit) else { return nil }
        let recipeID = id ?? "recipe-\(UUID().uuidString)"
        let recipe = FoodRecipe(id: recipeID, name: clean, ingredients: ingredients, yieldAmount: yieldAmount, yieldUnit: yieldUnit)
        transact { state in
            var recipes = state.nutrition.recipes ?? []
            if let index = recipes.firstIndex(where: { $0.id == recipeID }) { recipes[index] = recipe }
            else { recipes.append(recipe) }
            state.nutrition.recipes = recipes
        }
        return state.nutrition.recipes?.first(where: { $0.id == recipeID })?.id
    }

    func foodDefinition(for recipe: FoodRecipe) -> FoodDefinition {
        let total = recipe.total
        return FoodDefinition(id: recipe.id, name: recipe.name, basisAmount: 1, basisUnit: recipe.yieldUnit,
            calories: (total.calories ?? 0) / recipe.yieldAmount,
            protein: (total.protein ?? 0) / recipe.yieldAmount,
            carbohydrates: (total.carbohydrates ?? 0) / recipe.yieldAmount,
            fat: (total.fat ?? 0) / recipe.yieldAmount,
            source: "Saved Logbook recipe", isPersonal: true)
    }

    func deleteRecipe(_ id: String, at date: Date = .now) {
        transact { state in
            guard let index = state.nutrition.recipes?.firstIndex(where: { $0.id == id && $0.deletedAt == nil }) else { return }
            state.nutrition.recipes?[index].deletedAt = date
        }
    }

    func recentlyDeletedRecipes(asOf date: Date = .now) -> [FoodRecipe] {
        (state.nutrition.recipes ?? []).filter { recipe in
            guard let deletedAt = recipe.deletedAt else { return false }
            let age = date.timeIntervalSince(deletedAt)
            return age >= 0 && age < 30 * 24 * 60 * 60
        }.sorted { ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast) }
    }

    @discardableResult
    func restoreDeletedRecipe(_ id: String, at date: Date = .now) -> Bool {
        guard let recipe = state.nutrition.recipes?.first(where: { $0.id == id }), let deletedAt = recipe.deletedAt,
              date.timeIntervalSince(deletedAt) >= 0, date.timeIntervalSince(deletedAt) < 30 * 24 * 60 * 60 else { return false }
        transact { state in
            guard let index = state.nutrition.recipes?.firstIndex(where: { $0.id == id }) else { return }
            state.nutrition.recipes?[index].deletedAt = nil
        }
        return state.nutrition.recipes?.first(where: { $0.id == id })?.deletedAt == nil
    }

    func permanentlyDeleteRecipe(_ id: String) {
        transact { $0.nutrition.recipes?.removeAll { $0.id == id && $0.deletedAt != nil } }
    }

    func copyMeals(from sourceDate: String, to destinationDate: String, mealName: String? = nil, replaceMatchingMeals: Bool) -> Int {
        guard sourceDate != destinationDate else { return 0 }
        let sourceLogs = state.nutrition.logs.filter { $0.date == sourceDate && $0.deletedAt == nil && (mealName == nil || $0.mealName == mealName) }
        guard !sourceLogs.isEmpty else { return 0 }
        transact { state in
            let matchingNames = Set(sourceLogs.map(\.mealName))
            if replaceMatchingMeals {
                for index in state.nutrition.logs.indices where state.nutrition.logs[index].date == destinationDate &&
                    state.nutrition.logs[index].deletedAt == nil && matchingNames.contains(state.nutrition.logs[index].mealName) {
                    state.nutrition.logs[index].deletedAt = .now
                }
            }
            for source in sourceLogs {
                var copy = source
                copy.id = UUID()
                copy.date = destinationDate
                copy.confirmedAt = .now
                copy.deletedAt = nil
                state.nutrition.logs.append(copy)
            }
        }
        return sourceLogs.count
    }

    func addWater(_ milliliters: Int, date: String = LocalDay.string()) {
        guard (1...5000).contains(milliliters) else { return }
        transact { $0.nutrition.water.append(WaterLog(date: date, milliliters: milliliters)) }
    }

    func setWaterGoal(_ milliliters: Int?) {
        guard milliliters == nil || (1...10000).contains(milliliters!) else { return }
        transact { $0.nutrition.waterGoalMilliliters = milliliters }
    }

    func updateWaterLog(_ id: UUID, milliliters: Int, date: String) -> Bool {
        guard (1...5000).contains(milliliters) else { return false }
        transact { state in
            guard let index = state.nutrition.water.firstIndex(where: { $0.id == id && $0.deletedAt == nil }) else { return }
            state.nutrition.water[index].milliliters = milliliters
            state.nutrition.water[index].date = date
        }
        return state.nutrition.water.first(where: { $0.id == id && $0.deletedAt == nil })?.milliliters == milliliters
    }

    func deleteFoodLog(_ id: UUID, at date: Date = .now) {
        transact { state in
            guard let index = state.nutrition.logs.firstIndex(where: { $0.id == id && $0.deletedAt == nil }) else { return }
            state.nutrition.logs[index].deletedAt = date
        }
    }

    func recentlyDeletedFoodLogs(asOf date: Date = .now) -> [FoodLog] {
        state.nutrition.logs.filter { log in
            guard let deletedAt = log.deletedAt else { return false }
            let age = date.timeIntervalSince(deletedAt)
            return age >= 0 && age < 30 * 24 * 60 * 60
        }.sorted { ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast) }
    }

    @discardableResult
    func restoreDeletedFoodLog(_ id: UUID, at date: Date = .now) -> Bool {
        guard let log = state.nutrition.logs.first(where: { $0.id == id }),
              let deletedAt = log.deletedAt,
              date.timeIntervalSince(deletedAt) >= 0,
              date.timeIntervalSince(deletedAt) < 30 * 24 * 60 * 60 else { return false }
        transact { state in
            guard let index = state.nutrition.logs.firstIndex(where: { $0.id == id }) else { return }
            state.nutrition.logs[index].deletedAt = nil
        }
        return state.nutrition.logs.first(where: { $0.id == id })?.deletedAt == nil
    }

    func permanentlyDeleteFoodLog(_ id: UUID) {
        transact { $0.nutrition.logs.removeAll { $0.id == id && $0.deletedAt != nil } }
    }

    func purgeExpiredFoodLogs(asOf date: Date = .now) {
        transact { state in _ = Self.purgeExpiredFoodRecords(&state.nutrition, asOf: date) }
    }

    func removeWater(_ id: UUID, at date: Date = .now) {
        transact { state in
            guard let index = state.nutrition.water.firstIndex(where: { $0.id == id && $0.deletedAt == nil }) else { return }
            state.nutrition.water[index].deletedAt = date
        }
    }

    func recentlyDeletedWaterLogs(asOf date: Date = .now) -> [WaterLog] {
        state.nutrition.water.filter { log in
            guard let deletedAt = log.deletedAt else { return false }
            let age = date.timeIntervalSince(deletedAt)
            return age >= 0 && age < 30 * 24 * 60 * 60
        }.sorted { ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast) }
    }

    @discardableResult
    func restoreDeletedWaterLog(_ id: UUID, at date: Date = .now) -> Bool {
        guard let log = state.nutrition.water.first(where: { $0.id == id }), let deletedAt = log.deletedAt,
              date.timeIntervalSince(deletedAt) >= 0, date.timeIntervalSince(deletedAt) < 30 * 24 * 60 * 60 else { return false }
        transact { state in
            guard let index = state.nutrition.water.firstIndex(where: { $0.id == id }) else { return }
            state.nutrition.water[index].deletedAt = nil
        }
        return state.nutrition.water.first(where: { $0.id == id })?.deletedAt == nil
    }

    func permanentlyDeleteWaterLog(_ id: UUID) {
        transact { $0.nutrition.water.removeAll { $0.id == id && $0.deletedAt != nil } }
    }

    @discardableResult
    func addSleep(bedtime: Date, wakeTime: Date, manualMinutes: Int? = nil, confirmedReplace: Bool = false) -> Bool {
        guard wakeTime > bedtime else { return false }
        let log = SleepLog(wakeDate: LocalDay.string(wakeTime), bedtime: bedtime, wakeTime: wakeTime, manualMinutes: manualMinutes)
        guard confirmedReplace || !state.checkins.sleep.contains(where: { $0.wakeDate == log.wakeDate }) else { return false }
        transact { state in
            state.checkins.sleep.removeAll { $0.wakeDate == log.wakeDate }
            state.checkins.sleep.append(log)
        }
        return state.checkins.sleep.contains(where: { $0.id == log.id })
    }

    @discardableResult
    func addWeight(_ value: Double, unit: String = "kg", confirmedReplace: Bool = false) -> Bool {
        guard value > 0 else { return false }
        let kg = unit == "lb" ? value / 2.2046226218 : value
        let log = WeightLog(date: LocalDay.string(), kilograms: kg)
        guard confirmedReplace || !state.checkins.weights.contains(where: { $0.date == log.date }) else { return false }
        transact { state in
            state.checkins.weights.removeAll { $0.date == log.date }
            state.checkins.weights.append(log)
        }
        return state.checkins.weights.contains(where: { $0.id == log.id })
    }

    func addSupplement(name: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        transact { $0.checkins.supplements.append(Supplement(name: clean)) }
    }

    func markSupplement(_ supplement: Supplement, taken: Bool) {
        let date = LocalDay.string()
        transact { state in
            if let index = state.checkins.doses.firstIndex(where: { $0.supplementID == supplement.id && $0.date == date }) {
                state.checkins.doses[index].taken = taken
                state.checkins.doses[index].explicitlyMarked = true
            } else {
                state.checkins.doses.append(SupplementDose(supplementID: supplement.id, supplementName: supplement.name, date: date, taken: taken, explicitlyMarked: true))
            }
        }
    }

    func setHomePages(_ pages: [HomePage]) {
        transact { $0.home.pages = pages }
    }

    func undoHomeLayout() {
        guard let previous = state.home.undoPages else { return }
        transact { $0.home.pages = previous }
    }

    func addHomePage(name: String = "New Page") {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, state.home.pages.count < 40 else { return }
        transact { $0.home.pages.append(HomePage(name: clean, widgets: [])) }
    }

    func renameHomePage(_ id: UUID, name: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        transact { state in
            guard let index = state.home.pages.firstIndex(where: { $0.id == id }) else { return }
            state.home.pages[index].name = clean
        }
    }

    func deleteHomePage(_ id: UUID) {
        guard state.home.pages.count > 1 else { return }
        transact { $0.home.pages.removeAll { $0.id == id } }
    }

    func addHomeWidget(_ kind: WidgetKind, size: WidgetSize, pageID: UUID) -> Bool {
        guard let pageIndex = state.home.pages.firstIndex(where: { $0.id == pageID }) else { return false }
        var page = state.home.pages[pageIndex]
        let columns = size == .small ? 1 : 2
        let rows = size == .large ? 2 : 1
        var used = Set<String>()
        for widget in page.widgets {
            let widgetColumns = widget.size == .small ? 1 : 2
            let widgetRows = widget.size == .large ? 2 : 1
            for r in widget.row..<(widget.row + widgetRows) {
                for c in widget.column..<(widget.column + widgetColumns) { used.insert("\(r):\(c)") }
            }
        }
        var slot: (Int, Int)?
        for row in 0...max(0, 4 - rows) where slot == nil {
            for column in 0...max(0, 2 - columns) {
                let cells = (row..<(row + rows)).flatMap { r in (column..<(column + columns)).map { "\(r):\($0)" } }
                if cells.allSatisfy({ !used.contains($0) }) { slot = (row, column); break }
            }
        }
        guard let (row, column) = slot else { return false }
        page.widgets.append(HomeWidget(kind: kind, size: size, row: row, column: column))
        transact { $0.home.pages[pageIndex] = page }
        return true
    }

    func removeHomeWidget(_ widgetID: UUID, pageID: UUID) {
        transact { state in
            guard let index = state.home.pages.firstIndex(where: { $0.id == pageID }) else { return }
            state.home.pages[index].widgets.removeAll { $0.id == widgetID }
        }
    }

    func moveHomeWidget(_ widgetID: UUID, fromPageID: UUID, toPageID: UUID, row: Int, column: Int) -> Bool {
        var pages = state.home.pages
        guard let sourceIndex = pages.firstIndex(where: { $0.id == fromPageID }),
              let widgetIndex = pages[sourceIndex].widgets.firstIndex(where: { $0.id == widgetID }),
              let targetIndex = pages.firstIndex(where: { $0.id == toPageID }) else { return false }
        var widget = pages[sourceIndex].widgets.remove(at: widgetIndex)
        widget.row = row
        widget.column = column
        pages[targetIndex].widgets.append(widget)
        guard Self.isValidHomePages(pages) else {
            persistenceError = "That position is occupied or outside this page. The saved layout was kept."
            return false
        }
        transact { $0.home.pages = pages }
        return true
    }

    func resizeHomeWidget(_ widgetID: UUID, pageID: UUID, size: WidgetSize) {
        transact { state in
            guard let pageIndex = state.home.pages.firstIndex(where: { $0.id == pageID }),
                  let widgetIndex = state.home.pages[pageIndex].widgets.firstIndex(where: { $0.id == widgetID }) else { return }
            state.home.pages[pageIndex].widgets[widgetIndex].size = size
        }
    }

    func setHaptics(_ enabled: Bool) {
        transact { $0.home.hapticsEnabled = enabled }
    }

    func setWeightUnit(_ unit: String) {
        guard unit == "kg" || unit == "lb" else { return }
        transact { $0.home.preferredWeightUnit = unit }
    }

    func setReminder(kind: LogbookRoute, time: String?) {
        transact { state in
            switch kind {
            case .food: state.nutritionReminderTime = time
            case .training: state.trainingReminderTime = time
            default: break
            }
        }
        if state.notificationsEnabled {
            if kind == .food { ReminderService.scheduleNutrition(at: time) }
            if kind == .training { ReminderService.scheduleTraining(at: time) }
        }
    }

    func clearPersistenceError() { persistenceError = nil }

    func exportBackup() throws -> URL {
        let data = try JSONEncoder.logbook.encode(state)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Logbook-Backup-\(LocalDay.string()).json")
        try data.write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
        return url
    }

    private func transact(_ mutation: (inout LogbookState) -> Void) {
        guard canEdit else { return }
        var candidate = state
        mutation(&candidate)
        if candidate.home.pages != state.home.pages && candidate.home.undoPages == state.home.undoPages {
            candidate.home.undoPages = state.home.pages
        }
        candidate.lastModified = .now
        do {
            guard Self.isValid(candidate) else {
                persistenceError = "That change would create an invalid Home Screen layout. The saved layout was kept."
                return
            }
            try repository.save(candidate)
            state = candidate
            persistenceError = nil
            lastSavedAt = .now
            WidgetCenter.shared.reloadAllTimelines()
            WatchBridge.shared.send(state: candidate)
            if let active = candidate.training.activeSession { WorkoutActivityController.shared.update(session: active) }
        } catch {
            persistenceError = "Could not save this change. Your earlier saved data is still on this device. \(error.localizedDescription)"
        }
    }

    private func shouldStartRestTimer(after exerciseID: UUID, setIndex: Int) -> Bool {
        guard let session = state.training.activeSession,
              let exercise = session.exercises.first(where: { $0.id == exerciseID }) else { return false }
        guard let supersetID = exercise.supersetID else { return true }
        return session.exercises
            .filter { $0.supersetID == supersetID }
            .allSatisfy { member in
                guard member.sets.indices.contains(setIndex) else { return true }
                return member.sets[setIndex].completed
            }
    }

    @discardableResult
    private static func migrateLegacyPrograms(_ training: inout TrainingState) -> Bool {
        guard training.programs == nil || training.programs?.isEmpty == true else {
            if training.activeProgramID == nil || training.programs?.contains(where: { $0.id == training.activeProgramID }) != true {
                training.activeProgramID = training.programs?.first?.id
                return true
            }
            return false
        }
        let id = UUID(uuidString: "A989A0DF-8E57-4DEB-BB52-66B9BD039999") ?? UUID()
        let index = training.templates.isEmpty ? 0 : training.rotationIndex % training.templates.count
        training.programs = [WorkoutProgram(id: id, name: "Program 1", templateIDs: training.templates.map(\.id), rotationIndex: index)]
        training.activeProgramID = id
        training.rotationIndex = index
        return true
    }

    @discardableResult
    private static func purgeExpiredWorkoutRecords(_ training: inout TrainingState, asOf date: Date) -> Bool {
        let originalCount = training.completedSessions.count
        training.completedSessions.removeAll { session in
            guard let deletedAt = session.deletedAt else { return false }
            return date.timeIntervalSince(deletedAt) >= 30 * 24 * 60 * 60
        }
        return training.completedSessions.count != originalCount
    }

    @discardableResult
    private static func purgeExpiredFoodRecords(_ nutrition: inout NutritionState, asOf date: Date) -> Bool {
        let originalCount = nutrition.logs.count + nutrition.water.count + (nutrition.recipes?.count ?? 0)
        nutrition.logs.removeAll { log in
            guard let deletedAt = log.deletedAt else { return false }
            return date.timeIntervalSince(deletedAt) >= 30 * 24 * 60 * 60
        }
        nutrition.water.removeAll { log in
            guard let deletedAt = log.deletedAt else { return false }
            return date.timeIntervalSince(deletedAt) >= 30 * 24 * 60 * 60
        }
        nutrition.recipes?.removeAll { recipe in
            guard let deletedAt = recipe.deletedAt else { return false }
            return date.timeIntervalSince(deletedAt) >= 30 * 24 * 60 * 60
        }
        return nutrition.logs.count + nutrition.water.count + (nutrition.recipes?.count ?? 0) != originalCount
    }

    private static func isValid(_ state: LogbookState) -> Bool {
        state.schemaVersion == 1 && isValidHomePages(state.home.pages)
    }

    private static func isValidHomePages(_ pages: [HomePage]) -> Bool {
        guard !pages.isEmpty, pages.count <= 40 else { return false }
        for page in pages {
            var occupied = Set<String>()
            for widget in page.widgets {
                let columns = widget.size == .small ? 1 : 2
                let rows = widget.size == .large ? 2 : 1
                guard widget.row >= 0, widget.column >= 0, widget.row + rows <= 4, widget.column + columns <= 2 else { return false }
                for row in widget.row..<(widget.row + rows) {
                    for column in widget.column..<(widget.column + columns) {
                        let cell = "\(row):\(column)"
                        guard occupied.insert(cell).inserted else { return false }
                    }
                }
            }
        }
        return true
    }
}
