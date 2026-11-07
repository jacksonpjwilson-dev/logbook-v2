import Foundation
import Combine
import WidgetKit

@MainActor
final class LogbookStore: ObservableObject {
    @Published private(set) var state: LogbookState
    @Published private(set) var persistenceError: String?
    @Published private(set) var lastSavedAt: Date?
    @Published private(set) var focusedCheckInSection: CheckInSection?

    private let repository: LogbookRepository
    private(set) var canEdit = true

    init(repository: LogbookRepository = .shared) {
        self.repository = repository
        do {
            var loaded = try repository.load()
            if loaded.training.exercises.isEmpty, let url = Bundle.main.url(forResource: "exercise-catalog", withExtension: "json"),
               let data = try? Data(contentsOf: url), let catalogue = try? JSONDecoder().decode([ExerciseDefinition].self, from: data) {
                loaded.training.exercises = catalogue
            }
            if loaded.nutrition.foods.isEmpty, let url = Bundle.main.url(forResource: "food-catalog", withExtension: "json"),
               let data = try? Data(contentsOf: url), let foods = try? JSONDecoder().decode([FoodDefinition].self, from: data) {
                loaded.nutrition.foods = foods
            }
            let migratedDailyLayout = loaded.home.migrateUntouchedDailyLayout()
            state = loaded
            lastSavedAt = FileManager.default.fileExists(atPath: repository.url.path) ? Date() : nil
            if migratedDailyLayout {
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
        fixture.training.templates = [template]
        fixture.training.rotationIndex = 0
        fixture.training.completedSessions = [WorkoutSession(
                templateID: templateID,
                templateName: template.name,
                templateVersion: template.version,
                localDate: LocalDay.string(yesterday),
                startedAt: finished.addingTimeInterval(-2_700),
                finishedAt: finished,
                exercises: []
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

    func setNutritionTargets(calories: Double?, protein: Double?, carbohydrates: Double?, fat: Double?) {
        transact {
            $0.nutrition.targets = NutritionTargets(calories: calories, protein: protein, carbohydrates: carbohydrates, fat: fat)
            $0.home.dailyCalorieGoal = calories
            $0.home.dailyProteinGoal = protein
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
        transact { $0.training.templates.append(template) }
        return template.id
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

    func deleteTemplate(_ id: UUID) {
        transact { state in
            state.training.templates.removeAll { $0.id == id }
            state.training.rotationIndex = min(state.training.rotationIndex, max(0, state.training.templates.count - 1))
        }
    }

    func removeExercise(_ exerciseID: UUID, fromTemplate templateID: UUID) {
        transact { state in
            guard let index = state.training.templates.firstIndex(where: { $0.id == templateID }) else { return }
            state.training.templates[index].exercises.removeAll { $0.id == exerciseID }
            state.training.templates[index].version += 1
        }
    }

    func appendExercise(_ exercise: ExerciseDefinition, toTemplate id: UUID) {
        transact { state in
            guard let index = state.training.templates.firstIndex(where: { $0.id == id }) else { return }
            state.training.templates[index].exercises.append(PlannedExercise(
                exerciseID: exercise.id,
                name: exercise.name,
                muscle: exercise.group,
                equipment: exercise.equipment
            ))
            state.training.templates[index].version += 1
        }
    }

    func addCustomExercise(name: String, muscle: String, equipment: String) -> ExerciseDefinition? {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return nil }
        let item = ExerciseDefinition(id: "custom-\(UUID().uuidString)", name: cleanName, group: muscle, equipment: equipment, isCustom: true)
        transact { $0.training.exercises.append(item) }
        return item
    }

    func startWorkout(_ template: WorkoutTemplate) {
        guard state.training.activeSession == nil else { return }
        let now = Date()
        let exerciseRows = template.exercises.map { planned in
            WorkoutExercise(
                exerciseID: planned.exerciseID,
                name: planned.name,
                muscle: planned.muscle,
                equipment: planned.equipment,
                sets: planned.sets.map { WorkoutSet(reps: $0.reps, kind: $0.kind) },
                supersetID: planned.supersetID,
                restSeconds: planned.restSeconds
            )
        }
        let session = WorkoutSession(
            templateID: template.id,
            templateName: template.name,
            templateVersion: template.version,
            localDate: LocalDay.string(now),
            startedAt: now,
            exercises: exerciseRows,
            restTimer: WorkoutRestTimer()
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
                restSeconds: nil
            ))
        }
    }

    func addSet(toExercise exerciseID: UUID) {
        transact { state in
            guard let index = state.training.activeSession?.exercises.firstIndex(where: { $0.id == exerciseID }) else { return }
            let previous = state.training.activeSession?.exercises[index].sets.last
            state.training.activeSession?.exercises[index].sets.append(WorkoutSet(weightKg: previous?.weightKg, reps: previous?.reps ?? 8))
        }
    }

    func updateSet(exerciseID: UUID, setID: UUID, weightKg: Double?, reps: Int) {
        transact { state in
            guard let exerciseIndex = state.training.activeSession?.exercises.firstIndex(where: { $0.id == exerciseID }),
                  let setIndex = state.training.activeSession?.exercises[exerciseIndex].sets.firstIndex(where: { $0.id == setID }) else { return }
            state.training.activeSession?.exercises[exerciseIndex].sets[setIndex].weightKg = weightKg
            state.training.activeSession?.exercises[exerciseIndex].sets[setIndex].reps = max(1, reps)
        }
    }

    func toggleSet(exerciseID: UUID, setID: UUID) -> Bool {
        guard let exercise = state.training.activeSession?.exercises.first(where: { $0.id == exerciseID }),
              let set = exercise.sets.first(where: { $0.id == setID }) else { return false }
        guard set.completed || (set.weightKg ?? 0) > 0 && set.reps > 0 else { return false }
        let isCompleting = !set.completed
        let setIndex = exercise.sets.firstIndex(where: { $0.id == setID })
        transact { state in
            guard let exerciseIndex = state.training.activeSession?.exercises.firstIndex(where: { $0.id == exerciseID }),
                  let setIndex = state.training.activeSession?.exercises[exerciseIndex].sets.firstIndex(where: { $0.id == setID }) else { return }
            state.training.activeSession?.exercises[exerciseIndex].sets[setIndex].completed.toggle()
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
        transact { state in
            var timer = state.training.activeSession?.restTimer ?? WorkoutRestTimer()
            timer.resume()
            state.training.activeSession?.restTimer = timer
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
        session.finishedAt = .now
        session.pausedAt = nil
        transact { state in
            state.training.completedSessions.append(session)
            state.training.activeSession = nil
            if let templateID = session.templateID,
               let index = state.training.templates.firstIndex(where: { $0.id == templateID }),
               !state.training.templates.isEmpty {
                state.training.rotationIndex = (index + 1) % state.training.templates.count
            }
        }
        guard state.training.activeSession == nil else { return -2 }
        WorkoutActivityController.shared.finish(session: session)
        WatchBridge.shared.send(state: state)
        return -1
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
        transact { $0.nutrition.foods.append(food) }
    }

    func logFood(_ food: FoodDefinition, meal: MealSlot, quantity: Double, unit: String, confirmed: Bool) -> Bool {
        guard confirmed, quantity > 0, food.basisAmount > 0 else { return false }
        let factor = quantity / food.basisAmount
        let log = FoodLog(
            foodID: food.id,
            foodName: food.name,
            mealID: meal.id,
            mealName: meal.name,
            date: LocalDay.string(),
            quantity: quantity,
            unit: unit,
            calories: food.calories * factor,
            protein: food.protein * factor,
            carbohydrates: food.carbohydrates * factor,
            fat: food.fat * factor,
            confirmedAt: .now
        )
        transact { $0.nutrition.logs.append(log) }
        return true
    }

    func addMeal(name: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        transact { $0.nutrition.meals.append(MealSlot(name: clean)) }
    }

    func addWater(_ milliliters: Int) {
        guard milliliters > 0 else { return }
        transact { $0.nutrition.water.append(WaterLog(date: LocalDay.string(), milliliters: milliliters)) }
    }

    func deleteFoodLog(_ id: UUID) {
        transact { $0.nutrition.logs.removeAll { $0.id == id } }
    }

    func removeWater(_ id: UUID) {
        transact { $0.nutrition.water.removeAll { $0.id == id } }
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
