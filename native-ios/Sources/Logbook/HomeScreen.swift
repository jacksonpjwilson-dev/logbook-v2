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
            .safeAreaInset(edge: .bottom, spacing: 0) {
                LogbookDock(path: $path, palette: palette)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 5)
            }
            .ignoresSafeArea(edges: .bottom)
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
                Image("LogbookMark").resizable().frame(width: 34, height: 34).clipShape(RoundedRectangle(cornerRadius: 9))
                Text("LOGBOOK").font(.system(size: 12, weight: .bold, design: .rounded)).tracking(2.4)
                Spacer()
                if store.state.training.activeSession != nil {
                    Button { path = [.training] } label: {
                        Label("Resume", systemImage: "play.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 11).padding(.vertical, 8)
                            .background(palette.accentColor.opacity(0.82), in: Capsule())
                            .foregroundStyle(palette.onAccentColor)
                    }
                    .accessibilityLabel("Resume active workout")
                }
                Button {
                    isEditing.toggle()
                    if isEditing { showEditor = true }
                } label: {
                    Text(isEditing ? "Done" : "Edit")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 13).padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(.white.opacity(0.34), lineWidth: 0.7))
                }
                .foregroundStyle(palette.textColor)
                .accessibilityLabel("Edit Home Screen")
            }
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()).uppercased())
                .font(.system(size: 10, weight: .medium, design: .rounded)).tracking(1.1)
                .foregroundStyle(palette.mutedColor)
            HStack(alignment: .firstTextBaseline) {
                Text("Logbook").font(.system(size: 30, weight: .bold, design: .rounded))
                Spacer()
                Text(currentPageName).font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.mutedColor).lineLimit(1)
            }
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
    let remove: (UUID) -> Void

    private let gap: CGFloat = 9

    var body: some View {
        GeometryReader { proxy in
            let columnWidth = (proxy.size.width - gap) / 2
            let rowHeight = (proxy.size.height - gap * 3) / 4
            ZStack(alignment: .topLeading) {
                ForEach(page.widgets) { widget in
                    let columns = widget.size == .small ? 1 : 2
                    let rows = widget.size == .large ? 2 : 1
                    let width = columnWidth * CGFloat(columns) + gap * CGFloat(columns - 1)
                    let height = rowHeight * CGFloat(rows) + gap * CGFloat(rows - 1)
                    Button {
                        guard !editing else { return }
                        open(route(for: widget.kind))
                    } label: {
                        HomeWidgetCard(widget: widget, palette: store.state.home.theme.palette, state: store.state)
                            .frame(width: width, height: height)
                            .overlay(alignment: .topTrailing) {
                                if editing {
                                    Button { remove(widget.id) } label: {
                                        Image(systemName: "minus")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(.white)
                                            .frame(width: 25, height: 25)
                                            .background(Color.red, in: Circle())
                                            .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 1))
                                    }
                                    .offset(x: 8, y: -7)
                                    .accessibilityLabel("Remove \(widget.kind.title) widget")
                                }
                            }
                    }
                    .buttonStyle(WidgetPressStyle())
                    .disabled(editing)
                    .position(
                        x: CGFloat(widget.column) * (columnWidth + gap) + width / 2,
                        y: CGFloat(widget.row) * (rowHeight + gap) + height / 2
                    )
                    .rotationEffect(.degrees(editing ? (widget.row + widget.column).isMultiple(of: 2) ? -0.6 : 0.6 : 0))
                    .animation(.easeInOut(duration: 0.14).repeatForever(autoreverses: true), value: editing)
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
    }

    private func route(for kind: WidgetKind) -> LogbookRoute {
        switch kind.family {
        case "Training": .training
        case "Food": .food
        case "Body": .checkins
        default: .history
        }
    }
}

private struct HomeWidgetCard: View {
    let widget: HomeWidget
    let palette: ThemePalette
    let state: LogbookState

    private var summary: (String, String) {
        let today = LocalDay.string()
        let totals = state.nutritionTotals(on: today)
        switch widget.kind {
        case .calories:
            if let target = state.nutrition.targets.calories {
                return (String(Int(max(0, target - (totals.calories ?? 0)))), "calories left · \(Int(totals.calories ?? 0)) eaten")
            }
            return ("Set your target", "Calories update from your food log")
        case .protein:
            if let target = state.nutrition.targets.protein { return (String(Int(max(0, target - (totals.protein ?? 0)))) + " g", "protein remaining") }
            return ("No target", "Set a protein goal in Food")
        case .macros:
            return ("\(Int(totals.protein ?? 0)) g protein", "\(Int(totals.carbohydrates ?? 0)) g carbs · \(Int(totals.fat ?? 0)) g fat")
        case .water:
            let amount = state.nutrition.water.filter { $0.date == today }.reduce(0) { $0 + $1.milliliters }
            return ("\(amount) mL", "water logged today")
        case .meals:
            let count = state.nutrition.logs.filter { $0.date == today }.count
            return ("\(count) food entries", "across \(state.nutrition.meals.count) meals")
        case .nextWorkout, .workoutSplit, .upcomingPlan:
            if let active = state.training.activeSession { return (active.templateName, "Workout in progress") }
            if let template = state.training.templates.first { return (template.name, "\(state.training.templates.count) workout plan\(state.training.templates.count == 1 ? "" : "s")") }
            return ("No workout planned", "Create a plan in Training")
        case .thisWeek:
            let sessions = state.training.completedSessions.filter { $0.localDate >= weekStart() }
            return ("\(sessions.count) workouts", "completed this week")
        case .lastWorkout:
            if let last = state.training.completedSessions.max(by: { ($0.finishedAt ?? .distantPast) < ($1.finishedAt ?? .distantPast) }) {
                return (last.templateName, last.localDate)
            }
            return ("No sessions yet", "Your completed workouts will appear here")
        case .personalRecords:
            let records = state.training.completedSessions.flatMap(\.exercises).flatMap(\.sets).filter(\.completed).count
            return ("\(records) logged sets", "Personal records build from completed sets")
        case .lastNight, .sleepChart, .sleepConsistency:
            guard let sleep = state.checkins.sleep.max(by: { $0.wakeDate < $1.wakeDate }) else { return ("No sleep logged", "Add a check-in when you wake") }
            return (String(format: "%.1f hours", Double(sleep.durationMinutes) / 60), "last recorded sleep")
        case .weight, .weightTrend:
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
        case .fibre, .mealTiming, .weeklyCalories, .easyNext, .quickLog, .bedtimeTarget:
            return (widget.variant ?? widget.kind.title, "Open to view details")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: widget.kind.icon).font(.system(size: 11, weight: .semibold)).foregroundStyle(palette.accentColor)
                Text(widget.variant ?? widget.kind.title.uppercased())
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 25, style: .continuous))
        .background(palette.surfaceColor.opacity(palette.light ? 0.30 : 0.22), in: RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 25, style: .continuous).stroke(.white.opacity(palette.light ? 0.62 : 0.31), lineWidth: 0.8))
        .shadow(color: .black.opacity(0.13), radius: 12, x: 0, y: 7)
        .contentShape(RoundedRectangle(cornerRadius: 25))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(widget.variant ?? widget.kind.title), \(summary.0), \(summary.1). Open details.")
    }

    @ViewBuilder private var detailVisual: some View {
        if widget.kind == .calories || widget.kind == .protein || widget.kind == .macros {
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
        return state.training.completedSessions.contains { $0.localDate == day }
    }

    private func weightValue(_ kg: Double) -> Double { state.home.preferredWeightUnit == "lb" ? kg * 2.2046226218 : kg }
}

private struct WidgetPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.scaleEffect(configuration.isPressed ? 0.975 : 1).animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct ThemeBackdrop: View {
    let theme: LogbookTheme
    var body: some View {
        GeometryReader { proxy in
            Image(theme.rawValue)
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .overlay {
                    LinearGradient(colors: [Color.black.opacity(theme.palette.light ? 0.10 : 0.22), Color.black.opacity(theme.palette.light ? 0.12 : 0.36)], startPoint: .top, endPoint: .bottom)
                }
                .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }
}

private struct LogbookDock: View {
    @Binding var path: [LogbookRoute]
    let palette: ThemePalette
    private let items: [(LogbookRoute, String, String)] = [
        (.training, "Training", "dumbbell.fill"), (.food, "Food", "fork.knife"), (.history, "History", "chart.bar.fill"), (.checkins, "Sleep", "moon.fill"), (.settings, "Settings", "gearshape.fill")
    ]
    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.0) { item in
                Button { path = [item.0] } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.2).font(.system(size: 16, weight: .semibold)).frame(height: 18)
                        Text(item.1).font(.system(size: 9, weight: .semibold, design: .rounded)).lineLimit(1)
                    }
                    .foregroundStyle(palette.textColor)
                    .frame(maxWidth: .infinity).padding(.vertical, 9)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(item.1) tab")
            }
        }
        .padding(.horizontal, 5)
        .background(.ultraThinMaterial, in: Capsule())
        .background(palette.surfaceColor.opacity(0.36), in: Capsule())
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
                    Picker("Size", selection: $size) { ForEach(WidgetSize.allCases) { Text($0.title).tag($0) } }
                }
                Section("Available widgets · \(matches.count)") {
                    ForEach(matches) { kind in
                        Button {
                            guard let pageID else { return }
                            guard store.addHomeWidget(kind, size: size, pageID: pageID) else {
                                errorMessage = "This page has no open position for a \(size.title.lowercased()) widget. Choose a smaller size or add another page."
                                return
                            }
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: kind.icon).frame(width: 34, height: 34).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading, spacing: 3) { Text(kind.title).font(.headline); Text(kind.family).font(.caption).foregroundStyle(.secondary) }
                                Spacer()
                                Image(systemName: "plus.circle.fill").foregroundStyle(store.state.home.theme.palette.accentColor)
                            }
                        }
                        .foregroundStyle(.primary)
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
}
