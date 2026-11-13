import Charts
import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Binding var path: [LogbookRoute]
    @State private var pageIndex = 0
    @State private var isEditing = false
    @State private var showEditor = false

    private var theme: LogbookTheme { store.state.home.theme }
    private var palette: ThemePalette { theme.palette }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ThemeBackdrop(theme: theme)
                VStack(spacing: 0) {
                    header
                    TabView(selection: $pageIndex) {
                        ForEach(store.state.home.pages.indices, id: \.self) { index in
                            let page = store.state.home.pages[index]
                            HomePageGrid(
                                page: page,
                                editing: isEditing,
                                open: { route in path = [route] },
                                openCheckIn: { section in
                                    store.focusCheckIn(section)
                                    path = [.checkins]
                                },
                                openFoodFocus: { destination in
                                    store.focusFood(destination)
                                    path = [.food]
                                },
                                startWorkout: { template in
                                    store.startWorkout(template)
                                    store.requestActiveWorkoutPresentation()
                                    path = [.training]
                                },
                                remove: { id in store.removeHomeWidget(id, pageID: page.id) }
                            )
                            .tag(index)
                            .padding(.horizontal, 18)
                            .padding(.top, 4)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(maxHeight: .infinity)
                    pageIndicator
                        .padding(.bottom, 7)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            LogbookDock(path: $path, tokens: theme.tokens, isDefault: theme == .defaultTheme)
                .frame(height: 58)
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showEditor) {
            HomeEditorScreen()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: store.state.home.pages.count) { _, count in
            pageIndex = min(pageIndex, max(0, count - 1))
        }
        .onChange(of: pageIndex) { _, index in
            guard store.state.home.pages.indices.contains(index) else { return }
            isEditing = false
        }
        .onChange(of: showEditor) { _, visible in
            if !visible { isEditing = false }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Spacer()
                if !isEditing, store.state.training.activeSession != nil {
                    Button { path = [.training] } label: {
                        Label("Resume", systemImage: "play.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 11).padding(.vertical, 8)
                            .background(palette.accentColor.opacity(0.82), in: Capsule())
                            .foregroundStyle(palette.onAccentColor)
                    }
                    .accessibilityLabel("Resume active workout")
                }
                if isEditing {
                    Button { showEditor = true } label: {
                        Label("Add", systemImage: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 13).padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(0.34), lineWidth: 0.7))
                    }
                    .accessibilityLabel("Add or customize widgets")
                    .foregroundStyle(palette.textColor)
                    Button { isEditing = false } label: {
                        Text("Done")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 13).padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(0.34), lineWidth: 0.7))
                    }
                    .accessibilityLabel("Finish editing Home Screen")
                    .foregroundStyle(palette.textColor)
                } else {
                    Button { isEditing = true } label: {
                        Text("Edit")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.horizontal, 13).padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(0.34), lineWidth: 0.7))
                    }
                    .accessibilityLabel("Edit Home Screen")
                    .foregroundStyle(palette.textColor)
                }
            }
            Text(displayDate)
                .font(.system(size: 10, weight: .medium))
                .tracking(theme == .defaultTheme ? 0.45 : 1.1)
                .foregroundStyle(palette.mutedColor)
                .frame(height: 12, alignment: .leading)
            HStack(alignment: .firstTextBaseline) {
                Text("Logbook")
                    .font(.system(size: theme == .defaultTheme ? 27 : 30, weight: theme == .defaultTheme ? .semibold : .bold, design: .rounded))
                Spacer()
                Text(currentPageName).font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.mutedColor).lineLimit(1)
            }
            .frame(height: 36, alignment: .leading)
            .foregroundStyle(palette.textColor)
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 9)
    }

    private var currentPageName: String {
        guard store.state.home.pages.indices.contains(pageIndex) else { return "Daily overview" }
        return store.state.home.pages[pageIndex].name
    }

    private var displayDate: String {
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") { return "WEDNESDAY, NOVEMBER 4" }
        return Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()).uppercased()
    }

    private var pageIndicator: some View {
        HStack(spacing: 7) {
            ForEach(store.state.home.pages.indices, id: \.self) { index in
                Button { withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) { pageIndex = index } } label: {
                    Capsule().fill(index == pageIndex ? palette.textColor : palette.textColor.opacity(0.38))
                        .frame(width: index == pageIndex ? 18 : 6, height: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(store.state.home.pages[index].name) page")
            }
        }
        .padding(.vertical, 9)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Home Screen pages")
    }
}

private struct HomePageGrid: View {
    @EnvironmentObject private var store: LogbookStore
    let page: HomePage
    let editing: Bool
    let open: (LogbookRoute) -> Void
    let openCheckIn: (CheckInSection) -> Void
    let openFoodFocus: (FoodNavigationFocus) -> Void
    let startWorkout: (WorkoutTemplate) -> Void
    let remove: (UUID) -> Void
    @State private var wigglePhase = false

    private let gap: CGFloat = 9

    private var usesApprovedDailyLayout: Bool {
        guard page.name == "Daily", store.state.home.theme == .defaultTheme,
              page.widgets.count == HomeState.defaultDailyPage.widgets.count else { return false }
        return HomeState.defaultDailyPage.widgets.allSatisfy { expected in
            page.widgets.contains {
                $0.kind == expected.kind && $0.size == expected.size && $0.row == expected.row &&
                    $0.column == expected.column && $0.variant == expected.variant
            }
        }
    }

    private var usesApprovedTrainingLayout: Bool {
        guard page.name == "Training", store.state.home.theme == .defaultTheme,
              page.widgets.count == 2 else { return false }
        let expected = HomeState.defaultPages[1].widgets
        return expected.allSatisfy { item in
            page.widgets.contains {
                $0.kind == item.kind && $0.size == item.size && $0.row == item.row &&
                    $0.column == item.column && $0.variant == item.variant
            }
        }
    }

    private var usesApprovedFoodLayout: Bool {
        guard page.name == "Food", store.state.home.theme == .defaultTheme,
              page.widgets.count == HomeState.defaultPages[2].widgets.count else { return false }
        return HomeState.defaultPages[2].widgets.allSatisfy { expected in
            page.widgets.contains {
                $0.kind == expected.kind && $0.size == expected.size && $0.row == expected.row &&
                    $0.column == expected.column && $0.variant == expected.variant
            }
        }
    }

    private var usesApprovedProgressLayout: Bool {
        guard page.name == "Progress & History", store.state.home.theme == .defaultTheme,
              page.widgets.count == HomeState.defaultPages[3].widgets.count else { return false }
        return HomeState.defaultPages[3].widgets.allSatisfy { expected in
            page.widgets.contains {
                $0.kind == expected.kind && $0.size == expected.size && $0.row == expected.row &&
                    $0.column == expected.column && $0.variant == expected.variant
            }
        }
    }

    var body: some View {
        GeometryReader { proxy in
            gridBody(size: proxy.size)
        }
        .task(id: editing) {
            guard editing else {
                wigglePhase = false
                return
            }
            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: 0.14)) { wigglePhase.toggle() }
                do {
                    try await Task.sleep(for: .milliseconds(140))
                } catch {
                    break
                }
            }
        }
    }

    private func gridBody(size: CGSize) -> some View {
        // One scalar controls both axes: the eight cells are true squares.
        // Constrain the grid by the safe vertical space first when needed,
        // then center the two-column grid instead of stretching its rows.
        let cellSide = max(1, min((size.width - gap) / 2, (size.height - gap * 3) / 4))
        let gridWidth = cellSide * 2 + gap
        let gridLeading = max(0, (size.width - gridWidth) / 2)
        return ZStack(alignment: .topLeading) {
            ForEach(page.widgets) { widget in
                widgetCell(widget, cellSide: cellSide, gridLeading: gridLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .overlay {
            if page.widgets.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "square.grid.2x2").font(.system(size: 28, weight: .light))
                    Text("This page is ready for your widgets.").font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(store.state.home.theme.palette.textColor.opacity(0.78))
            }
        }
    }

    private func widgetCell(
        _ widget: HomeWidget,
        cellSide: CGFloat,
        gridLeading: CGFloat
    ) -> some View {
        let isSmall = widget.size == .small
        let isLarge = widget.size == .large
        let columns: CGFloat = isSmall ? 1 : 2
        let rows: CGFloat = isLarge ? 2 : 1
        let width = cellSide * columns + gap * (columns - 1)
        let height = cellSide * rows + gap * (rows - 1)
        let originX = gridLeading + CGFloat(widget.column) * (cellSide + gap)
        let originY = CGFloat(widget.row) * (cellSide + gap)
        let angle = (widget.row + widget.column).isMultiple(of: 2) ? -1.0 : 1.0
        let rotation = editing ? angle * (wigglePhase ? 0.6 : -0.6) : 0

        return ZStack(alignment: .topTrailing) {
            widgetContent(for: widget, width: width, height: height)
            if editing {
                Button { remove(widget.id) } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 25, height: 25)
                        .background(Color.red, in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 1))
                }
                .offset(x: -7, y: 7)
                .accessibilityLabel("Remove \(widget.kind.title) widget")
            }
        }
        .frame(width: width, height: height)
        .position(x: originX + width / 2, y: originY + height / 2)
        .rotationEffect(.degrees(rotation))
        .transaction { transaction in
            if !editing { transaction.animation = nil }
        }
    }

    private func route(for kind: WidgetKind) -> LogbookRoute {
        switch kind.family {
        case "Training": .training
        case "Food": .food
        case "Body": .checkins
        default: .history
        }
    }

    @ViewBuilder
    private func widgetContent(for widget: HomeWidget, width: CGFloat, height: CGFloat) -> some View {
        if usesApprovedDailyLayout {
            DefaultDailyWidgetView(
                widget: widget,
                palette: store.state.home.theme.palette,
                state: store.state,
                openFood: { open(.food) },
                openTraining: { open(.training) },
                openCheckIn: openCheckIn,
                startWorkout: startWorkout
            )
            .frame(width: width, height: height)
            .disabled(editing)
        } else if usesApprovedTrainingLayout {
            DefaultTrainingWidgetView(
                widget: widget,
                palette: store.state.home.theme.palette,
                state: store.state,
                openTraining: { open(.training) }
            )
            .frame(width: width, height: height)
            .disabled(editing)
        } else if usesApprovedFoodLayout {
            DefaultFoodHomeWidgetView(
                widget: widget,
                palette: store.state.home.theme.palette,
                state: store.state,
                openFood: openFoodFocus
            )
            .frame(width: width, height: height)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("home-widget-food-\(widget.kind.rawValue)")
            .accessibilityValue("\(width)|\(height)")
            .disabled(editing)
        } else if usesApprovedProgressLayout {
            DefaultProgressHomeWidget(
                widget: widget,
                palette: store.state.home.theme.palette,
                state: store.state,
                openHistory: { open(.history) },
                openHistoryDate: { date in
                    open(.historyDate(date))
                }
            )
            .frame(width: width, height: height)
            .disabled(editing)
        } else {
            Button {
                guard !editing else { return }
                open(route(for: widget.kind))
            } label: {
                HomeWidgetCard(widget: widget, palette: store.state.home.theme.palette, state: store.state)
                    .frame(width: width, height: height)
            }
            .accessibilityIdentifier("home-widget-\(widget.kind.rawValue)")
            .buttonStyle(WidgetPressStyle())
            .disabled(editing)
        }
    }
}



enum ActivityHeatmapMetrics {
    /// Equal-weight daily activity signal. Training, Food, Sleep and Weight are
    /// always eligible; Supplements counts only on a day with at least one due item.
    static func score(state: LogbookState, on date: String) -> Double {
        guard let dateValue = LocalDay.formatter.date(from: date) else { return 0 }
        let active = [
            state.training.visibleCompletedSessions.contains { $0.localDate == date },
            state.nutrition.logs.contains { $0.date == date && $0.deletedAt == nil },
            state.checkins.sleep.contains { $0.wakeDate == date && $0.deletedAt == nil },
            state.checkins.weights.contains { $0.date == date && $0.deletedAt == nil }
        ]
        var completed = active.filter { $0 }.count
        var eligible = active.count
        let weekday = Calendar.current.component(.weekday, from: dateValue)
        let due = state.checkins.supplements.filter { supplement in
            guard supplement.deletedAt == nil else { return false }
            return supplement.schedule.lowercased() == "daily" || supplement.weekdays.contains(weekday)
        }
        if !due.isEmpty {
            eligible += 1
            let allTaken = due.allSatisfy { supplement in
                state.checkins.doses.contains {
                    $0.deletedAt == nil && $0.supplementID == supplement.id && $0.date == date &&
                        $0.taken && $0.explicitlyMarked
                }
            }
            if allTaken { completed += 1 }
        }
        return eligible == 0 ? 0 : Double(completed) / Double(eligible)
    }
}

private struct ProgressExerciseOption: Identifiable {
    let id: String
    let name: String
}

private enum ProgressMetric: String, CaseIterable, Identifiable {
    case weight, strength, sleep, calories, protein
    var id: String { rawValue }
    var title: String {
        switch self {
        case .weight: "Weight"
        case .strength: "Strength"
        case .sleep: "Sleep"
        case .calories: "Calories"
        case .protein: "Protein"
        }
    }
}

private struct DefaultProgressHomeWidget: View {
    private struct ActivityMonthCell: Identifiable {
        let id: String
        let dateKey: String?
        let dayLabel: String?
    }

    let widget: HomeWidget
    let palette: ThemePalette
    let state: LogbookState
    let openHistory: () -> Void
    let openHistoryDate: (String) -> Void
    @State private var selectedMetric: ProgressMetric = .weight
    @State private var selectedExerciseID = ""
    @State private var displayedActivityMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now

    private var cutoff: String {
        LocalDay.string(Calendar.current.date(byAdding: .day, value: -29, to: .now) ?? .now)
    }

    private var exerciseOptions: [ProgressExerciseOption] {
        var names: [String: String] = [:]
        for session in state.training.visibleCompletedSessions {
            for exercise in session.exercises { names[exercise.exerciseID] = exercise.name }
        }
        return names.keys.sorted { (names[$0] ?? $0) < (names[$1] ?? $1) }
            .map { ProgressExerciseOption(id: $0, name: names[$0] ?? $0) }
    }

    private var series: [DailyHistoryPoint] {
        switch selectedMetric {
        case .weight:
            return state.checkins.weights
                .filter { $0.deletedAt == nil && $0.date >= cutoff }
                .map { DailyHistoryPoint(date: $0.date, value: state.home.preferredWeightUnit == "lb" ? $0.kilograms * 2.2046226218 : $0.kilograms) }
                .sorted { $0.date < $1.date }
        case .strength:
            return strengthSeries()
        case .sleep:
            return Dictionary(grouping: state.checkins.sleep.filter { $0.deletedAt == nil && $0.wakeDate >= cutoff }, by: \.wakeDate)
                .map { date, records in DailyHistoryPoint(date: date, value: Double(records.reduce(0) { $0 + $1.durationMinutes }) / 60) }
                .sorted { $0.date < $1.date }
        case .calories:
            return NutritionHistorySeries.calories(from: state.nutrition.logs, since: cutoff)
        case .protein:
            return NutritionHistorySeries.protein(from: state.nutrition.logs, since: cutoff)
        }
    }

    private func strengthSeries() -> [DailyHistoryPoint] {
        var bestByDate: [String: Double] = [:]
        for session in state.training.visibleCompletedSessions where session.localDate >= cutoff {
            for exercise in session.exercises {
                guard exercise.exerciseID == selectedExerciseID,
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

    private var unit: String {
        switch selectedMetric {
        case .weight: state.home.preferredWeightUnit
        case .strength: "kg e1RM"
        case .sleep: "hours"
        case .calories: "kcal"
        case .protein: "g"
        }
    }

    private var latestValue: String {
        guard let value = series.last?.value else { return "No data yet" }
        switch selectedMetric {
        case .weight: return "\(value.formatted(.number.precision(.fractionLength(1)))) \(unit)"
        case .strength: return "\(value.formatted(.number.precision(.fractionLength(1)))) kg"
        case .sleep: return "\(value.formatted(.number.precision(.fractionLength(1)))) h"
        case .calories: return "\(Int(value)) kcal"
        case .protein: return "\(Int(value)) g"
        }
    }

    var body: some View {
        Group {
            switch widget.kind {
            case .graph: chartWidget
            case .calendarHeatmap: heatmapWidget
            case .personalRecords: recordsWidget
            case .mealTiming where widget.variant == "Nutrition Adherence": adherenceWidget
            default: HomeWidgetCard(widget: widget, palette: palette, state: state)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(state.home.theme.tokens.surfaceTint.opacity(state.home.theme.tokens.cardOpacity), in: RoundedRectangle(cornerRadius: state.home.theme.tokens.cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: state.home.theme.tokens.cornerRadius, style: .continuous).stroke(palette.accentColor.opacity(state.home.theme.tokens.borderOpacity), lineWidth: 0.9))
        .shadow(color: .black.opacity(state.home.theme.tokens.shadowOpacity), radius: state.home.theme.tokens.cardShadowRadius, x: 0, y: 7)
        .accessibilityElement(children: .contain)
        .onAppear {
            if selectedExerciseID.isEmpty { selectedExerciseID = exerciseOptions.first?.id ?? "" }
        }
    }

    private var chartWidget: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Label("30-DAY PROGRESS", systemImage: "chart.xyaxis.line")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.mutedColor)
                Spacer()
                Text(latestValue)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.textColor)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            Picker("Progress metric", selection: $selectedMetric) {
                ForEach(ProgressMetric.allCases) { metric in Text(metric.title).tag(metric) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .accessibilityIdentifier("progress-metric-picker")
            if selectedMetric == .strength && exerciseOptions.count > 1 {
                Picker("Exercise", selection: $selectedExerciseID) {
                    ForEach(exerciseOptions) { option in Text(option.name).tag(option.id) }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("progress-strength-exercise")
            }
            if series.isEmpty {
                ContentUnavailableView("No \(selectedMetric.title.lowercased()) data", systemImage: "chart.xyaxis.line", description: Text("Log a check-in or complete a workout to start this 30-day trend."))
                    .frame(maxHeight: .infinity)
            } else {
                Chart(series) { point in
                    LineMark(x: .value("Date", point.date), y: .value(unit, point.value))
                        .interpolationMethod(.catmullRom).foregroundStyle(palette.accentColor)
                    PointMark(x: .value("Date", point.date), y: .value(unit, point.value))
                        .foregroundStyle(palette.accentColor)
                }
                .chartYAxisLabel(unit)
                .frame(maxHeight: .infinity)
                .accessibilityIdentifier("progress-metric-chart")
            }
            Button("View History", action: openHistory)
                .font(.system(size: 10, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityIdentifier("progress-view-history")
        }
        .padding(10)
    }

    private var activityCalendar: Calendar { .current }

    private var activityMonthStart: Date? {
        activityCalendar.date(from: activityCalendar.dateComponents([.year, .month], from: displayedActivityMonth))
    }

    private var activityMonthDates: [Date?] {
        guard let firstDay = activityMonthStart,
              let days = activityCalendar.range(of: .day, in: .month, for: firstDay) else { return [] }
        let offset = (activityCalendar.component(.weekday, from: firstDay) - activityCalendar.firstWeekday + 7) % 7
        var dates = Array(repeating: nil as Date?, count: offset)
        for day in days {
            dates.append(activityCalendar.date(byAdding: .day, value: day - 1, to: firstDay))
        }
        return dates
    }

    private var activityMonthCells: [ActivityMonthCell] {
        guard let firstDay = activityMonthStart else { return [] }
        let year = activityCalendar.component(.year, from: firstDay)
        let month = activityCalendar.component(.month, from: firstDay)
        return activityMonthDates.enumerated().map { index, date in
            guard let date else { return ActivityMonthCell(id: "blank-\(index)", dateKey: nil, dayLabel: nil) }
            let day = activityCalendar.component(.day, from: date)
            let key = String(format: "%04d-%02d-%02d", year, month, day)
            return ActivityMonthCell(id: "day-\(key)", dateKey: key, dayLabel: String(day))
        }
    }

    private var activityWeekdaySymbols: [String] {
        let symbols = activityCalendar.veryShortStandaloneWeekdaySymbols
        guard !symbols.isEmpty else { return [] }
        let start = max(0, min(symbols.count - 1, activityCalendar.firstWeekday - 1))
        return Array(symbols[start...]) + Array(symbols[..<start])
    }

    private func changeActivityMonth(by amount: Int) {
        guard let firstDay = activityMonthStart,
              let changed = activityCalendar.date(byAdding: .month, value: amount, to: firstDay),
              let monthStart = activityCalendar.date(from: activityCalendar.dateComponents([.year, .month], from: changed)) else { return }
        displayedActivityMonth = monthStart
    }

    private var heatmapWidget: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)
        return VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 2) {
                Label(widget.variant ?? "MONTHLY ACTIVITY", systemImage: "calendar")
                    .font(.system(size: 8, weight: .bold, design: .rounded)).lineLimit(1)
                Spacer(minLength: 1)
                Button { changeActivityMonth(by: -1) } label: {
                    Image(systemName: "chevron.left").font(.system(size: 7, weight: .bold)).frame(width: 12, height: 12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Previous month")
                .accessibilityIdentifier("activity-month-previous")
                Text(displayedActivityMonth.formatted(.dateTime.month(.abbreviated).year()))
                    .font(.system(size: 7, weight: .semibold))
                    .lineLimit(1)
                    .accessibilityIdentifier("activity-month-label")
                Button { changeActivityMonth(by: 1) } label: {
                    Image(systemName: "chevron.right").font(.system(size: 7, weight: .bold)).frame(width: 14, height: 14)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Next month")
                .accessibilityIdentifier("activity-month-next")
            }
            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(Array(activityWeekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol.uppercased())
                        .font(.system(size: 6, weight: .medium))
                        .frame(maxWidth: .infinity).frame(height: 7)
                        .foregroundStyle(palette.mutedColor)
                }
            }
            LazyVGrid(columns: columns, spacing: 1) {
                // Date-based identities prevent LazyVGrid from reusing a previous
                // month's button action for a different day at the same cell index.
                ForEach(activityMonthCells) { cell in
                    if let key = cell.dateKey {
                        Button { openHistoryDate(key) } label: {
                            Text(cell.dayLabel ?? "")
                                .font(.system(size: 6, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity).frame(height: 8)
                                .foregroundStyle(palette.textColor)
                                .background(palette.accentColor.opacity(max(0.08, activityScore(on: key))), in: RoundedRectangle(cornerRadius: 2))
                        }
                        .buttonStyle(.plain)
                        .id("activity-day-button-\(key)")
                        .accessibilityLabel("\(key), activity score \(Int(activityScore(on: key) * 100)) percent")
                        .accessibilityIdentifier("activity-day-\(key)")
                    } else {
                        Color.clear.frame(height: 8)
                    }
                }
            }
            HStack(spacing: 3) {
                Text("Training · Food · Sleep · Weight · due supplements")
                    .font(.system(size: 6, weight: .medium)).lineLimit(1).minimumScaleFactor(0.7)
                Spacer(minLength: 1)
                Button("History", action: openHistory)
                    .font(.system(size: 7, weight: .semibold))
            }
        }
        .foregroundStyle(palette.textColor)
        .padding(6)
    }

    private func activityScore(on date: String) -> Double {
        ActivityHeatmapMetrics.score(state: state, on: date)
    }

    private var recordsWidget: some View {
        let monthRecords = state.training.personalRecordEvents.filter { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month) }.sorted { $0.date > $1.date }
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label("PRs THIS MONTH", systemImage: "trophy.fill").font(.system(size: 9, weight: .bold, design: .rounded))
                Spacer()
                Text("\(monthRecords.count)").font(.system(size: 17, weight: .bold, design: .rounded))
            }
            if let featured = monthRecords.first {
                Text(featured.exerciseName).font(.system(size: 13, weight: .semibold)).lineLimit(1)
                Text("e1RM \(featured.estimatedOneRepMaxKg.formatted(.number.precision(.fractionLength(1)))) kg").font(.system(size: 10))
            } else {
                Text("Your first completed workout establishes an exercise baseline.")
                    .font(.system(size: 9)).lineLimit(3)
            }
            Button("View PR history", action: openHistory).font(.system(size: 9, weight: .semibold))
            Spacer(minLength: 0)
        }
        .foregroundStyle(palette.textColor)
        .padding(10)
    }

    private var adherenceWidget: some View {
        let dates = (0..<30).compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: Calendar.current.startOfDay(for: .now)) }
        let states = dates.map { state.nutritionAdherence(on: LocalDay.string($0)) }
        let eligible = states.filter { $0 != .unlogged && $0 != .noTargets }
        let onTarget = eligible.filter { $0 == .onTarget }.count
        let percentage = eligible.isEmpty ? 0 : Double(onTarget) / Double(eligible.count)
        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label("NUTRITION ADHERENCE", systemImage: "target").font(.system(size: 8, weight: .bold, design: .rounded)).lineLimit(1)
                Spacer(minLength: 0)
                Text("±\(Int((state.nutrition.calorieTolerance ?? 0.05) * 100))%").font(.system(size: 8, weight: .medium))
            }
            HStack(spacing: 7) {
                ZStack {
                    Circle().stroke(palette.accentColor.opacity(0.18), lineWidth: 5)
                    Circle().trim(from: 0, to: percentage).stroke(palette.accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round)).rotationEffect(.degrees(-90))
                    Text("\(Int(percentage * 100))%").font(.system(size: 12, weight: .bold, design: .rounded)).minimumScaleFactor(0.7)
                }.frame(width: 42, height: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text(eligible.isEmpty ? "No target days yet" : "\(onTarget) of \(eligible.count) logged days")
                        .font(.system(size: 9, weight: .semibold)).lineLimit(2)
                    Text("calories in range + protein goal").font(.system(size: 7, weight: .medium)).lineLimit(2)
                }
            }
            Button("View adherence", action: openHistory).font(.system(size: 9, weight: .semibold))
        }
        .foregroundStyle(palette.textColor)
        .padding(8)
    }
}

private struct HomeWidgetCard: View {
    let widget: HomeWidget
    let palette: ThemePalette
    let state: LogbookState

    private var summary: (String, String) {
        let today = LocalDay.string()
        let totals = state.nutritionTotals(on: today)
        let targets = state.nutritionTargets(on: today)
        switch widget.kind {
        case .calories:
            if let target = targets.calories {
                let remaining = Int(max(0, target - (totals.calories ?? 0)))
                if widget.variant == "Calories & Protein Remaining" {
                    let proteinLeft = targets.protein.map { Int(max(0, $0 - (totals.protein ?? 0))) }
                    return ("\(remaining) kcal left", proteinLeft.map { "\($0) g protein left" } ?? "Set a protein target")
                }
                return (String(remaining), "calories left · \(Int(totals.calories ?? 0)) eaten")
            }
            if widget.variant == "Calories & Protein Remaining" { return ("Set calorie target", "Set a protein target") }
            return ("Set your target", "Calories update from your food log")
        case .protein:
            if let target = targets.protein { return (String(Int(max(0, target - (totals.protein ?? 0)))) + " g", "protein remaining") }
            return ("No target", "Set a protein goal in Food")
        case .macros:
            return ("\(Int(totals.protein ?? 0)) g protein", "\(Int(totals.carbohydrates ?? 0)) g carbs · \(Int(totals.fat ?? 0)) g fat")
        case .water:
            let amount = state.nutrition.water.filter { $0.date == today }.reduce(0) { $0 + $1.milliliters }
            return ("\(amount) mL", "water logged today")
        case .meals:
            let count = state.nutrition.logs.filter { $0.date == today && $0.deletedAt == nil }.count
            return ("\(count) food entries", "across \(state.nutrition.meals.count) meals")
        case .nextWorkout:
            if let active = state.training.activeSession { return (active.templateName, "Workout in progress · Tap to open Training") }
            if let template = state.training.scheduledTemplate {
                let templates = state.training.activeProgram?.templateIDs.compactMap { id in state.training.templates.first { $0.id == id } } ?? []
                let position = templates.firstIndex { $0.id == template.id }.map { $0 + 1 } ?? 1
                return ("\(position). \(template.name)", "Workout \(position) of \(templates.count) · Tap to open Training")
            }
            return ("No workout planned", "Create a plan in Training")
        case .workoutSplit, .upcomingPlan, .volumeTrend, .muscleGroups, .restTimer:
            if let active = state.training.activeSession { return (active.templateName, "Workout in progress") }
            if let template = state.training.scheduledTemplate {
                let count = state.training.activeProgram?.templateIDs.count ?? 0
                return (template.name, "Next in \(state.training.activeProgram?.name ?? "Program") · \(count) workout\(count == 1 ? "" : "s")")
            }
            return ("No workout planned", "Create a plan in Training")
        case .thisWeek:
            let sessions = state.training.visibleCompletedSessions.filter { $0.localDate >= weekStart() }
            return ("\(sessions.count) workouts", "completed this week")
        case .lastWorkout:
            if let last = state.training.visibleCompletedSessions.max(by: { ($0.finishedAt ?? .distantPast) < ($1.finishedAt ?? .distantPast) }) {
                return (last.templateName, last.localDate)
            }
            return ("No sessions yet", "Your completed workouts will appear here")
        case .personalRecords:
            let records = state.training.personalRecordEvents.filter { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month) }.sorted { $0.date > $1.date }
            if let featured = records.first {
                return ("\(records.count) PR\(records.count == 1 ? "" : "s") this month", "\(featured.exerciseName) · e1RM \(Int(featured.estimatedOneRepMaxKg)) kg")
            }
            return ("No PRs this month", "First completed workout sets your baseline")
        case .lastNight, .sleepChart, .sleepConsistency:
            guard let sleep = state.checkins.sleep.max(by: { $0.wakeDate < $1.wakeDate }) else { return ("No sleep logged", "Add a check-in when you wake") }
            return (String(format: "%.1f hours", Double(sleep.durationMinutes) / 60), "last recorded sleep")
        case .weight, .weightTrend, .measurements:
            guard let weight = state.checkins.weights.max(by: { $0.date < $1.date }) else { return ("No weight logged", "Add an optional check-in") }
            return (String(format: "%.1f %@", weightValue(weight.kilograms), state.home.preferredWeightUnit), "last recorded · \(weight.date)")
        case .supplements:
            let dayDoses = state.checkins.doses.filter { $0.date == today && $0.explicitlyMarked }
            return ("\(dayDoses.filter(\.taken).count) taken", "of \(state.checkins.supplements.count) supplements")
        case .graph, .calendarHeatmap, .monthSummary, .bestWeek, .compare, .milestones, .journal, .allTimeTotals:
            return ("Your history", "Charts use your recorded data")
        case .trainingStreak:
            return (widget.variant ?? "Training activity", "Habits appear as you log them")
        case .vitals:
            return (widget.variant ?? "Check-ins", "Sleep, weight and doses")
        case .fibre, .mealTiming, .weeklyCalories, .easyNext, .quickLog, .bedtimeTarget, .today:
            return (widget.variant ?? widget.kind.title, "Open to view details")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: widget.kind.icon).font(.system(size: 11, weight: .semibold)).foregroundStyle(palette.accentColor)
                Text(visibleHeaderTitle)
                    .font(.system(size: 9, weight: .bold, design: .rounded)).tracking(1.1).lineLimit(1)
                Spacer(minLength: 2)
                if widget.kind == .graph { Image(systemName: "arrow.up.right").font(.system(size: 9, weight: .bold)) }
            }
            .foregroundStyle(palette.mutedColor)
            Text(summary.0)
                .font(.system(size: widget.size == .small ? 17 : widget.size == .large ? 26 : 21, weight: .bold, design: .rounded))
                .lineLimit(2).minimumScaleFactor(0.72)
                .foregroundStyle(palette.textColor)
            Text(summary.1)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .lineLimit(widget.size == .large ? 3 : 2)
                .foregroundStyle(palette.mutedColor.opacity(0.95))
            if widget.size == .large { Spacer(minLength: 0); detailVisual }
        }
        .padding(widget.size == .small ? 12 : 15)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // A tinted glass surface keeps the theme visible while protecting text contrast.
        .background(themeTokens.surfaceTint.opacity(themeTokens.cardOpacity), in: RoundedRectangle(cornerRadius: themeTokens.cornerRadius, style: cardCornerStyle))
        .overlay(RoundedRectangle(cornerRadius: themeTokens.cornerRadius, style: cardCornerStyle).stroke(palette.light ? palette.accentColor.opacity(themeTokens.borderOpacity) : .white.opacity(themeTokens.borderOpacity), lineWidth: 0.9))
        .shadow(color: .black.opacity(themeTokens.shadowOpacity), radius: themeTokens.cardShadowRadius, x: 0, y: 7)
        .contentShape(RoundedRectangle(cornerRadius: themeTokens.cornerRadius, style: cardCornerStyle))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(widget.variant ?? widget.kind.title), \(summary.0), \(summary.1). Open details.")
    }

    private var themeTokens: ThemeTokens { state.home.theme.tokens }
    private var cardCornerStyle: RoundedCornerStyle { state.home.theme == .defaultTheme ? .continuous : .circular }

    private var visibleHeaderTitle: String {
        guard state.home.theme == .defaultTheme, widget.size == .small else {
            return widget.variant ?? widget.kind.title.uppercased()
        }
        if widget.variant == "Habits Streak" { return "HABITS" }
        if widget.variant == "Daily Check-in" { return "CHECK-IN" }
        return widget.variant ?? widget.kind.title.uppercased()
    }

    @ViewBuilder private var detailVisual: some View {
        if widget.variant == "Calories & Protein Remaining", state.home.theme == .defaultTheme {
            CaloriesMacroVisual(state: state, palette: palette)
        } else if widget.variant == "Calories & Protein Remaining" {
            let totals = state.nutritionTotals(on: LocalDay.string())
            VStack(alignment: .leading, spacing: 9) {
                nutritionProgressRow(title: "Calories", consumed: totals.calories ?? 0, goal: state.nutrition.targets.calories, unit: "kcal", color: palette.accentColor)
                nutritionProgressRow(title: "Protein", consumed: totals.protein ?? 0, goal: state.nutrition.targets.protein, unit: "g", color: .cyan)
            }
        } else if widget.kind == .calories || widget.kind == .protein || widget.kind == .macros {
            let totals = state.nutritionTotals(on: LocalDay.string())
            HStack(alignment: .bottom, spacing: 7) {
                macroPill("Protein", value: totals.protein ?? 0, color: palette.accentColor)
                macroPill("Carbs", value: totals.carbohydrates ?? 0, color: .cyan)
                macroPill("Fat", value: totals.fat ?? 0, color: .orange)
            }
        } else if widget.kind == .workoutSplit || widget.kind == .calendarHeatmap {
            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { index in
                    let done = hasWorkout(on: index - 6)
                    RoundedRectangle(cornerRadius: 4).fill(done ? palette.accentColor : palette.textColor.opacity(0.16)).frame(height: 9)
                }
            }
        } else {
            HStack {
                Image(systemName: "arrow.up.right.circle.fill").foregroundStyle(palette.accentColor)
                Text("Tap to open").font(.system(size: 10, weight: .semibold)).foregroundStyle(palette.mutedColor)
            }
        }
    }

    private func nutritionProgressRow(title: String, consumed: Double, goal: Double?, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title).font(.system(size: 10, weight: .semibold, design: .rounded))
                Spacer(minLength: 4)
                if let goal {
                    Text("\(Int(consumed)) / \(Int(goal)) \(unit) · \(Int(max(0, goal - consumed))) left")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                } else {
                    Text("Set target").font(.system(size: 9, weight: .medium, design: .rounded))
                }
            }
            .foregroundStyle(palette.textColor)
            if let goal, goal > 0 {
                ProgressView(value: min(1, consumed / goal)).tint(color)
            }
        }
    }

    private func macroPill(_ title: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Capsule().fill(color.opacity(0.9)).frame(height: 4)
            Text("\(Int(value)) g").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(palette.textColor)
            Text(title).font(.system(size: 9, weight: .medium)).foregroundStyle(palette.mutedColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func weekStart() -> String {
        let components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)
        return LocalDay.string(Calendar.current.date(from: components) ?? .now)
    }

    private func hasWorkout(on offset: Int) -> Bool {
        guard let date = Calendar.current.date(byAdding: .day, value: offset, to: .now) else { return false }
        let day = LocalDay.string(date)
        return state.training.visibleCompletedSessions.contains { $0.localDate == day }
    }

    private func weightValue(_ kg: Double) -> Double { state.home.preferredWeightUnit == "lb" ? kg * 2.2046226218 : kg }
}

private enum FoodHomeTrend: String, CaseIterable, Identifiable {
    case calories, protein, carbs, fats
    var id: String { rawValue }
    var title: String {
        switch self {
        case .calories: "Calories"
        case .protein: "Protein"
        case .carbs: "Carbs"
        case .fats: "Fats"
        }
    }
    var unit: String { self == .calories ? "kcal" : "g" }
    func value(_ totals: NutritionTargets) -> Double? {
        switch self {
        case .calories: totals.calories
        case .protein: totals.protein
        case .carbs: totals.carbohydrates
        case .fats: totals.fat
        }
    }
}

private struct FoodHomeDay: Identifiable {
    var date: Date
    var key: String
    var value: NutritionTargets
    var targets: NutritionTargets
    var id: String { key }
}

private struct DefaultFoodHomeWidgetView: View {
    let widget: HomeWidget
    let palette: ThemePalette
    let state: LogbookState
    let openFood: (FoodNavigationFocus) -> Void
    @EnvironmentObject private var store: LogbookStore
    @State private var trend: FoodHomeTrend = .calories

    private var today: String { LocalDay.string() }
    private var todayLogs: [FoodLog] { state.nutrition.logs.filter { $0.date == today && $0.deletedAt == nil } }
    private var todayWater: Int { state.nutrition.water.filter { $0.date == today && $0.deletedAt == nil }.reduce(0) { $0 + $1.milliliters } }
    private var todayTargets: NutritionTargets { state.nutritionTargets(on: today) }
    private var todayTotals: NutritionTargets { state.nutritionTotals(on: today) }
    private var waterGoal: Int? { state.nutrition.waterGoalMilliliters }
    private var days: [FoodHomeDay] {
        (0..<7).compactMap { offset in
            guard let date = Calendar.current.date(byAdding: .day, value: offset - 6, to: .now) else { return nil }
            let key = LocalDay.string(date)
            let dayLogs = state.nutrition.logs.filter { $0.date == key && $0.deletedAt == nil }
            let raw = state.nutritionTotals(on: key)
            let totals = NutritionTargets(
                calories: dayLogs.isEmpty ? nil : raw.calories,
                protein: dayLogs.isEmpty ? nil : raw.protein,
                carbohydrates: dayLogs.isEmpty ? nil : raw.carbohydrates,
                fat: dayLogs.isEmpty ? nil : raw.fat
            )
            return FoodHomeDay(date: date, key: key, value: totals, targets: state.nutritionTargets(on: key))
        }
    }
    private var trendDays: [FoodHomeDay] { days.filter { trend.value($0.value) != nil } }
    private var calorieAverage: Double? { average(days.compactMap { $0.value.calories }) }
    private var proteinAverage: Double? { average(days.compactMap { $0.value.protein }) }
    private var nutritionStreak: Int {
        state.nutritionOnTargetStreak()
    }
    private var easyNext: (title: String, reason: String, focus: FoodNavigationFocus?) {
        if todayTargets.calories == nil || todayTargets.protein == nil {
            return ("Set nutrition goals", "Choose calorie and protein targets", .targets)
        }
        if todayLogs.isEmpty { return ("Log your first meal", "Nothing has been recorded today", .addFood) }
        let proteinLeft = max(0, (todayTargets.protein ?? 0) - (todayTotals.protein ?? 0))
        if proteinLeft > 0 {
            return ("Add a protein source", "\(Int(proteinLeft)) g protein remaining", .addFood)
        }
        if let goal = todayTargets.carbohydrates, (todayTotals.carbohydrates ?? 0) < goal {
            return ("Log a balanced meal", "\(Int(goal - (todayTotals.carbohydrates ?? 0))) g carbs remaining", .addFood)
        }
        if let goal = todayTargets.fat, (todayTotals.fat ?? 0) < goal {
            return ("Log a balanced meal", "\(Int(goal - (todayTotals.fat ?? 0))) g fat remaining", .addFood)
        }
        if let goal = waterGoal, todayWater < goal {
            return ("Log water", "\(goal - todayWater) mL to your daily goal", .water)
        }
        if waterGoal == nil, todayWater == 0, Calendar.current.component(.hour, from: .now) >= 12 {
            return ("Log some water", "No water has been recorded today", .water)
        }
        if let calorieGoal = todayTargets.calories, (todayTotals.calories ?? 0) < calorieGoal * 0.95 {
            return ("Log a meal", "\(Int(calorieGoal - (todayTotals.calories ?? 0))) kcal to your target", .addFood)
        }
        if let calorieGoal = todayTargets.calories, (todayTotals.calories ?? 0) > calorieGoal * 1.05 {
            return ("Review today’s intake", "You are above the calorie target", .adherence)
        }
        return ("All caught up", "Your recorded goals are on track", nil)
    }

    var body: some View {
        Group {
            switch widget.kind {
            case .calories: trendsCard
            case .meals: mealsCard
            case .fibre: streakCard
            case .easyNext: easyNextCard
            default: EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(state.home.theme.tokens.surfaceTint.opacity(state.home.theme.tokens.cardOpacity), in: RoundedRectangle(cornerRadius: state.home.theme.tokens.cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: state.home.theme.tokens.cornerRadius, style: .continuous).stroke(palette.accentColor.opacity(state.home.theme.tokens.borderOpacity), lineWidth: 0.9))
        .shadow(color: .black.opacity(state.home.theme.tokens.shadowOpacity), radius: state.home.theme.tokens.cardShadowRadius, x: 0, y: 7)
    }

    private var trendsCard: some View {
        VStack(alignment: .leading, spacing: 5) {
            header("7-DAY NUTRITION TRENDS", icon: "chart.bar.fill")
            Picker("Food trend metric", selection: $trend) {
                ForEach(FoodHomeTrend.allCases) { item in Text(item.title).tag(item) }
            }
            .pickerStyle(.segmented)
            .controlSize(.mini)
            .font(.system(size: 8, weight: .medium))
            .accessibilityIdentifier("food-home-trend-picker")
            Chart(trendDays) { day in
                if let value = trend.value(day.value) {
                    BarMark(x: .value("Day", day.date, unit: .day), y: .value(trend.title, value))
                        .foregroundStyle(palette.accentColor.gradient)
                }
                if let goal = trend.value(day.targets) {
                    RuleMark(y: .value("Goal", goal)).foregroundStyle(palette.mutedColor.opacity(0.35)).lineStyle(StrokeStyle(dash: [2, 2]))
                }
            }
            .chartXAxis { AxisMarks(values: .stride(by: .day, count: 2)) { value in AxisValueLabel(format: .dateTime.weekday(.narrow)) } }
            .chartYAxis(.hidden)
            .frame(height: 67)
            .accessibilityIdentifier("food-home-seven-day-chart")
            HStack(spacing: 5) {
                Text("Avg \(calorieAverage.map { String(Int($0)) } ?? "—") kcal")
                Spacer(minLength: 1)
                Text("Protein \(proteinAverage.map { String(Int($0)) } ?? "—") g")
            }
            .font(.system(size: 8, weight: .medium))
            .foregroundStyle(palette.mutedColor)
            Divider().overlay(palette.mutedColor.opacity(0.25))
            HStack(spacing: 5) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("WATER · \(todayWater) / \(waterGoal.map { String($0) } ?? "—") mL")
                        .font(.system(size: 8, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.7)
                    if let waterGoal, waterGoal > 0 {
                        ProgressView(value: min(1, Double(todayWater) / Double(waterGoal))).tint(palette.accentColor)
                    }
                }
                Button {
                    store.addWater(250, date: today)
                } label: { Text("+250") }
                    .font(.system(size: 8, weight: .semibold))
                    .buttonStyle(.bordered).controlSize(.mini)
                    .accessibilityIdentifier("food-home-water-250")
                Button("Full log") { openFood(.water) }
                    .font(.system(size: 8, weight: .medium))
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("food-home-water-log")
            }
        }
        .padding(12)
    }

    private var mealsCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                header("TODAY’S MEALS", icon: "fork.knife")
                Spacer(minLength: 2)
                Button("All") { openFood(.meals) }
                    .font(.system(size: 8, weight: .medium)).buttonStyle(.plain)
                    .accessibilityIdentifier("food-home-all-meals")
                Button { openFood(.addFood) } label: { Image(systemName: "plus.circle.fill").font(.system(size: 15)) }
                    .buttonStyle(.plain).accessibilityLabel("Add Food").accessibilityIdentifier("food-home-add")
            }
            ForEach(Array(state.nutrition.meals.prefix(3).enumerated()), id: \.element.id) { index, meal in
                let entries = todayLogs.filter { $0.mealID == meal.id || $0.mealName == meal.name }
                Button { openFood(.meal(meal.id)) } label: {
                    HStack(spacing: 4) {
                        Text(meal.name.isEmpty ? "Meal \(index + 1)" : meal.name).lineLimit(1)
                        Spacer(minLength: 2)
                        Text("\(Int(entries.reduce(0) { $0 + $1.calories })) kcal · \(Int(entries.reduce(0) { $0 + $1.protein })) g P")
                            .lineLimit(1).minimumScaleFactor(0.75)
                        Image(systemName: "chevron.right").font(.system(size: 8, weight: .semibold))
                    }
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(palette.textColor)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("food-home-meal-\(meal.id.uuidString)")
                if index < min(2, state.nutrition.meals.count - 1) { Divider().overlay(palette.mutedColor.opacity(0.18)) }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
    }

    private var streakCard: some View {
        Button { openFood(.adherence) } label: {
            VStack(alignment: .leading, spacing: 6) {
                header("NUTRITION STREAK", icon: "flame.fill")
                Text("\(nutritionStreak) day\(nutritionStreak == 1 ? "" : "s")")
                    .font(.system(size: 19, weight: .semibold, design: .rounded)).foregroundStyle(palette.textColor).lineLimit(1).minimumScaleFactor(0.7)
                HStack(spacing: 5) {
                    ForEach(days) { day in
                        VStack(spacing: 2) {
                            Circle().fill(adherenceColor(state.nutritionAdherence(on: day.key))).frame(width: 9, height: 9)
                                .overlay(Circle().stroke(palette.mutedColor.opacity(0.2), lineWidth: 0.5))
                            Text(day.date.formatted(.dateTime.weekday(.narrow)))
                                .font(.system(size: 6, weight: .medium)).foregroundStyle(palette.mutedColor)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(day.date.formatted(.dateTime.weekday(.wide))), \(adherenceText(state.nutritionAdherence(on: day.key)))")
                    }
                }
                Text("View adherence history")
                    .font(.system(size: 8, weight: .medium)).foregroundStyle(palette.mutedColor).lineLimit(1).minimumScaleFactor(0.75)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("food-home-nutrition-streak")
    }

    private var easyNextCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            header("EASY NEXT", icon: "sparkles")
            Text(easyNext.title)
                .font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(palette.textColor).lineLimit(2).minimumScaleFactor(0.75)
            Text(easyNext.reason)
                .font(.system(size: 9, weight: .medium)).foregroundStyle(palette.mutedColor).lineLimit(2).minimumScaleFactor(0.75)
            Spacer(minLength: 0)
            if let destination = easyNext.focus {
                Button {
                    if destination == .water { store.addWater(250, date: today) }
                    else { openFood(destination) }
                } label: {
                    Label(destination == .water ? "Log +250 mL" : (destination == .targets ? "Set targets" : (destination == .adherence ? "Review" : "Add Food")), systemImage: destination == .water ? "drop.fill" : "arrow.right")
                        .font(.system(size: 8, weight: .semibold))
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("food-home-easy-next-action")
            }
        }
        .padding(11)
        .accessibilityElement(children: .contain)
    }

    private func header(_ title: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 9, weight: .semibold)).foregroundStyle(palette.accentColor)
            Text(title).font(.system(size: 8, weight: .semibold, design: .rounded)).tracking(0.55).foregroundStyle(palette.mutedColor).lineLimit(1).minimumScaleFactor(0.7)
        }
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func adherenceColor(_ status: LogbookState.NutritionAdherence) -> Color {
        switch status {
        case .onTarget: .green
        case .belowGoal: .orange
        case .aboveGoal: .red
        case .unlogged, .noTargets: palette.mutedColor.opacity(0.35)
        }
    }

    private func adherenceText(_ status: LogbookState.NutritionAdherence) -> String {
        switch status {
        case .onTarget: "On target"
        case .belowGoal: "Below target"
        case .aboveGoal: "Above target"
        case .unlogged: "Unlogged"
        case .noTargets: "No targets"
        }
    }
}

private struct CaloriesMacroVisual: View {
    let state: LogbookState
    let palette: ThemePalette

    private var totals: NutritionTargets { state.nutritionTotals(on: LocalDay.string()) }
    private var calorieGoal: Double? { state.nutrition.targets.calories }
    private var calorieCount: Double { totals.calories ?? 0 }
    private var caloriesLeft: Int { Int(max(0, (calorieGoal ?? 0) - calorieCount)) }

    var body: some View {
        HStack(spacing: 10) {
            VStack(spacing: 3) {
                ZStack {
                    Circle().stroke(palette.accentColor.opacity(0.18), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: calorieGoal.map { $0 > 0 ? min(1, calorieCount / $0) : 0 } ?? 0)
                        .stroke(palette.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text(calorieGoal == nil ? "—" : "\(caloriesLeft)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .lineLimit(1).minimumScaleFactor(0.65)
                        Text("kcal left").font(.system(size: 7, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(palette.textColor)
                }
                .frame(width: 62, height: 62)
                Text(calorieGoal.map { "\(Int(calorieCount))/\(Int($0)) kcal" } ?? "Set calorie goal")
                    .font(.system(size: 7.5, weight: .medium, design: .rounded))
                    .foregroundStyle(palette.mutedColor)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            VStack(spacing: 6) {
                macroRow("Protein", consumed: totals.protein ?? 0, goal: state.nutrition.targets.protein, unit: "g", color: palette.accentColor)
                macroRow("Carbs", consumed: totals.carbohydrates ?? 0, goal: state.nutrition.targets.carbohydrates, unit: "g", color: palette.mutedColor)
                macroRow("Fat", consumed: totals.fat ?? 0, goal: state.nutrition.targets.fat, unit: "g", color: palette.accentColor.opacity(0.62))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottomTrailing) {
            Label("View Food", systemImage: "chevron.right")
                .font(.system(size: 8, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.accentColor)
                .padding(.top, 2)
                .accessibilityLabel("View Food")
        }
    }

    private func macroRow(_ name: String, consumed: Double, goal: Double?, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 2) {
                Text(name).font(.system(size: 8, weight: .semibold, design: .rounded))
                Spacer(minLength: 1)
                Text(goal.map { "\(Int(consumed))/\(Int($0)) \(unit) · \(Int(max(0, $0 - consumed))) left" } ?? "\(Int(consumed)) \(unit) · Set goal")
                    .font(.system(size: 7.5, weight: .medium, design: .rounded))
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .foregroundStyle(palette.textColor)
            ProgressView(value: goal.flatMap { $0 > 0 ? min(1, consumed / $0) : nil } ?? 0)
                .tint(color)
                .accessibilityLabel("\(name), \(Int(consumed)) of \(Int(goal ?? 0)) \(unit)")
        }
    }
}

private struct WidgetPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.975 : 1).animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct ThemeBackdrop: View {
    let theme: LogbookTheme
    var body: some View {
        let tokens = theme.tokens
        GeometryReader { proxy in
            ZStack {
                tokens.backgroundBase
                Image(tokens.backgroundAsset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .overlay {
                        LinearGradient(
                            colors: [Color.black.opacity(theme == .defaultTheme ? 0.02 : theme.palette.light ? 0.04 : 0.06), Color.black.opacity(theme == .defaultTheme ? 0.08 : theme.palette.light ? 0.10 : 0.16)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
        }
        .ignoresSafeArea()
    }
}

private struct LogbookDock: View {
    @Binding var path: [LogbookRoute]
    let tokens: ThemeTokens
    let isDefault: Bool
    private let items: [(LogbookRoute, String, String)] = [
        (.training, "Training", "dumbbell.fill"), (.food, "Food", "fork.knife"), (.history, "History", "chart.bar.fill"), (.checkins, "Sleep", "moon.fill"), (.settings, "Settings", "gearshape.fill")
    ]
    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.0) { item in
                Button { path = [item.0] } label: {
                    let selected = path.last == item.0 || (path.isEmpty && item.0 == .training)
                    VStack(spacing: 4) {
                        Image(systemName: item.2).font(.system(size: 16, weight: .semibold)).frame(height: 18)
                        Text(item.1).font(.system(size: 9, weight: .semibold, design: .rounded)).lineLimit(1)
                    }
                    .foregroundStyle(isDefault ? (selected ? tokens.accent : tokens.text.opacity(0.78)) : tokens.text)
                    .frame(maxWidth: .infinity).padding(.vertical, isDefault ? 7 : 9)
                    .background {
                        if isDefault && selected {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(tokens.accent.opacity(0.17))
                                .padding(.horizontal, 2)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(item.1) tab")
            }
        }
        .padding(.horizontal, 5)
        .background(.ultraThinMaterial, in: Capsule())
        .background(tokens.surfaceTint.opacity(0.36), in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.38), lineWidth: 0.8))
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
    }
}

struct HomeEditorScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPageID: UUID?
    @State private var showGallery = false
    @State private var newPageName = ""
    @State private var showTidyConfirmation = false
    @State private var tidyPages: [HomePage] = []
    @State private var tidyMoveCount = 0

    var body: some View {
        NavigationStack {
            List {
                Section("Pages") {
                    ForEach(store.state.home.pages) { page in
                        HStack {
                            TextField("Page name", text: Binding(
                                get: { page.name },
                                set: { store.renameHomePage(page.id, name: $0) }
                            ))
                            .textInputAutocapitalization(.words)
                            .onTapGesture { selectedPageID = page.id }
                            Spacer()
                            if selectedPageID == page.id { Image(systemName: "checkmark.circle.fill").foregroundStyle(.blue) }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selectedPageID = page.id }
                    }
                    .onMove { source, destination in
                        var pages = store.state.home.pages
                        pages.move(fromOffsets: source, toOffset: destination)
                        store.setHomePages(pages)
                    }
                    HStack {
                        TextField("New page name", text: $newPageName)
                        Button("Add") {
                            store.addHomePage(name: newPageName.isEmpty ? "New Page" : newPageName)
                            selectedPageID = store.state.home.pages.last?.id
                            newPageName = ""
                        }
                        .disabled(store.state.home.pages.count >= 40)
                    }
                    if let page = selectedPage {
                        Button("Remove \(page.name) page", role: .destructive) { store.deleteHomePage(page.id); selectedPageID = store.state.home.pages.first?.id }
                            .disabled(store.state.home.pages.count <= 1)
                    }
                }
                Section("Widgets · \(selectedPage?.name ?? "Choose a page")") {
                    if let page = selectedPage {
                        ForEach(page.widgets) { widget in
                            HStack {
                                Image(systemName: widget.kind.icon).foregroundStyle(store.state.home.theme.palette.accentColor)
                                VStack(alignment: .leading) { Text(widget.variant ?? widget.kind.title); Text(widget.size.title).font(.caption).foregroundStyle(.secondary) }
                                Spacer()
                                Menu("Size") {
                                    ForEach(WidgetSize.allCases) { size in
                                        Button(size.title) { store.resizeHomeWidget(widget.id, pageID: page.id, size: size) }
                                    }
                                }
                                Menu("Move") {
                                    ForEach(store.state.home.pages) { target in
                                        Menu(target.name) {
                                            ForEach(0..<4, id: \.self) { row in
                                                ForEach(0..<2, id: \.self) { column in
                                                    Button("Row \(row + 1), Column \(column + 1)") {
                                                        _ = store.moveHomeWidget(widget.id, fromPageID: page.id, toPageID: target.id, row: row, column: column)
                                                    }
                                                    .disabled(widget.size == .large && (row > 2 || column > 0) || widget.size != .small && column > 0)
                                                }
                                            }
                                        }
                                    }
                                }
                                Button(role: .destructive) { store.removeHomeWidget(widget.id, pageID: page.id) } label: { Image(systemName: "trash") }
                            }
                        }
                        Button { showGallery = true } label: { Label("Add a widget", systemImage: "plus.app.fill") }
                    } else {
                        Text("Choose a page above to edit its widgets.").foregroundStyle(.secondary)
                    }
                }
                Section("Layout") {
                    Text("Four rows, two columns. Large widgets take two rows. Empty space is kept until you move or remove a widget.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("Preview Smart Tidy") { previewSmartTidy() }
                    Button("Undo last layout change") { store.undoHomeLayout() }
                        .disabled(store.state.home.undoPages == nil)
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Edit Home Screen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $showGallery) {
                WidgetGalleryScreen(pageID: selectedPageID)
                    .presentationDetents([.large]).presentationDragIndicator(.visible)
            }
            .confirmationDialog("Apply Smart Tidy?", isPresented: $showTidyConfirmation, titleVisibility: .visible) {
                Button("Apply Smart Tidy") { store.setHomePages(tidyPages) }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will move \(tidyMoveCount) widget\(tidyMoveCount == 1 ? "" : "s") to fill open positions. You can undo the layout afterward.")
            }
            .onAppear { selectedPageID = selectedPageID ?? store.state.home.pages.first?.id }
        }
    }

    private var selectedPage: HomePage? { store.state.home.pages.first(where: { $0.id == selectedPageID }) }

    private func previewSmartTidy() {
        guard let page = selectedPage else { return }
        let ordered = page.widgets.sorted { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row }
        var packedPages = [HomePage(id: page.id, name: page.name, widgets: [])]
        for original in ordered {
            var item = original
            let columns = item.size == .small ? 1 : 2
            let rows = item.size == .large ? 2 : 1
            var didPlace = false
            for pageIndex in packedPages.indices where !didPlace {
                for row in 0...(4 - rows) {
                    for column in 0...(2 - columns) {
                        if fits(item, row: row, column: column, beside: packedPages[pageIndex].widgets) {
                            item.row = row
                            item.column = column
                            packedPages[pageIndex].widgets.append(item)
                            didPlace = true
                            break
                        }
                    }
                    if didPlace { break }
                }
            }
            if !didPlace {
                var overflow = HomePage(name: "\(page.name) \(packedPages.count + 1)", widgets: [])
                for row in 0...(4 - rows) {
                    for column in 0...(2 - columns) {
                        if fits(item, row: row, column: column, beside: overflow.widgets) {
                            item.row = row
                            item.column = column
                            overflow.widgets.append(item)
                            didPlace = true
                            break
                        }
                    }
                    if didPlace { break }
                }
                guard didPlace else { return }
                packedPages.append(overflow)
            }
        }
        var pages = store.state.home.pages
        guard let index = pages.firstIndex(where: { $0.id == page.id }) else { return }
        let originalPositions = Dictionary(uniqueKeysWithValues: page.widgets.map { ($0.id, ($0.row, $0.column)) })
        let packedWidgets = packedPages.flatMap(\.widgets)
        tidyMoveCount = packedWidgets.filter { item in
            guard let old = originalPositions[item.id] else { return true }
            let pageChanged = packedPages.first(where: { $0.widgets.contains(where: { $0.id == item.id }) })?.id != page.id
            return old.0 != item.row || old.1 != item.column || pageChanged
        }.count
        pages[index] = packedPages[0]
        if packedPages.count > 1 { pages.insert(contentsOf: packedPages.dropFirst(), at: index + 1) }
        tidyPages = pages
        showTidyConfirmation = true
    }

    private func fits(_ item: HomeWidget, row: Int, column: Int, beside existing: [HomeWidget]) -> Bool {
        let width = item.size == .small ? 1 : 2
        let height = item.size == .large ? 2 : 1
        for r in row..<(row + height) {
            for c in column..<(column + width) {
                if existing.contains(where: { other in
                    let otherWidth = other.size == .small ? 1 : 2
                    let otherHeight = other.size == .large ? 2 : 1
                    return r >= other.row && r < other.row + otherHeight && c >= other.column && c < other.column + otherWidth
                }) { return false }
            }
        }
        return true
    }
}

struct WidgetGalleryScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    let pageID: UUID?
    @State private var search = ""
    @State private var family = "All"
    @State private var size: WidgetSize = .medium
    @State private var errorMessage: String?

    private let families = ["All", "Food", "Training", "Body", "History", "Home"]
    private var matches: [WidgetKind] {
        WidgetKind.allCases.filter { (family == "All" || $0.family == family) && (search.isEmpty || $0.title.localizedCaseInsensitiveContains(search)) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Category", selection: $family) { ForEach(families, id: \.self) { Text($0).tag($0) } }
                    Text("Choose a size preview, then tap Add.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Widget previews · \(matches.count)") {
                    ForEach(matches) { kind in
                        VStack(alignment: .leading, spacing: 11) {
                            HStack(spacing: 9) {
                                Image(systemName: kind.icon)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(store.state.home.theme.palette.accentColor)
                                    .frame(width: 30, height: 30)
                                    .background(store.state.home.theme.palette.accentColor.opacity(0.13), in: RoundedRectangle(cornerRadius: 9))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(kind.title).font(.subheadline.weight(.semibold))
                                    Text(kind.family).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 4)
                                Button { add(kind) } label: {
                                    Label("Add", systemImage: "plus.circle.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(store.state.home.theme.palette.accentColor)
                                .disabled(pageID == nil)
                            }

                            HStack(alignment: .bottom, spacing: 7) {
                                ForEach(WidgetSize.allCases) { previewSize in
                                    Button { size = previewSize } label: {
                                        VStack(spacing: 4) {
                                            WidgetSizePreview(
                                                kind: kind,
                                                size: previewSize,
                                                palette: store.state.home.theme.palette,
                                                selected: size == previewSize
                                            )
                                            Text(previewSize.title)
                                                .font(.system(size: 9, weight: size == previewSize ? .bold : .medium, design: .rounded))
                                                .foregroundStyle(size == previewSize ? store.state.home.theme.palette.accentColor : store.state.home.theme.palette.mutedColor)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Preview \(previewSize.title) \(kind.title) widget")
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Widget Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .alert("Page is full", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
        .searchable(text: $search, prompt: "Find a widget")
    }

    private func add(_ kind: WidgetKind) {
        guard let pageID else { return }
        guard store.addHomeWidget(kind, size: size, pageID: pageID) else {
            errorMessage = "This page has no open position for a \(size.title.lowercased()) widget. Choose a smaller size or add another page."
            return
        }
        dismiss()
    }
}

private struct WidgetSizePreview: View {
    let kind: WidgetKind
    let size: WidgetSize
    let palette: ThemePalette
    let selected: Bool

    private var previewWidth: CGFloat { size == .small ? 58 : 120 }
    private var previewHeight: CGFloat { size == .large ? 100 : 48 }

    private var previewMetric: String {
        switch kind.family {
        case "Food": "1,450 kcal"
        case "Training": "4 / 5 sets"
        case "Body": "7.5 hours"
        case "History": "This week"
        default: "Today"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 3) {
                Image(systemName: kind.icon).font(.system(size: 6, weight: .bold))
                Text(kind.title.uppercased())
                    .font(.system(size: 5, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Spacer(minLength: 0)
            }
            .foregroundStyle(palette.accentColor)
            Text(previewMetric)
                .font(.system(size: size == .large ? 10 : 8, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(palette.textColor)
            if size != .small {
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(0..<4, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index == 3 ? palette.accentColor.opacity(0.32) : palette.accentColor.opacity(0.8))
                            .frame(height: CGFloat([8, 13, 10, 6][index]))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer(minLength: 0)
        }
        .padding(6)
        .frame(width: previewWidth, height: previewHeight, alignment: .topLeading)
        .background(palette.surfaceColor.opacity(palette.light ? 0.88 : 0.82), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(selected ? palette.accentColor : palette.textColor.opacity(0.22), lineWidth: selected ? 2 : 0.8))
        .shadow(color: .black.opacity(selected ? 0.15 : 0.06), radius: 4, x: 0, y: 2)
    }
}
