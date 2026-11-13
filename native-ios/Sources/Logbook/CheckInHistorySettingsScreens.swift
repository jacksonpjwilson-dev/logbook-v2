import Charts
import SwiftUI
import UniformTypeIdentifiers

private enum CheckInPermanentDeleteKind { case sleep, weight, supplement, supplementDose }
private struct CheckInPermanentDelete: Identifiable {
    let kind: CheckInPermanentDeleteKind
    let id: UUID
}

struct CheckInScreen: View {
    @EnvironmentObject private var store: LogbookStore
    private let initialFocusSection: CheckInSection?
    private let initialSleepID: UUID?
    @State private var selectedDate: Date

    init(initialDate: Date = .now, focusSection: CheckInSection? = nil, sleepID: UUID? = nil) {
        _selectedDate = State(initialValue: Calendar.current.startOfDay(for: initialDate))
        initialFocusSection = focusSection
        initialSleepID = sleepID
    }
    @State private var bedtime = Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: .now) ?? .now
    @State private var wakeTime = Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: .now) ?? .now
    @State private var sleepIsNap = false
    @State private var manualDuration = ""
    @State private var qualityRating = 0
    @State private var editingSleepID: UUID?
    @State private var weight = ""
    @State private var showWeightSaved = false
    @State private var showSleepReplace = false
    @State private var showWeightReplace = false
    @State private var showSupplementEditor = false
    @State private var editingSupplement: Supplement?
    @State private var permanentDelete: CheckInPermanentDelete?

    private var unit: String { store.state.home.preferredWeightUnit }
    private var dateKey: String { LocalDay.string(selectedDate) }
    private var weightForDate: WeightLog? { store.state.checkins.weights.first { $0.deletedAt == nil && $0.date == dateKey } }
    private var activeSleep: [SleepLog] {
        store.state.checkins.sleep.filter { $0.deletedAt == nil && $0.wakeDate == dateKey }.sorted { $0.wakeTime > $1.wakeTime }
    }
    private var activeSupplements: [Supplement] { store.state.checkins.supplements.filter { $0.deletedAt == nil }.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending } }
    private var previousWeight: WeightLog? {
        store.state.checkins.weights.filter { $0.deletedAt == nil && $0.date < dateKey }.max { $0.date < $1.date }
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                Section {
                    DatePicker("Check-in date", selection: $selectedDate, displayedComponents: .date)
                        .accessibilityIdentifier("checkin-date-picker")
                    Text("Sleep, weight and supplement records are saved to the selected local date.")
                        .font(.footnote).foregroundStyle(.secondary)
                }

                Section("Sleep") {
                    Picker("Session type", selection: $sleepIsNap) {
                        Text("Overnight").tag(false)
                        Text("Nap").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("sleep-session-type")
                    DatePicker("Bedtime", selection: $bedtime, displayedComponents: .hourAndMinute)
                    DatePicker("Wake time", selection: $wakeTime, displayedComponents: .hourAndMinute)
                    TextField("Optional duration override (minutes)", text: $manualDuration)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("sleep-duration-override")
                    Picker("Sleep quality", selection: $qualityRating) {
                        Text("Not rated").tag(0)
                        ForEach(1...5, id: \.self) { value in
                            Text(String(repeating: "★", count: value)).tag(value)
                        }
                    }
                    .accessibilityIdentifier("sleep-quality-rating")
                    Button { saveSleep() } label: {
                        Label(editingSleepID == nil ? (sleepIsNap ? "Save nap" : "Save overnight sleep") : "Update sleep", systemImage: "moon.zzz.fill")
                    }
                    .accessibilityIdentifier("sleep-save")
                    .disabled(!sleepInputIsValid)

                    if activeSleep.isEmpty {
                        Text("No sleep logged for this date. Naps add to sleep-hour totals but do not satisfy the overnight Sleep check-in.")
                            .font(.footnote).foregroundStyle(.secondary)
                    } else {
                        ForEach(activeSleep) { record in
                            HStack(spacing: 8) {
                                Button { editSleep(record) } label: {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(record.isNap ? "Nap" : "Overnight sleep").font(.headline)
                                        Text("\(sleepDuration(record.durationMinutes)) · \(record.qualityRating.map { "\($0) of 5 stars" } ?? "not rated") · wakes \(record.wakeTime.formatted(date: .omitted, time: .shortened))")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .accessibilityIdentifier("sleep-edit-\(record.id.uuidString)")
                                Button(role: .destructive) { store.deleteSleep(record.id) } label: {
                                    Image(systemName: "trash")
                                        .frame(width: 44, height: 44)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.borderless)
                                .frame(width: 44, height: 44)
                                .accessibilityLabel("Delete \(record.isNap ? "nap" : "overnight sleep")")
                                .accessibilityIdentifier("sleep-delete-\(record.id.uuidString)")
                            }
                            .id("sleep-row-\(record.id.uuidString)")
                        }
                    }
                    Text("Sleep is entered manually. Apple Health access remains disabled.").font(.footnote).foregroundStyle(.secondary)
                }
                .id(CheckInSection.sleep)

                Section("Weight") {
                    HStack {
                        TextField("Weight", text: $weight).keyboardType(.decimalPad).accessibilityIdentifier("checkin-weight-value")
                        Text(unit).foregroundStyle(.secondary)
                    }
                    Button { saveWeight() } label: {
                        Label(weightForDate == nil ? "Save weight for this date" : "Replace weight for this date", systemImage: "scalemass.fill")
                    }
                    .accessibilityIdentifier("weight-save")
                    .disabled((Double(weight) ?? 0) <= 0)
                    if let saved = weightForDate {
                        LabeledContent("Saved measurement", value: "\(displayWeight(saved.kilograms)) \(unit)")
                            .accessibilityIdentifier("weight-current-value")
                        if let previousWeight {
                            let difference = displayWeight(saved.kilograms - previousWeight.kilograms)
                            LabeledContent("Change from \(previousWeight.date)", value: "\(difference) \(unit)")
                        }
                        Button(role: .destructive) { store.deleteWeight(saved.id) } label: {
                            Label("Delete this weight entry", systemImage: "trash")
                        }
                        .accessibilityIdentifier("weight-delete-current")
                    } else if let previousWeight {
                        Text("Previous entry: \(displayWeight(previousWeight.kilograms)) \(unit) · \(previousWeight.date)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .id(CheckInSection.weight)

                Section {
                    if activeSupplements.isEmpty {
                        Text("Add supplements you want to track. Only scheduled doses count toward today’s Habits check-in.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    ForEach(activeSupplements) { supplement in
                        let dose = store.state.checkins.doses.first { $0.supplementID == supplement.id && $0.date == dateKey && $0.deletedAt == nil }
                        let due = isScheduled(supplement, on: selectedDate)
                        HStack(spacing: 8) {
                            Button {
                                editingSupplement = supplement
                                showSupplementEditor = true
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(supplement.name).font(.headline)
                                    Text([supplement.doseDescription, scheduleDescription(supplement), due ? (dose?.taken == true ? "Taken" : "Not taken") : "Not scheduled"].compactMap { $0 }.joined(separator: " · "))
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("supplement-edit-\(supplement.id.uuidString)")
                            Button {
                                store.markSupplement(supplement, taken: dose?.taken != true, on: selectedDate)
                            } label: {
                                Image(systemName: dose?.taken == true ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 25)).foregroundStyle(dose?.taken == true ? Color.green : Color.secondary)
                            }
                            .buttonStyle(.plain)
                            .disabled(!due)
                            .accessibilityLabel(dose?.taken == true ? "Undo \(supplement.name)" : "Mark \(supplement.name) taken")
                            .accessibilityIdentifier("supplement-taken-\(supplement.id.uuidString)")
                        }
                        .swipeActions {
                            Button(role: .destructive) { store.deleteSupplement(supplement.id) } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                    Button {
                        editingSupplement = nil
                        showSupplementEditor = true
                    } label: { Label("Add supplement", systemImage: "plus") }
                    .accessibilityIdentifier("supplement-add")
                } header: { Text("Supplements") }
                .id(CheckInSection.supplements)

                let deleted = store.recentlyDeletedCheckIns()
                Section("Recently Deleted · 30 days") {
                    if deleted.sleep.isEmpty && deleted.weights.isEmpty && deleted.supplements.isEmpty && deleted.doses.isEmpty {
                        Text("Sleep, weight, supplements and individual doses can be restored here for 30 days.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    ForEach(deleted.sleep) { record in
                        HStack {
                            Text("\(record.isNap ? "Nap" : "Sleep") · \(record.wakeDate)")
                            Spacer()
                            Button("Restore") { restoreSleep(record, using: proxy) }
                                .accessibilityIdentifier("restore-sleep-\(record.id.uuidString)")
                            Button(role: .destructive) {
                                permanentDelete = CheckInPermanentDelete(kind: .sleep, id: record.id)
                            } label: {
                                Label("Delete Permanently", systemImage: "trash")
                            }
                            .accessibilityLabel("Delete Permanently")
                            .accessibilityIdentifier("permanently-delete-sleep-\(record.id.uuidString)")
                        }
                    }
                    ForEach(deleted.weights) { record in
                        HStack {
                            Text("Weight · \(record.date)")
                            Spacer()
                            Button("Restore") { restoreWeight(record, using: proxy) }
                                .accessibilityIdentifier("restore-weight-\(record.id.uuidString)")
                            Button(role: .destructive) {
                                permanentDelete = CheckInPermanentDelete(kind: .weight, id: record.id)
                            } label: {
                                Label("Delete Permanently", systemImage: "trash")
                            }
                            .accessibilityLabel("Delete Permanently")
                            .accessibilityIdentifier("permanently-delete-weight-\(record.id.uuidString)")
                        }
                    }
                    ForEach(deleted.supplements) { record in
                        HStack {
                            Text("Supplement · \(record.name)")
                            Spacer()
                            Button("Restore") { restoreSupplement(record, using: proxy) }
                                .accessibilityIdentifier("restore-supplement-\(record.id.uuidString)")
                            Button(role: .destructive) {
                                permanentDelete = CheckInPermanentDelete(kind: .supplement, id: record.id)
                            } label: {
                                Label("Delete Permanently", systemImage: "trash")
                            }
                            .accessibilityLabel("Delete Permanently")
                            .accessibilityIdentifier("permanently-delete-supplement-\(record.id.uuidString)")
                        }
                    }
                    ForEach(deleted.doses) { dose in
                        HStack {
                            Text("\(dose.supplementName) dose · \(dose.date)")
                            Spacer()
                            Button("Restore") { _ = store.restoreDeletedSupplementDose(dose.id) }
                                .accessibilityIdentifier("restore-supplement-dose-\(dose.id.uuidString)")
                            Button(role: .destructive) {
                                permanentDelete = CheckInPermanentDelete(kind: .supplementDose, id: dose.id)
                            } label: {
                                Label("Delete Permanently", systemImage: "trash")
                            }
                            .accessibilityLabel("Delete Permanently")
                            .accessibilityIdentifier("permanently-delete-supplement-dose-\(dose.id.uuidString)")
                        }
                    }
                }

                Section {
                    NavigationLink("Reminder settings", destination: ReminderSettingsScreen())
                        .font(.footnote)
                    Text("Reminder times are optional and use local notifications. They are not guaranteed during Focus or when iOS limits delivery.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .onAppear {
                loadWeightForSelectedDate()
                if let initialSleepID, let record = store.state.checkins.sleep.first(where: { $0.id == initialSleepID && $0.deletedAt == nil }) {
                    editSleep(record)
                }
                if let initialFocusSection { scroll(to: initialFocusSection, using: proxy) }
                else { scrollToRequestedSection(using: proxy) }
            }
            .onChange(of: selectedDate) { _, _ in loadWeightForSelectedDate() }
            .onChange(of: store.focusedCheckInSection) { _, _ in scrollToRequestedSection(using: proxy) }
        }
        .navigationTitle("Sleep & Check-ins")
        .alert("Weight saved", isPresented: $showWeightSaved) { Button("OK", role: .cancel) { } }
        .sheet(isPresented: $showSupplementEditor) {
            SupplementEditorScreen(supplement: editingSupplement) { value in
                if editingSupplement == nil {
                    store.addSupplement(name: value.name, doseDescription: value.doseDescription, schedule: value.schedule, weekdays: value.weekdays)
                } else {
                    store.updateSupplement(value)
                }
            }
            .environmentObject(store)
        }
        .confirmationDialog("Replace the overnight sleep record for \(dateKey)?", isPresented: $showSleepReplace, titleVisibility: .visible) {
            Button("Replace overnight sleep", role: .destructive) { _ = persistSleep(confirmedReplace: true) }
            Button("Keep existing record", role: .cancel) { }
        } message: { Text("The prior main sleep entry is moved to Recently Deleted; naps remain separate.") }
        .confirmationDialog("Replace the weight record for \(dateKey)?", isPresented: $showWeightReplace, titleVisibility: .visible) {
            Button("Replace weight", role: .destructive) {
                if store.addWeight(Double(weight) ?? 0, unit: unit, date: selectedDate, confirmedReplace: true) {
                    weight = ""
                    showWeightSaved = true
                }
            }
            Button("Keep existing record", role: .cancel) { }
        } message: { Text("The previous daily measurement is moved to Recently Deleted.") }
        .confirmationDialog("Permanently delete this check-in?", isPresented: Binding(
            get: { permanentDelete != nil },
            set: { if !$0 { permanentDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete Permanently", role: .destructive) {
                guard let selection = permanentDelete else { return }
                switch selection.kind {
                case .sleep: store.permanentlyDeleteSleep(selection.id)
                case .weight: store.permanentlyDeleteWeight(selection.id)
                case .supplement: store.permanentlyDeleteSupplement(selection.id)
                case .supplementDose: store.permanentlyDeleteSupplementDose(selection.id)
                }
                permanentDelete = nil
            }
            Button("Cancel", role: .cancel) { permanentDelete = nil }
        } message: { Text("This cannot be undone.") }
    }

    private var sleepInputIsValid: Bool {
        guard sleepWakeTime > sleepBedtime else { return false }
        guard !manualDuration.isEmpty else { return true }
        guard let minutes = Int(manualDuration), minutes > 0 else { return false }
        return true
    }

    private var sleepWakeTime: Date {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: selectedDate)
        return calendar.date(
            bySettingHour: calendar.component(.hour, from: wakeTime),
            minute: calendar.component(.minute, from: wakeTime),
            second: 0,
            of: day
        ) ?? wakeTime
    }

    private var sleepBedtime: Date {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: selectedDate)
        let bedHour = calendar.component(.hour, from: bedtime)
        let bedMinute = calendar.component(.minute, from: bedtime)
        let wakeHour = calendar.component(.hour, from: wakeTime)
        let wakeMinute = calendar.component(.minute, from: wakeTime)
        let crossesMidnight = bedHour * 60 + bedMinute >= wakeHour * 60 + wakeMinute
        let bedDay = crossesMidnight ? (calendar.date(byAdding: .day, value: -1, to: day) ?? day) : day
        return calendar.date(bySettingHour: bedHour, minute: bedMinute, second: 0, of: bedDay) ?? bedtime
    }

    private func editSleep(_ record: SleepLog) {
        editingSleepID = record.id
        selectedDate = LocalDay.formatter.date(from: record.wakeDate) ?? selectedDate
        bedtime = record.bedtime
        wakeTime = record.wakeTime
        sleepIsNap = record.isNap
        manualDuration = record.manualMinutes.map(String.init) ?? ""
        qualityRating = record.qualityRating ?? 0
    }

    private func persistSleep(confirmedReplace: Bool = false) -> Bool {
        let manual = manualDuration.isEmpty ? nil : Int(manualDuration)
        let quality = qualityRating == 0 ? nil : qualityRating
        if let editingSleepID {
            let updated = store.updateSleep(editingSleepID, bedtime: sleepBedtime, wakeTime: sleepWakeTime, manualMinutes: manual, isNap: sleepIsNap, qualityRating: quality)
            if updated { self.editingSleepID = nil }
            return updated
        }
        return store.addSleep(bedtime: sleepBedtime, wakeTime: sleepWakeTime, manualMinutes: manual, isNap: sleepIsNap, qualityRating: quality, confirmedReplace: confirmedReplace)
    }

    private func saveSleep() {
        if editingSleepID != nil {
            _ = persistSleep()
            manualDuration = ""
            qualityRating = 0
        } else if !sleepIsNap && activeSleep.contains(where: { !$0.isNap }) {
            showSleepReplace = true
        } else if persistSleep() {
            manualDuration = ""
            qualityRating = 0
        }
    }

    private func loadWeightForSelectedDate() {
        weight = weightForDate.map { displayWeight($0.kilograms) } ?? ""
    }

    private func saveWeight() {
        guard let value = Double(weight), value.isFinite, value > 0 else { return }
        if weightForDate != nil { showWeightReplace = true }
        else if store.addWeight(value, unit: unit, date: selectedDate) { weight = ""; showWeightSaved = true }
    }

    private func isScheduled(_ supplement: Supplement, on date: Date) -> Bool {
        supplement.schedule.lowercased() == "daily" || supplement.weekdays.contains(Calendar.current.component(.weekday, from: date))
    }

    private func scheduleDescription(_ supplement: Supplement) -> String {
        supplement.schedule.lowercased() == "daily" ? "Daily" : supplement.weekdays.sorted().map { Calendar.current.shortWeekdaySymbols[$0 - 1] }.joined(separator: ", ")
    }

    private func restoreSleep(_ record: SleepLog, using proxy: ScrollViewProxy) {
        guard store.restoreDeletedSleep(record.id) else { return }
        if let restoredDate = date(from: record.wakeDate) { selectedDate = restoredDate }
        // Return to the restored record itself so its edit and delete controls
        // are immediately visible, including on compact screens.
        let rowID = "sleep-row-\(record.id.uuidString)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.2)) { proxy.scrollTo(rowID, anchor: .center) }
        }
    }

    private func restoreWeight(_ record: WeightLog, using proxy: ScrollViewProxy) {
        guard store.restoreDeletedWeight(record.id) else { return }
        if let restoredDate = date(from: record.date) { selectedDate = restoredDate }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.2)) { proxy.scrollTo(CheckInSection.weight, anchor: .top) }
        }
    }

    private func restoreSupplement(_ record: Supplement, using proxy: ScrollViewProxy) {
        guard store.restoreDeletedSupplement(record.id) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.2)) { proxy.scrollTo(CheckInSection.supplements, anchor: .top) }
        }
    }

    private func date(from key: String) -> Date? {
        let values = key.split(separator: "-").compactMap { Int($0) }
        guard values.count == 3 else { return nil }
        return Calendar.current.date(from: DateComponents(year: values[0], month: values[1], day: values[2]))
    }

    private func scrollToRequestedSection(using proxy: ScrollViewProxy) {
        guard let section = store.focusedCheckInSection else { return }
        scroll(to: section, using: proxy)
        store.clearCheckInFocus()
    }

    private func scroll(to section: CheckInSection, using proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.2)) { proxy.scrollTo(section, anchor: .top) }
        }
    }

    private func sleepDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours == 0 { return "\(remainder) min" }
        if remainder == 0 { return "\(hours) hr" }
        return "\(hours) hr \(remainder) min"
    }

    private func displayWeight(_ kg: Double) -> String {
        let value = unit == "lb" ? kg * 2.2046226218 : kg
        return value.formatted(.number.precision(.fractionLength(1)))
    }
}

private struct SupplementEditorScreen: View {
    @Environment(\.dismiss) private var dismiss
    let initial: Supplement?
    let onSave: (Supplement) -> Void
    @State private var name: String
    @State private var dose: String
    @State private var daily: Bool
    @State private var weekdays: Set<Int>

    init(supplement: Supplement?, onSave: @escaping (Supplement) -> Void) {
        initial = supplement
        self.onSave = onSave
        _name = State(initialValue: supplement?.name ?? "")
        _dose = State(initialValue: supplement?.doseDescription ?? "")
        _daily = State(initialValue: supplement?.schedule.lowercased() != "weekdays")
        _weekdays = State(initialValue: Set(supplement?.weekdays ?? []))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Supplement") {
                    TextField("Name", text: $name).accessibilityIdentifier("supplement-name")
                    TextField("Optional dose", text: $dose).accessibilityIdentifier("supplement-dose")
                }
                Section("Schedule") {
                    Picker("Repeat", selection: $daily) {
                        Text("Every day").tag(true)
                        Text("Selected days").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("supplement-schedule-mode")
                    if !daily {
                        ForEach(1...7, id: \.self) { day in
                            Toggle(Calendar.current.shortWeekdaySymbols[day - 1], isOn: Binding(
                                get: { weekdays.contains(day) },
                                set: { selected in
                                    if selected { weekdays.insert(day) } else { weekdays.remove(day) }
                                }
                            ))
                        }
                    }
                }
            }
            .navigationTitle(initial == nil ? "Add supplement" : "Edit supplement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var value = initial ?? Supplement(name: name)
                        value.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        value.doseDescription = dose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : dose
                        value.schedule = daily ? "daily" : "weekdays"
                        value.weekdays = daily ? [] : weekdays.sorted()
                        onSave(value)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (!daily && weekdays.isEmpty))
                    .accessibilityIdentifier("supplement-editor-save")
                }
            }
        }
    }
}

struct HistoryScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @State private var range = 30
    @State private var showingWorkoutCalendar = false
    @State private var workoutToDeletePermanently: UUID?
    @State private var selectedHistoryDate: String?
    @State private var selectedStrengthExerciseID = ""
    private let explicitInitialDate: String?

    init(initialDate: String? = nil) {
        explicitInitialDate = initialDate
        _selectedHistoryDate = State(initialValue: initialDate)
    }
    private let ranges = [7, 30, 90]
    private var cutoff: String {
        LocalDay.string(Calendar.current.date(byAdding: .day, value: -range + 1, to: .now) ?? .now)
    }
    private var weights: [WeightLog] { store.state.checkins.weights.filter { $0.deletedAt == nil && $0.date >= cutoff }.sorted { $0.date < $1.date } }
    private var sleepByDate: [DailyHistoryPoint] {
        Dictionary(grouping: store.state.checkins.sleep.filter { $0.deletedAt == nil && $0.wakeDate >= cutoff }, by: \.wakeDate)
            .map { date, logs in DailyHistoryPoint(date: date, value: Double(logs.reduce(0) { $0 + $1.durationMinutes }) / 60) }
            .sorted { $0.date < $1.date }
    }
    private var caloriesByDate: [DailyHistoryPoint] {
        NutritionHistorySeries.calories(from: store.state.nutrition.logs, since: cutoff)
    }
    private var sessions: [WorkoutSession] { store.state.training.visibleCompletedSessions.sorted { $0.startedAt > $1.startedAt } }
    private var strengthOptions: [HistoryExerciseOption] {
        var names: [String: String] = [:]
        for session in sessions {
            for exercise in session.exercises where (exercise.trackingMode ?? .weightAndReps) == .weightAndReps {
                names[exercise.exerciseID] = exercise.name
            }
        }
        return names.keys.sorted { (names[$0] ?? $0) < (names[$1] ?? $1) }
            .map { HistoryExerciseOption(id: $0, name: names[$0] ?? $0) }
    }
    private var strengthByDate: [DailyHistoryPoint] {
        StrengthHistorySeries.points(from: sessions, exerciseID: selectedStrengthExerciseID, since: cutoff)
    }
    private var proteinByDate: [DailyHistoryPoint] {
        NutritionHistorySeries.protein(from: store.state.nutrition.logs, since: cutoff)
    }

    private func scrollToSelectedDate(using proxy: ScrollViewProxy) {
        guard selectedHistoryDate != nil else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.2)) { proxy.scrollTo("history-selected-day-scroll-target", anchor: .top) }
        }
    }

    private func consumeFocusedDate(using proxy: ScrollViewProxy) {
        guard let date = store.focusedHistoryDate else { return }
        store.consumeHistoryDateFocus()
        // A date passed directly from a History calendar/widget is authoritative;
        // a stale focus request from another screen must not replace it.
        guard explicitInitialDate == nil else { return }
        selectedHistoryDate = date
        scrollToSelectedDate(using: proxy)
    }

    var body: some View {
        ScrollViewReader { proxy in
        List {
            Section("Category histories") {
                NavigationLink("Training", destination: WorkoutCalendarScreen())
                    .accessibilityIdentifier("history-category-training")
                NavigationLink("Nutrition", destination: FoodHistoryScreen())
                    .accessibilityIdentifier("history-category-nutrition")
                NavigationLink("Weight", destination: CheckInCategoryHistoryScreen(category: .weight))
                    .accessibilityIdentifier("history-category-weight")
                NavigationLink("Sleep", destination: CheckInCategoryHistoryScreen(category: .sleep))
                    .accessibilityIdentifier("history-category-sleep")
                NavigationLink("Supplements", destination: CheckInCategoryHistoryScreen(category: .supplements))
                    .accessibilityIdentifier("history-category-supplements")
                NavigationLink("Habits", destination: CheckInCategoryHistoryScreen(category: .habits))
                    .accessibilityIdentifier("history-category-habits")
            }
            if let date = selectedHistoryDate {
                Section {
                    Text(date).font(.caption).foregroundStyle(.secondary)
                        .accessibilityIdentifier("history-selected-day-date")
                        .id("history-selected-day-scroll-target")
                    let nutrition = store.state.nutritionTotals(on: date)
                    let sleepMinutes = store.state.checkins.sleep.filter { $0.deletedAt == nil && $0.wakeDate == date }.reduce(0) { $0 + $1.durationMinutes }
                    let activeSessions = sessions.filter { $0.localDate == date }
                    LabeledContent("Food entries", value: "\(store.state.nutrition.logs.filter { $0.deletedAt == nil && $0.date == date }.count)")
                    LabeledContent("Nutrition", value: "\(Int(nutrition.calories ?? 0)) kcal · \(Int(nutrition.protein ?? 0)) g protein")
                    LabeledContent("Sleep", value: sleepMinutes == 0 ? "No record" : "\((Double(sleepMinutes) / 60).formatted(.number.precision(.fractionLength(1)))) h")
                    LabeledContent("Workouts", value: "\(activeSessions.count)")
                    if let weight = store.state.checkins.weights.first(where: { $0.deletedAt == nil && $0.date == date }) {
                        LabeledContent("Weight", value: "\(displayedWeight(weight.kilograms).formatted(.number.precision(.fractionLength(1)))) \(store.state.home.preferredWeightUnit)")
                    } else {
                        LabeledContent("Weight", value: "No record")
                    }
                    ForEach(activeSessions) { session in
                        NavigationLink(session.templateName, destination: WorkoutHistoryDetailScreen(sessionID: session.id))
                    }
                    Button("Close selected day") { selectedHistoryDate = nil }
                        .accessibilityIdentifier("history-close-selected-day")
                }

            }
            Section {
                Picker("Range", selection: $range) { ForEach(ranges, id: \.self) { Text("\($0) days").tag($0) } }
                    .pickerStyle(.segmented)
                if weights.isEmpty { ContentUnavailableView("No weight records", systemImage: "scalemass", description: Text("Log a weight check-in to start this chart.")) }
                else {
                    Chart(weights) { point in
                        LineMark(x: .value("Date", point.date), y: .value("Weight", displayedWeight(point.kilograms)))
                            .interpolationMethod(.catmullRom).foregroundStyle(store.state.home.theme.palette.accentColor)
                        PointMark(x: .value("Date", point.date), y: .value("Weight", displayedWeight(point.kilograms)))
                            .foregroundStyle(store.state.home.theme.palette.accentColor)
                    }
                    .frame(height: 180)
                    .chartYAxisLabel("\(store.state.home.preferredWeightUnit)")
                }
            } header: { Text("Body") }

            Section("Nutrition") {
                if caloriesByDate.isEmpty { Text("Calories appear on days with logged food. Missing days are left blank.").font(.footnote).foregroundStyle(.secondary) }
                else {
                    Chart(caloriesByDate) { point in
                        BarMark(x: .value("Date", point.date), y: .value("Calories", point.value))
                            .foregroundStyle(store.state.home.theme.palette.accentColor.gradient)
                    }
                    .frame(height: 170)
                    ForEach(caloriesByDate.suffix(7)) { point in LabeledContent(point.date, value: "\(Int(point.value)) kcal") }
                }
                if proteinByDate.isEmpty {
                    Text("Protein appears on days with logged food.").font(.footnote).foregroundStyle(.secondary)
                } else {
                    Chart(proteinByDate) { point in
                        BarMark(x: .value("Date", point.date), y: .value("Protein", point.value))
                            .foregroundStyle(store.state.home.theme.palette.accentColor.gradient)
                    }
                    .frame(height: 150)
                    .chartYAxisLabel("g protein")
                    .accessibilityIdentifier("history-protein-chart")
                }
            }

            Section("Training") {
                if !strengthOptions.isEmpty {
                    if strengthOptions.count > 1 {
                        Picker("Strength exercise", selection: $selectedStrengthExerciseID) {
                            ForEach(strengthOptions) { option in Text(option.name).tag(option.id) }
                        }
                        .accessibilityIdentifier("history-strength-exercise")
                    }
                    if strengthByDate.isEmpty {
                        Text("Complete compatible weighted sets to build this exercise’s estimated 1RM trend.")
                            .font(.footnote).foregroundStyle(.secondary)
                    } else {
                        Chart(strengthByDate) { point in
                            LineMark(x: .value("Date", point.date), y: .value("Estimated 1RM", point.value))
                                .interpolationMethod(.catmullRom).foregroundStyle(store.state.home.theme.palette.accentColor)
                            PointMark(x: .value("Date", point.date), y: .value("Estimated 1RM", point.value))
                                .foregroundStyle(store.state.home.theme.palette.accentColor)
                        }
                        .frame(height: 150)
                        .chartYAxisLabel("kg · estimated 1RM")
                        .accessibilityIdentifier("history-strength-chart")
                    }
                } else {
                    Text("Strength trends appear after a completed weighted exercise.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if sessions.isEmpty { Text("Completed workouts appear here; unfinished sessions are not counted.").foregroundStyle(.secondary) }
                ForEach(sessions) { session in
                    NavigationLink(destination: WorkoutHistoryDetailScreen(sessionID: session.id)) {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack { Text(session.templateName).font(.headline); Spacer(); Text(session.localDate).font(.caption).foregroundStyle(.secondary) }
                            let complete = session.exercises.flatMap(\.sets).filter(\.completed)
                            Text("\(complete.count) sets · \(Int(complete.reduce(0.0) { $0 + ($1.weightKg ?? 0) * Double($1.reps) })) kg volume")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("history-workout-\(session.id.uuidString)")
                    .accessibilityLabel("\(session.templateName), \(session.localDate)")
                }
                Button { showingWorkoutCalendar = true } label: { Label("Workout Calendar", systemImage: "calendar") }
                    .accessibilityIdentifier("workout-calendar-open")
            }

            Section("Personal records") {
                let records = store.state.training.personalRecordEvents.filter {
                    Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month)
                }.sorted { $0.date > $1.date }
                if records.isEmpty {
                    Text("No new estimated 1RM records this month. Your first completed workout establishes an exercise baseline.")
                        .font(.footnote).foregroundStyle(.secondary)
                } else {
                    ForEach(records) { record in
                        NavigationLink(destination: WorkoutHistoryDetailScreen(sessionID: record.sessionID)) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(record.exerciseName).font(.headline)
                                Text("Estimated 1RM \(record.estimatedOneRepMaxKg.formatted(.number.precision(.fractionLength(1)))) kg · \(record.date.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityIdentifier("history-pr-\(record.sessionID.uuidString)-\(record.exerciseID)")
                    }
                }
            }

            Section("Recently Deleted") {
                let deleted = store.state.training.recentlyDeletedSessions()
                if deleted.isEmpty { Text("Deleted workouts can be restored for 30 days.").font(.footnote).foregroundStyle(.secondary) }
                ForEach(deleted) { session in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(session.templateName).font(.headline)
                            Text("Deleted \((session.deletedAt ?? .now).formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Restore") { _ = store.restoreDeletedWorkout(session.id) }
                            .buttonStyle(.bordered).controlSize(.small)
                            .accessibilityIdentifier("restore-deleted-workout-\(session.id.uuidString)")
                        Button(role: .destructive) { workoutToDeletePermanently = session.id } label: {
                            Image(systemName: "trash").accessibilityLabel("Delete permanently")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            Section("Sleep") {
                if sleepByDate.isEmpty {
                    Text("Sleep charts use recorded check-ins only.").foregroundStyle(.secondary)
                } else {
                    Chart(sleepByDate) { point in
                        LineMark(x: .value("Date", point.date), y: .value("Hours", point.value))
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(store.state.home.theme.palette.accentColor)
                        PointMark(x: .value("Date", point.date), y: .value("Hours", point.value))
                            .foregroundStyle(store.state.home.theme.palette.accentColor)
                    }
                    .frame(height: 170)
                    .chartYAxisLabel("hours · includes naps")
                    ForEach(sleepByDate.suffix(7)) { point in
                        LabeledContent(point.date, value: "\(point.value.formatted(.number.precision(.fractionLength(1)))) hours")
                    }
                }
            }
        }
        .onAppear {
            consumeFocusedDate(using: proxy)
            scrollToSelectedDate(using: proxy)
            if selectedStrengthExerciseID.isEmpty { selectedStrengthExerciseID = strengthOptions.first?.id ?? "" }
        }
        .onChange(of: store.focusedHistoryDate) { _, _ in consumeFocusedDate(using: proxy) }
        .onChange(of: selectedHistoryDate) { _, date in
            guard date != nil else { return }
            scrollToSelectedDate(using: proxy)
        }
        }
        .navigationTitle("History")
        .toolbar { ToolbarItem(placement: .topBarTrailing) {
            Button { showingWorkoutCalendar = true } label: { Image(systemName: "calendar") }
                .accessibilityLabel("Workout Calendar")
        } }
        .sheet(isPresented: $showingWorkoutCalendar) {
            WorkoutCalendarScreen().presentationDetents([.large]).presentationDragIndicator(.visible)
        }
        .confirmationDialog("Delete this workout permanently?", isPresented: Binding(
            get: { workoutToDeletePermanently != nil },
            set: { if !$0 { workoutToDeletePermanently = nil } }
        ), titleVisibility: .visible) {
            Button("Delete Permanently", role: .destructive) {
                if let workoutToDeletePermanently { store.permanentlyDeleteWorkout(workoutToDeletePermanently) }
                workoutToDeletePermanently = nil
            }
            Button("Cancel", role: .cancel) { workoutToDeletePermanently = nil }
        } message: { Text("This cannot be undone. Otherwise Logbook removes deleted workouts automatically after 30 days.") }
    }

    private func displayedWeight(_ kg: Double) -> Double { store.state.home.preferredWeightUnit == "lb" ? kg * 2.2046226218 : kg }
}

private enum CheckInHistoryCategory: String {
    case sleep, weight, supplements, habits
    var title: String { rawValue.capitalized }
}

private struct CheckInCategoryHistoryScreen: View {
    @EnvironmentObject private var store: LogbookStore
    let category: CheckInHistoryCategory

    private var sleepRecords: [SleepLog] {
        store.state.checkins.sleep.filter { $0.deletedAt == nil }.sorted { ($0.wakeDate, $0.wakeTime) > ($1.wakeDate, $1.wakeTime) }
    }
    private var weightRecords: [WeightLog] {
        store.state.checkins.weights.filter { $0.deletedAt == nil }.sorted { $0.date > $1.date }
    }
    private var supplementRecords: [SupplementDose] {
        store.state.checkins.doses.filter { $0.deletedAt == nil }.sorted { ($0.date, $0.supplementName) > ($1.date, $1.supplementName) }
    }
    private var deletedSupplementDoses: [SupplementDose] { store.recentlyDeletedCheckIns().doses }
    @State private var doseToDeletePermanently: UUID?
    private var habitDates: [String] {
        Set(sleepRecords.map(\.wakeDate) + weightRecords.map(\.date) + supplementRecords.map(\.date)).sorted(by: >)
    }

    var body: some View {
        List {
            switch category {
            case .sleep:
                Section("Sleep records") {
                    if sleepRecords.isEmpty { ContentUnavailableView("No sleep history", systemImage: "moon.zzz", description: Text("Recorded overnight sleep and naps appear here.")) }
                    ForEach(sleepRecords) { record in
                        if let date = LocalDay.formatter.date(from: record.wakeDate) {
                            NavigationLink(destination: CheckInScreen(initialDate: date, focusSection: .sleep, sleepID: record.id)) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(record.isNap ? "Nap" : "Overnight sleep").font(.headline)
                                    let quality = record.qualityRating.map { "\($0)/5 stars" } ?? "not rated"
                                    Text("\(record.wakeDate) · \(record.durationMinutes) min · \(quality)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .accessibilityIdentifier("history-sleep-\(record.id.uuidString)")
                            .swipeActions { Button("Delete", role: .destructive) { store.deleteSleep(record.id) } }
                        }
                    }
                }
            case .weight:
                Section("Weight records") {
                    if weightRecords.isEmpty { ContentUnavailableView("No weight history", systemImage: "scalemass", description: Text("Daily weight entries appear here.")) }
                    ForEach(weightRecords) { record in
                        if let date = LocalDay.formatter.date(from: record.date) {
                            NavigationLink(destination: CheckInScreen(initialDate: date, focusSection: .weight)) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\(record.date) · \(displayedWeight(record.kilograms)) \(store.state.home.preferredWeightUnit)")
                                    Text("Tap to inspect or edit this measurement").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .accessibilityIdentifier("history-weight-\(record.id.uuidString)")
                            .swipeActions { Button("Delete", role: .destructive) { store.deleteWeight(record.id) } }
                        }
                    }
                }
            case .supplements:
                Section("Supplement dose history") {
                    if supplementRecords.isEmpty { ContentUnavailableView("No supplement history", systemImage: "pills", description: Text("Taken and undone doses appear here.")) }
                    ForEach(supplementRecords) { record in
                        if let date = LocalDay.formatter.date(from: record.date) {
                            NavigationLink(destination: CheckInScreen(initialDate: date, focusSection: .supplements)) {
                                LabeledContent(record.supplementName, value: "\(record.date) · \(record.taken ? "Taken" : "Not taken")")
                            }
                            .accessibilityIdentifier("history-supplement-\(record.id.uuidString)")
                            .swipeActions { Button("Delete", role: .destructive) { store.deleteSupplementDose(record.id) } }
                        }
                    }
                }
                Section("Recently Deleted doses") {
                    if deletedSupplementDoses.isEmpty { Text("Deleted supplement doses can be restored for 30 days.").font(.footnote).foregroundStyle(.secondary) }
                    ForEach(deletedSupplementDoses) { dose in
                        HStack {
                            Text("\(dose.supplementName) · \(dose.date)")
                            Spacer()
                            Button("Restore") { _ = store.restoreDeletedSupplementDose(dose.id) }
                                .accessibilityIdentifier("restore-history-supplement-dose-\(dose.id.uuidString)")
                            Button(role: .destructive) { doseToDeletePermanently = dose.id } label: {
                                Image(systemName: "trash").accessibilityLabel("Delete permanently")
                            }
                        }
                    }
                }
            case .habits:
                Section("Daily completion history") {
                    if habitDates.isEmpty { ContentUnavailableView("No habit history", systemImage: "checkmark.circle", description: Text("Sleep, weight and scheduled supplement check-ins appear here.")) }
                    ForEach(habitDates, id: \.self) { key in
                        if let date = LocalDay.formatter.date(from: key) {
                            let metrics = DailyHomeMetrics(state: store.state, date: date)
                            NavigationLink(destination: CheckInScreen(initialDate: date, focusSection: .sleep)) {
                                LabeledContent(key, value: "\(metrics.completedCount)/\(metrics.eligibleCount) · streak \(metrics.perfectDayStreak)")
                            }
                            .accessibilityIdentifier("history-habit-day-\(key)")
                        }
                    }
                }
            }
            Section {
                NavigationLink("Manage Recently Deleted", destination: CheckInScreen())
                    .accessibilityIdentifier("checkin-history-recently-deleted")
            } footer: { Text("Deleted check-ins remain recoverable for 30 days from Sleep & Check-ins.") }
        }
        .navigationTitle("\(category.title) History")
        .confirmationDialog("Permanently delete this supplement dose?", isPresented: Binding(
            get: { doseToDeletePermanently != nil },
            set: { if !$0 { doseToDeletePermanently = nil } }
        ), titleVisibility: .visible) {
            Button("Delete Permanently", role: .destructive) {
                if let doseToDeletePermanently { store.permanentlyDeleteSupplementDose(doseToDeletePermanently) }
                doseToDeletePermanently = nil
            }
            Button("Cancel", role: .cancel) { doseToDeletePermanently = nil }
        } message: { Text("This cannot be undone.") }
    }

    private func displayedWeight(_ kilograms: Double) -> String {
        let value = store.state.home.preferredWeightUnit == "lb" ? kilograms * 2.2046226218 : kilograms
        return value.formatted(.number.precision(.fractionLength(1)))
    }
}

private struct WorkoutHistoryDetailScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    let sessionID: UUID
    var onCalendarBack: (() -> Void)? = nil
    @State private var confirmDelete = false

    private var session: WorkoutSession? { store.state.training.visibleCompletedSessions.first { $0.id == sessionID } }

    var body: some View {
        Group {
            if let session {
                List {
                    Section("Workout") {
                        LabeledContent("Date", value: session.startedAt.formatted(date: .complete, time: .shortened))
                        LabeledContent("Duration", value: duration(session))
                        LabeledContent("Sets", value: "\(session.exercises.flatMap(\.sets).filter(\.completed).count) / \(session.exercises.flatMap(\.sets).count)")
                    }
                    ForEach(session.exercises) { exercise in
                        Section(exercise.name) {
                            ForEach(exercise.sets) { set in
                                HistoryWorkoutSetEditor(session: session, exercise: exercise, set: set)
                            }
                            TextField("Exercise notes", text: Binding(
                                get: { store.state.training.visibleCompletedSessions.first(where: { $0.id == sessionID })?.exercises.first(where: { $0.id == exercise.id })?.notes ?? "" },
                                set: { store.updateCompletedExerciseNotes(sessionID: sessionID, exerciseID: exercise.id, notes: $0) }
                            ), axis: .vertical)
                                .lineLimit(1...4)
                        }
                    }
                    Section("Workout notes") {
                        TextField("Notes", text: Binding(
                            get: { store.state.training.visibleCompletedSessions.first(where: { $0.id == sessionID })?.notes ?? "" },
                            set: { store.updateCompletedWorkoutNotes(sessionID: sessionID, notes: $0) }
                        ), axis: .vertical)
                            .lineLimit(2...5)
                            .accessibilityIdentifier("history-workout-notes")
                    }
                    let records = store.state.training.personalRecordEvents.filter { $0.sessionID == sessionID }
                    if !records.isEmpty {
                        Section("Personal records") {
                            ForEach(records) { record in
                                LabeledContent(record.exerciseName, value: "e1RM \(record.estimatedOneRepMaxKg.formatted(.number.precision(.fractionLength(1)))) kg")
                            }
                        }
                    }
                    Section {
                        Button("Delete workout", role: .destructive) { confirmDelete = true }
                    } footer: { Text("The workout moves to Recently Deleted for 30 days. Training rotation does not change.") }
                }
                .navigationTitle(session.templateName)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(onCalendarBack != nil)
                .toolbar {
                    if let onCalendarBack {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Back", action: onCalendarBack)
                                .accessibilityIdentifier("workout-history-back")
                        }
                    }
                }
                .confirmationDialog("Delete this workout?", isPresented: $confirmDelete, titleVisibility: .visible) {
                    Button("Delete Workout", role: .destructive) {
                        store.deleteCompletedWorkout(sessionID)
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) { }
                }
            } else {
                ContentUnavailableView("Workout unavailable", systemImage: "dumbbell")
            }
        }
    }

    private func duration(_ session: WorkoutSession) -> String {
        guard let finishedAt = session.finishedAt else { return "—" }
        let minutes = max(0, Int(finishedAt.timeIntervalSince(session.startedAt) - session.pausedSeconds) / 60)
        return "\(minutes) min"
    }
}

private struct HistoryWorkoutSetEditor: View {
    @EnvironmentObject private var store: LogbookStore
    let session: WorkoutSession
    let exercise: WorkoutExercise
    let set: WorkoutSet

    var body: some View {
        HStack(spacing: 9) {
            Text("Set \((exercise.sets.firstIndex(of: set) ?? 0) + 1)").font(.caption).frame(width: 45, alignment: .leading)
            switch exercise.trackingMode ?? .weightAndReps {
            case .weightAndReps:
                weightField
                Text("×").foregroundStyle(.secondary)
                repsField
            case .repsOnly:
                repsField
            case .duration:
                TextField("sec", value: Binding(
                    get: { set.durationSeconds ?? 0 },
                    set: { update(weight: nil, reps: set.reps, completed: set.completed, duration: $0 > 0 ? $0 : nil, distance: nil) }
                ), format: .number)
                    .keyboardType(.numberPad).textFieldStyle(.roundedBorder).accessibilityLabel("Duration in seconds")
            case .weightAndDistance:
                weightField
                TextField("m", value: Binding(
                    get: { set.distanceMeters ?? 0 },
                    set: { update(weight: set.weightKg, reps: set.reps, completed: set.completed, duration: nil, distance: $0 > 0 ? $0 : nil) }
                ), format: .number.precision(.fractionLength(0...1)))
                    .keyboardType(.decimalPad).textFieldStyle(.roundedBorder).accessibilityLabel("Distance in meters")
            }
            Button {
                update(weight: set.weightKg, reps: set.reps, completed: !set.completed, duration: set.durationSeconds, distance: set.distanceMeters)
            } label: { Image(systemName: set.completed ? "checkmark.circle.fill" : "circle").foregroundStyle(set.completed ? .green : .secondary) }
                .buttonStyle(.plain).accessibilityLabel(set.completed ? "Mark set incomplete" : "Mark set complete")
                    .accessibilityIdentifier("history-set-complete")
        }
    }

    private var weightField: some View {
        TextField("kg", value: Binding(
            get: { set.weightKg ?? 0 },
            set: { update(weight: $0 > 0 ? $0 : nil, reps: set.reps, completed: set.completed, duration: nil, distance: set.distanceMeters) }
        ), format: .number.precision(.fractionLength(0...2)))
            .keyboardType(.decimalPad).textFieldStyle(.roundedBorder).accessibilityLabel("Weight in kilograms")
                .accessibilityIdentifier("history-set-weight")
    }

    private var repsField: some View {
        TextField("Reps", value: Binding(
            get: { set.reps },
            set: { update(weight: set.weightKg, reps: $0, completed: set.completed, duration: nil, distance: set.distanceMeters) }
        ), format: .number)
            .keyboardType(.numberPad).textFieldStyle(.roundedBorder).frame(width: 64).accessibilityLabel("Repetitions")
                .accessibilityIdentifier("history-set-reps")
    }

    private func update(weight: Double?, reps: Int, completed: Bool, duration: Int?, distance: Double?) {
        store.updateCompletedWorkoutSet(sessionID: session.id, exerciseID: exercise.id, setID: set.id, weightKg: weight, reps: reps, completed: completed, durationSeconds: duration, distanceMeters: distance)
    }
}

struct WorkoutCalendarScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    @State private var month: Date
    @State private var selectedDate: Date
    @State private var historyPath: [UUID] = []

    init(initialDate: Date = .now) {
        let calendar = Calendar.current
        _month = State(initialValue: calendar.date(from: calendar.dateComponents([.year, .month], from: initialDate)) ?? initialDate)
        _selectedDate = State(initialValue: calendar.startOfDay(for: initialDate))
    }

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private var sessions: [WorkoutSession] { store.state.training.visibleCompletedSessions }

    private var monthDays: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let dayRange = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7
        let days = dayRange.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: interval.start) }
        return Array<Date?>(repeating: nil, count: leading) + days.map(Optional.some)
    }

    private var selectedSessions: [WorkoutSession] {
        sessions.filter { $0.localDate == LocalDay.string(selectedDate) }.sorted { $0.startedAt < $1.startedAt }
    }

    private var monthSessionCount: Int {
        sessions.filter { calendar.isDate($0.startedAt, equalTo: month, toGranularity: .month) }.count
    }

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        let symbols: [String] = formatter.veryShortWeekdaySymbols ?? ["S", "M", "T", "W", "T", "F", "S"]
        guard !symbols.isEmpty else { return [] }
        let offset = max(0, calendar.firstWeekday - 1)
        var ordered: [String] = []
        ordered.reserveCapacity(symbols.count)
        for index in symbols.indices {
            let symbolIndex = (index + offset) % symbols.count
            ordered.append(symbols[symbolIndex])
        }
        return ordered
    }

    var body: some View {
        NavigationStack(path: $historyPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Button { changeMonth(by: -1) } label: { Image(systemName: "chevron.left").frame(width: 36, height: 36) }
                            .accessibilityLabel("Previous month")
                        Spacer()
                        VStack(spacing: 3) {
                            Text(month.formatted(.dateTime.month(.wide).year())).font(.headline)
                                .accessibilityIdentifier("training-calendar-month-label")
                            Text("\(monthSessionCount) workouts completed").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { changeMonth(by: 1) } label: { Image(systemName: "chevron.right").frame(width: 36, height: 36) }
                            .accessibilityLabel("Next month")
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 4)

                    LazyVGrid(columns: columns, spacing: 5) {
                        ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                            Text(symbol.uppercased()).font(.caption2.weight(.semibold)).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                        }
                        ForEach(Array(monthDays.enumerated()), id: \.offset) { _, day in
                            if let day {
                                calendarCell(day)
                            } else {
                                Color.clear.frame(height: 58)
                            }
                        }
                    }

                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedDate.formatted(date: .complete, time: .omitted)).font(.headline)
                        if selectedSessions.isEmpty {
                            Text("No completed workouts on this date.").font(.subheadline).foregroundStyle(.secondary)
                        } else {
                            WorkoutDaySessionSummary(sessions: selectedSessions, weightUnit: store.state.home.preferredWeightUnit)
                            ForEach(selectedSessions) { session in
                                NavigationLink(value: session.id) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(session.templateName).font(.subheadline.weight(.semibold))
                                            Text("\(session.startedAt.formatted(date: .omitted, time: .shortened)) · \(session.exercises.flatMap(\.sets).filter(\.completed).count) completed sets")
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                                    }
                                    .padding(10)
                                    .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
                                }
                                .accessibilityIdentifier("calendar-workout-\(session.id.uuidString)")
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Workout Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UUID.self) { sessionID in
                WorkoutHistoryDetailScreen(sessionID: sessionID) {
                    if !historyPath.isEmpty { historyPath.removeLast() }
                }
            }
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func calendarCell(_ date: Date) -> some View {
        let daySessions = sessions.filter { $0.localDate == LocalDay.string(date) }.sorted { $0.startedAt < $1.startedAt }
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let isCurrentWeek = calendar.isDate(date, equalTo: .now, toGranularity: .weekOfYear)
        return Button { selectedDate = date } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(date.formatted(.dateTime.day())).font(.caption.weight(isToday || isSelected ? .bold : .regular))
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let first = daySessions.first {
                    Text(String(first.templateName.prefix(5))).font(.system(size: 8, weight: .medium)).lineLimit(1)
                    if daySessions.count > 1 { Text("+\(daySessions.count - 1)").font(.system(size: 8, weight: .bold)).foregroundStyle(.secondary) }
                } else {
                    Spacer(minLength: 0).frame(height: 12)
                }
            }
            .padding(5)
            .frame(maxWidth: .infinity, minHeight: 58, maxHeight: 58, alignment: .topLeading)
            .background(isSelected ? store.state.home.theme.palette.accentColor.opacity(0.22) : (isCurrentWeek ? store.state.home.theme.palette.accentColor.opacity(0.06) : Color.clear), in: RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(isToday ? store.state.home.theme.palette.accentColor : Color.clear, lineWidth: 1.4))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(date.formatted(date: .complete, time: .omitted)), \(daySessions.count) workouts")
        .accessibilityIdentifier("workout-calendar-\(LocalDay.string(date))")
    }

    private func changeMonth(by amount: Int) {
        guard let next = calendar.date(byAdding: .month, value: amount, to: month),
              let start = calendar.date(from: calendar.dateComponents([.year, .month], from: next)) else { return }
        month = start
        selectedDate = start
    }
}

private struct WorkoutDaySessionSummary: View {
    let sessions: [WorkoutSession]
    let weightUnit: String

    private var completedSets: Int {
        var count = 0
        for session in sessions {
            for exercise in session.exercises {
                count += exercise.sets.filter(\.completed).count
            }
        }
        return count
    }

    private var volume: Int {
        var kg = 0.0
        for session in sessions {
            for exercise in session.exercises {
                for set in exercise.sets where set.completed {
                    kg += (set.weightKg ?? 0) * Double(set.reps)
                }
            }
        }
        return Int(weightUnit == "lb" ? kg * 2.2046226218 : kg)
    }

    var body: some View {
        HStack {
            Label("\(sessions.count) workouts", systemImage: "dumbbell.fill")
            Spacer()
            Text("\(completedSets) sets · \(volume) \(weightUnit) volume")
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
    }
}

struct DailyHistoryPoint: Identifiable, Equatable {
    var id: String { date }
    let date: String
    let value: Double
}

enum NutritionHistorySeries {
    static func calories(from logs: [FoodLog], since cutoff: String) -> [DailyHistoryPoint] {
        aggregate(logs, since: cutoff, value: \.calories)
    }

    static func protein(from logs: [FoodLog], since cutoff: String) -> [DailyHistoryPoint] {
        aggregate(logs, since: cutoff, value: \.protein)
    }

    private static func aggregate(_ logs: [FoodLog], since cutoff: String, value: KeyPath<FoodLog, Double>) -> [DailyHistoryPoint] {
        Dictionary(grouping: logs.filter { $0.deletedAt == nil && $0.date >= cutoff }, by: \.date)
            .map { date, entries in DailyHistoryPoint(date: date, value: entries.reduce(0) { $0 + $1[keyPath: value] }) }
            .sorted { $0.date < $1.date }
    }
}

private struct HistoryExerciseOption: Identifiable {
    let id: String
    let name: String
}

enum StrengthHistorySeries {
    static func points(from sessions: [WorkoutSession], exerciseID: String, since cutoff: String) -> [DailyHistoryPoint] {
        var bestByDate: [String: Double] = [:]
        for session in sessions where session.finishedAt != nil && session.localDate >= cutoff {
            for exercise in session.exercises {
                guard exercise.exerciseID == exerciseID,
                      (exercise.trackingMode ?? .weightAndReps) == .weightAndReps else { continue }
                for set in exercise.sets where set.completed && set.reps > 0 {
                    guard let weight = set.weightKg, weight > 0 else { continue }
                    let estimate = weight * (1 + Double(set.reps) / 30)
                    bestByDate[session.localDate] = max(bestByDate[session.localDate] ?? 0, estimate)
                }
            }
        }
        return bestByDate.keys.sorted().compactMap { date in
            guard let value = bestByDate[date] else { return nil }
            return DailyHistoryPoint(date: date, value: value)
        }
    }
}

struct SettingsScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @State private var showThemeGallery = false
    @State private var showHomeEditor = false
    @State private var backupURL: URL?
    @State private var exportError: String?

    var body: some View {
        List {
            Section("Appearance") {
                Button { showThemeGallery = true } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) { Text("Theme").foregroundStyle(.primary); Text(store.state.home.theme.title).font(.caption).foregroundStyle(.secondary) }
                        Spacer()
                        Image(store.state.home.theme.rawValue).resizable().scaledToFill().frame(width: 58, height: 44).clipShape(RoundedRectangle(cornerRadius: 10))
                        Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                Toggle("Optional haptic feedback", isOn: Binding(get: { store.state.home.hapticsEnabled }, set: store.setHaptics))
            }
            Section("Home Screen") {
                Button { showHomeEditor = true } label: { Label("Edit pages and widgets", systemImage: "square.grid.2x2") }
                Text("Four approved default pages; customize page names, widget types, sizes, and placement. System widgets are managed from the iPhone Home Screen.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Fitness & Nutrition") {
                NavigationLink("Nutrition targets", destination: NutritionTargetsScreen())
                Picker("Weight unit", selection: Binding(get: { store.state.home.preferredWeightUnit }, set: store.setWeightUnit)) {
                    Text("Kilograms").tag("kg")
                    Text("Pounds").tag("lb")
                }
                NavigationLink("Training reminders", destination: ReminderSettingsScreen())
                NavigationLink("Nutrition reminders", destination: ReminderSettingsScreen())
            }
            Section("Data & Backup") {
                Button { createBackup() } label: { Label("Export Logbook backup", systemImage: "square.and.arrow.up") }
                if let backupURL {
                    ShareLink(item: backupURL) { Label("Share backup file…", systemImage: "doc.zipper") }
                }
                Text("Data stays on this device in a shared App Group file for the app and widgets. Keep a backup before changing devices. Importing existing web-app records is not yet enabled; see the project migration note before moving any real data.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Apple Health") {
                Label("Health access is off", systemImage: "heart.slash")
                Text("No HealthKit framework, entitlement, or permission prompt is included, per your choice.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Storage") {
                LabeledContent("Saved locally", value: store.lastSavedAt?.formatted(date: .omitted, time: .shortened) ?? "No changes yet")
                if let error = store.persistenceError { Text(error).font(.footnote).foregroundStyle(.red) }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showThemeGallery) { ThemeGalleryScreen().presentationDetents([.large]).presentationDragIndicator(.visible) }
        .sheet(isPresented: $showHomeEditor) { HomeEditorScreen().presentationDetents([.large]).presentationDragIndicator(.visible) }
        .alert("Backup could not be created", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
            Button("OK", role: .cancel) { exportError = nil }
        } message: { Text(exportError ?? "") }
    }

    private func createBackup() {
        do { backupURL = try store.exportBackup() }
        catch { exportError = error.localizedDescription }
    }
}

struct ThemeGalleryScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(LogbookTheme.allCases) { theme in
                        Button {
                            store.setTheme(theme)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 0) {
                                Image(theme.rawValue).resizable().scaledToFill().frame(height: 116).clipped()
                                    .overlay(alignment: .bottomLeading) {
                                        Text(theme.title.uppercased()).font(.system(size: 10, weight: .bold, design: .rounded)).tracking(0.9)
                                            .foregroundStyle(theme.palette.textColor).padding(8)
                                    }
                                HStack {
                                    Circle().fill(theme.palette.accentColor).frame(width: 12, height: 12)
                                    Text(theme.title).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                                    Spacer(minLength: 0)
                                    if store.state.home.theme == theme { Image(systemName: "checkmark.circle.fill").foregroundStyle(theme.palette.accentColor) }
                                }
                                .padding(10).foregroundStyle(theme.palette.textColor)
                                .background(theme.palette.surfaceColor.opacity(theme.palette.light ? 0.9 : 0.96))
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(theme.palette.accentColor.opacity(0.45), lineWidth: store.state.home.theme == theme ? 2 : 0.6))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Apply \(theme.title) theme")
                    }
                }
                .padding(16)
            }
            .background(ThemeBackdrop(theme: store.state.home.theme))
            .navigationTitle("Theme Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

struct ReminderSettingsScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @State private var permissionMessage: String?

    var body: some View {
        Form {
            Section {
                Toggle("Enable local reminders", isOn: Binding(
                    get: { store.state.notificationsEnabled },
                    set: { enabled in
                        Task {
                            if enabled {
                                guard await ReminderService.requestPermission() else { permissionMessage = "Notifications are not authorized in iOS Settings."; return }
                            }
                            store.setNotificationsEnabled(enabled)
                        }
                    }
                ))
                if let permissionMessage { Text(permissionMessage).font(.footnote).foregroundStyle(.orange) }
            } footer: { Text("Reminders are optional local notifications. iOS Focus and notification settings can delay or silence them.") }
            Section("Daily reminder times") {
                reminderRow("Food", value: store.state.nutritionReminderTime) { store.setReminder(kind: .food, time: $0) }
                reminderRow("Training", value: store.state.trainingReminderTime) { store.setReminder(kind: .training, time: $0) }
                reminderRow("Sleep", value: store.state.sleepReminderTime) { store.setReminder(kind: .sleep, time: $0) }
                reminderRow("Weight", value: store.state.weightReminderTime) { store.setReminder(kind: .weight, time: $0) }
                reminderRow("Supplements", value: store.state.supplementReminderTime) { store.setReminder(kind: .supplements, time: $0) }
                Text("Leave a time unset to keep that reminder off. Completed check-ins and days without scheduled supplements are skipped.").font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private func reminderRow(_ title: String, value: String?, set: @escaping (String?) -> Void) -> some View {
        let enabled = value != nil
        Toggle(isOn: Binding(get: { value != nil }, set: { on in
            if on && !store.state.notificationsEnabled {
                Task {
                    guard await ReminderService.requestPermission() else { permissionMessage = "Notifications are not authorized in iOS Settings."; return }
                    store.setNotificationsEnabled(true)
                    set(value ?? "19:00")
                }
            } else {
                set(on ? (value ?? "19:00") : nil)
            }
        })) { Text(title) }
            .accessibilityIdentifier("reminder-\(title.lowercased())-toggle")
        if enabled {
            DatePicker("Time", selection: Binding(get: { date(from: value ?? "19:00") }, set: { set(time(from: $0)) }), displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
                .accessibilityIdentifier("reminder-\(title.lowercased())-time")
        }
    }

    private func date(from value: String) -> Date {
        let pieces = value.split(separator: ":").compactMap { Int($0) }
        return Calendar.current.date(bySettingHour: pieces.first ?? 19, minute: pieces.dropFirst().first ?? 0, second: 0, of: .now) ?? .now
    }
    private func time(from date: Date) -> String {
        String(format: "%02d:%02d", Calendar.current.component(.hour, from: date), Calendar.current.component(.minute, from: date))
    }
}
