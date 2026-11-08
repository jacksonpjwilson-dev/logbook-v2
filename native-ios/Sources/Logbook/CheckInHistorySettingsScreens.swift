import Charts
import SwiftUI
import UniformTypeIdentifiers

struct CheckInScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @State private var bedtime = Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: .now) ?? .now
    @State private var wakeTime = Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: .now) ?? .now
    @State private var weight = ""
    @State private var showWeightSaved = false
    @State private var showSleepReplace = false
    @State private var showWeightReplace = false
    @State private var supplementName = ""
    @State private var showSupplementForm = false

    private var unit: String { store.state.home.preferredWeightUnit }
    private var weightToday: WeightLog? { store.state.checkins.weights.first { $0.date == LocalDay.string() } }

    var body: some View {
        ScrollViewReader { proxy in
        List {
            Section("Sleep") {
                DatePicker("Bedtime", selection: $bedtime, displayedComponents: .hourAndMinute)
                DatePicker("Wake time", selection: $wakeTime, displayedComponents: .hourAndMinute)
                Button { saveSleep() } label: { Label("Save sleep", systemImage: "moon.zzz.fill") }
                    .disabled(wakeTime <= sleepBedtime)
                if let last = store.state.checkins.sleep.max(by: { $0.wakeDate < $1.wakeDate }) {
                    LabeledContent("Last recorded", value: "\(String(format: "%.1f", Double(last.durationMinutes) / 60)) hours · \(last.wakeDate)")
                } else { Text("No sleep record yet.").font(.caption).foregroundStyle(.secondary) }
                Text("Sleep is entered manually. This app has no Apple Health access.").font(.footnote).foregroundStyle(.secondary)
            }
            .id(CheckInSection.sleep)

            Section("Weight") {
                HStack { TextField("Weight", text: $weight).keyboardType(.decimalPad); Text(unit).foregroundStyle(.secondary) }
                Button { saveWeight() } label: { Label("Save today’s weight", systemImage: "scalemass.fill") }
                    .disabled((Double(weight) ?? 0) <= 0)
                if let last = store.state.checkins.weights.max(by: { $0.date < $1.date }) {
                    Text("Last entry: \(displayWeight(last.kilograms)) \(unit) · \(last.date)").font(.caption).foregroundStyle(.secondary)
                }
            }
            .id(CheckInSection.weight)

            Section {
                if store.state.checkins.supplements.isEmpty {
                    Text("Add supplements you want to track. A dose is counted only after you mark it.").font(.footnote).foregroundStyle(.secondary)
                }
                ForEach(store.state.checkins.supplements) { supplement in
                    let dose = store.state.checkins.doses.first { $0.supplementID == supplement.id && $0.date == LocalDay.string() }
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(supplement.name).font(.headline)
                            Text(dose?.explicitlyMarked == true ? (dose?.taken == true ? "Taken today" : "Marked not taken") : "Not marked today")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { store.markSupplement(supplement, taken: dose?.taken != true) } label: {
                            Image(systemName: dose?.taken == true ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 25)).foregroundStyle(dose?.taken == true ? Color.green : Color.secondary)
                        }
                        .buttonStyle(.plain).accessibilityLabel(dose?.taken == true ? "Mark \(supplement.name) not taken" : "Mark \(supplement.name) taken")
                    }
                }
                Button { showSupplementForm = true } label: { Label("Add supplement", systemImage: "plus") }
            } header: { Text("Supplements") }
            .id(CheckInSection.supplements)

            Section {
                NavigationLink("Reminder settings", destination: ReminderSettingsScreen())
                    .font(.footnote)
                Text("Reminder times are optional and use local notifications. They are not guaranteed during Focus or when iOS limits delivery.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .onAppear { scrollToRequestedSection(using: proxy) }
        .onChange(of: store.focusedCheckInSection) { _, _ in scrollToRequestedSection(using: proxy) }
        }
        .navigationTitle("Sleep & Check-ins")
        .alert("Weight saved", isPresented: $showWeightSaved) { Button("OK", role: .cancel) { } }
        .alert("Add supplement", isPresented: $showSupplementForm) {
            TextField("Supplement name", text: $supplementName)
            Button("Save") { store.addSupplement(name: supplementName); supplementName = "" }
            Button("Cancel", role: .cancel) { supplementName = "" }
        }
        .confirmationDialog("Replace today’s sleep record?", isPresented: $showSleepReplace, titleVisibility: .visible) {
            Button("Replace sleep record", role: .destructive) { _ = store.addSleep(bedtime: sleepBedtime, wakeTime: wakeTime, confirmedReplace: true) }
            Button("Keep existing record", role: .cancel) { }
        } message: { Text("The earlier sleep entry for this wake date will be replaced.") }
        .confirmationDialog("Replace today’s weight?", isPresented: $showWeightReplace, titleVisibility: .visible) {
            Button("Replace weight", role: .destructive) {
                if store.addWeight(Double(weight) ?? 0, unit: unit, confirmedReplace: true) { weight = ""; showWeightSaved = true }
            }
            Button("Keep existing weight", role: .cancel) { }
        } message: { Text("There is already one official weight entry for today.") }
    }

    private var sleepBedtime: Date {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: .now)
        let bedHour = calendar.component(.hour, from: bedtime)
        let bedMinute = calendar.component(.minute, from: bedtime)
        let wakeHour = calendar.component(.hour, from: wakeTime)
        let wakeMinute = calendar.component(.minute, from: wakeTime)
        let crossesMidnight = bedHour * 60 + bedMinute >= wakeHour * 60 + wakeMinute
        let bedDay = crossesMidnight ? (calendar.date(byAdding: .day, value: -1, to: day) ?? day) : day
        return calendar.date(bySettingHour: bedHour, minute: bedMinute, second: 0, of: bedDay) ?? bedtime
    }

    private func scrollToRequestedSection(using proxy: ScrollViewProxy) {
        guard let section = store.focusedCheckInSection else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.2)) { proxy.scrollTo(section, anchor: .top) }
            store.clearCheckInFocus()
        }
    }

    private func displayWeight(_ kg: Double) -> String {
        let value = unit == "lb" ? kg * 2.2046226218 : kg
        return value.formatted(.number.precision(.fractionLength(1)))
    }

    private func saveSleep() {
        if store.state.checkins.sleep.contains(where: { $0.wakeDate == LocalDay.string(wakeTime) }) { showSleepReplace = true }
        else { _ = store.addSleep(bedtime: sleepBedtime, wakeTime: wakeTime) }
    }

    private func saveWeight() {
        guard let value = Double(weight), value > 0 else { return }
        if weightToday != nil { showWeightReplace = true }
        else if store.addWeight(value, unit: unit) { weight = ""; showWeightSaved = true }
    }
}

struct HistoryScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @State private var range = 30
    @State private var showingWorkoutCalendar = false
    @State private var workoutToDeletePermanently: UUID?
    private let ranges = [7, 30, 90]
    private var cutoff: String {
        LocalDay.string(Calendar.current.date(byAdding: .day, value: -range + 1, to: .now) ?? .now)
    }
    private var weights: [WeightLog] { store.state.checkins.weights.filter { $0.date >= cutoff }.sorted { $0.date < $1.date } }
    private var caloriesByDate: [DailyHistoryPoint] {
        Dictionary(grouping: store.state.nutrition.logs.filter { $0.date >= cutoff }, by: \.date)
            .map { DailyHistoryPoint(date: $0.key, value: $0.value.reduce(0) { $0 + $1.calories }) }
            .sorted { $0.date < $1.date }
    }
    private var sessions: [WorkoutSession] { store.state.training.visibleCompletedSessions.sorted { $0.startedAt > $1.startedAt } }

    var body: some View {
        List {
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
            }

            Section("Training") {
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
                let sleep = store.state.checkins.sleep.filter { $0.wakeDate >= cutoff }.sorted { $0.wakeDate > $1.wakeDate }
                if sleep.isEmpty { Text("Sleep charts use recorded check-ins only.").foregroundStyle(.secondary) }
                ForEach(sleep.prefix(14)) { item in
                    LabeledContent(item.wakeDate, value: "\(String(format: "%.1f", Double(item.durationMinutes) / 60)) hours")
                }
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

private struct WorkoutHistoryDetailScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    let sessionID: UUID
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
        NavigationStack {
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
                                NavigationLink(destination: WorkoutHistoryDetailScreen(sessionID: session.id)) {
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

private struct DailyHistoryPoint: Identifiable {
    var id: String { date }
    let date: String
    let value: Double
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
                reminderRow("Nutrition", route: .food, value: store.state.nutritionReminderTime)
                reminderRow("Training", route: .training, value: store.state.trainingReminderTime)
                Text("Leave a time unset to keep that reminder off.").font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private func reminderRow(_ title: String, route: LogbookRoute, value: String?) -> some View {
        let enabled = value != nil
        Toggle(isOn: Binding(get: { enabled }, set: { on in
            if on && !store.state.notificationsEnabled {
                Task {
                    guard await ReminderService.requestPermission() else { permissionMessage = "Notifications are not authorized in iOS Settings."; return }
                    store.setNotificationsEnabled(true)
                    store.setReminder(kind: route, time: "19:00")
                }
            } else {
                store.setReminder(kind: route, time: on ? (value ?? "19:00") : nil)
            }
        })) { Text(title) }
        if enabled {
            DatePicker("Time", selection: Binding(get: { date(from: value ?? "19:00") }, set: { store.setReminder(kind: route, time: time(from: $0)) }), displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
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
