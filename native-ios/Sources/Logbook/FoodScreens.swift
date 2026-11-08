import Charts
import SwiftUI

private enum FoodEntryMode: String { case search, recent, scan, manual }
private enum FoodPresentedSheet: Identifiable {
    case addFood(mode: FoodEntryMode, meal: MealSlot, date: String)
    case targets(date: String)
    case copyMeals(date: String)
    case recipeBuilder
    case editRecipe(FoodRecipe)
    case waterGoal
    case waterEntry(date: String)

    var id: String {
        switch self {
        case .addFood(let mode, let meal, let date): "add-\(mode.rawValue)-\(meal.id)-\(date)"
        case .targets(let date): "targets-\(date)"
        case .copyMeals(let date): "copy-\(date)"
        case .recipeBuilder: "recipe-builder"
        case .editRecipe(let recipe): "edit-recipe-\(recipe.id)"
        case .waterGoal: "water-goal"
        case .waterEntry(let date): "water-entry-\(date)"
        }
    }
}
private enum FoodTrendMetric: String, CaseIterable, Identifiable, Hashable {
    case calories, protein, carbohydrates, fat
    var id: String { rawValue }
    var title: String {
        switch self {
        case .calories: "Calories"
        case .protein: "Protein"
        case .carbohydrates: "Carbs"
        case .fat: "Fats"
        }
    }
    var unit: String { self == .calories ? "kcal" : "g" }
    func value(in totals: NutritionTargets) -> Double? {
        switch self {
        case .calories: totals.calories
        case .protein: totals.protein
        case .carbohydrates: totals.carbohydrates
        case .fat: totals.fat
        }
    }
}

struct FoodScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @State private var selectedDate = Calendar.current.startOfDay(for: .now)
    @State private var selectedMealID: UUID?
    @State private var expandedMealIDs = Set<UUID>()
    @State private var trendMetric: FoodTrendMetric = .calories
    @State private var addFoodMenu = false
    @State private var presentedSheet: FoodPresentedSheet?
    @State private var renameMealID: UUID?
    @State private var mealNameDraft = ""

    private var dateKey: String { LocalDay.string(selectedDate) }
    private var selectedDateBinding: Binding<Date> {
        Binding(
            get: { selectedDate },
            set: { selectedDate = Calendar.current.startOfDay(for: $0) }
        )
    }
    private var logs: [FoodLog] { store.state.nutrition.logs.filter { $0.date == dateKey && $0.deletedAt == nil } }
    private var totals: NutritionTargets { store.state.nutritionTotals(on: dateKey) }
    private var targets: NutritionTargets { store.state.nutritionTargets(on: dateKey) }
    private var waterLogs: [WaterLog] { store.state.nutrition.water.filter { $0.date == dateKey && $0.deletedAt == nil }.sorted { $0.createdAt > $1.createdAt } }
    private var waterTotal: Int { waterLogs.reduce(0) { $0 + $1.milliliters } }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                nutritionSummarySection
                mealsSection
                hydrationSection
                nutritionTrendsSection
                foodToolsSection
            }
            .navigationTitle("Food")
            .onAppear { applyPendingFoodFocus(using: proxy) }
            .onChange(of: store.foodNavigationFocus) { _, _ in applyPendingFoodFocus(using: proxy) }
        }
        .confirmationDialog("Add Food", isPresented: $addFoodMenu, titleVisibility: .visible) {
                Button("Search Foods") { presentFoodEntry(.search) }
                    .accessibilityIdentifier("food-option-search")
                Button("Scan Barcode") { presentFoodEntry(.scan) }
                    .accessibilityIdentifier("food-option-scan")
                Button("Manual Entry") { presentFoodEntry(.manual) }
                    .accessibilityIdentifier("food-option-manual")
                Button("Recent Foods") { presentFoodEntry(.recent) }
                    .accessibilityIdentifier("food-option-recent")
                Button("Cancel", role: .cancel) {}
            } message: { Text("Search Foods, Scan Barcode, Manual Entry, or Recent Foods") }
            .sheet(item: $presentedSheet) { sheet in
                Group {
                    switch sheet {
                    case .addFood(let mode, let meal, let date):
                        FoodAddFlowScreen(mode: mode, meal: meal, date: date).presentationDetents([.large])
                    case .targets(let date):
                        NutritionTargetsScreen(effectiveDate: date).presentationDetents([.medium, .large])
                    case .copyMeals(let date):
                        CopyMealsScreen(destinationDate: date).presentationDetents([.medium, .large])
                    case .recipeBuilder:
                        RecipeEditorScreen().presentationDetents([.large])
                    case .editRecipe(let recipe):
                        RecipeEditorScreen(recipe: recipe).presentationDetents([.large])
                    case .waterGoal:
                        WaterGoalScreen().presentationDetents([.medium])
                    case .waterEntry(let date):
                        WaterEntryScreen(date: date).presentationDetents([.medium, .large])
                    }
                }
                .presentationDragIndicator(.visible)
            }
            .alert("Rename meal", isPresented: Binding(get: { renameMealID != nil }, set: { if !$0 { renameMealID = nil } })) {
                TextField("Meal name", text: $mealNameDraft)
                Button("Save") { if let renameMealID { store.renameMeal(renameMealID, name: mealNameDraft) }; renameMealID = nil }
                Button("Cancel", role: .cancel) { renameMealID = nil }
            } message: { Text("Past food entries keep the meal name recorded when they were logged.") }
    }

    private func applyPendingFoodFocus(using proxy: ScrollViewProxy) {
        guard let focus = store.consumeFoodNavigationFocus() else { return }
        switch focus {
        case .meal(let id):
            selectedDate = Calendar.current.startOfDay(for: .now)
            selectedMealID = id
            expandedMealIDs.insert(id)
            DispatchQueue.main.async { withAnimation { proxy.scrollTo("food-meal-\(id.uuidString)", anchor: .center) } }
        case .meals:
            selectedDate = Calendar.current.startOfDay(for: .now)
            DispatchQueue.main.async { withAnimation { proxy.scrollTo("food-meals", anchor: .center) } }
        case .addFood:
            selectedDate = Calendar.current.startOfDay(for: .now)
            selectedMealID = suggestedMealID
            addFoodMenu = true
        case .water:
            selectedDate = Calendar.current.startOfDay(for: .now)
            DispatchQueue.main.async { withAnimation { proxy.scrollTo("food-hydration", anchor: .center) } }
        case .adherence:
            DispatchQueue.main.async { withAnimation { proxy.scrollTo("food-trends", anchor: .center) } }
        case .targets:
            selectedDate = Calendar.current.startOfDay(for: .now)
            presentedSheet = .targets(date: dateKey)
        }
    }

    private var nutritionSummarySection: some View {
        Section {
            HStack(spacing: 18) {
                Button { shiftDay(-1) } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Previous food day")
                .accessibilityIdentifier("food-day-previous")
                DatePicker("Choose Food Log date", selection: selectedDateBinding, displayedComponents: .date)
                    .datePickerStyle(.compact).labelsHidden().accessibilityIdentifier("food-day-picker")
                Button { shiftDay(1) } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Next food day")
                .accessibilityIdentifier("food-day-next")
            }
            .frame(maxWidth: .infinity)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Calories").font(.caption).foregroundStyle(.secondary)
                    Text("\(Int(totals.calories ?? 0))").font(.system(size: 30, weight: .bold, design: .rounded)).accessibilityIdentifier("food-calories-total")
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(remaining(targets.calories, totals.calories)) kcal left").font(.headline)
                    Text(dateKey).font(.caption).foregroundStyle(.secondary)
                        .id("food-date-key-\(dateKey)")
                        .accessibilityIdentifier("food-date-key")
                }
            }
            ProgressView(value: ratio(totals.calories, targets.calories)).tint(store.state.home.theme.palette.accentColor)
            HStack(spacing: 6) {
                MacroTile(name: "Protein", value: totals.protein ?? 0, goal: targets.protein, color: .teal)
                MacroTile(name: "Carbs", value: totals.carbohydrates ?? 0, goal: targets.carbohydrates, color: .blue)
                MacroTile(name: "Fat", value: totals.fat ?? 0, goal: targets.fat, color: .orange)
            }
            .accessibilityIdentifier("food-macro-swipe-area")
            .accessibilityElement(children: .combine)
            .contentShape(Rectangle())
            .highPriorityGesture(DragGesture(minimumDistance: 20).onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > max(32, abs(vertical) * 1.25) else { return }
                shiftDay(horizontal < 0 ? 1 : -1)
            })
        } header: {
            HStack {
                Text(selectedDate.formatted(date: .complete, time: .omitted))
                Spacer()
                Button("Targets") { presentedSheet = .targets(date: dateKey) }.accessibilityIdentifier("food-targets")
            }
        }
        .id("food-nutrition-summary-\(dateKey)")
    }

    private var mealsSection: some View {
        Section {
            ForEach(store.state.nutrition.meals) { meal in
                mealRow(meal)
            }
            Button { store.addMeal(name: "Meal \(store.state.nutrition.meals.count + 1)") } label: {
                Label("Add meal", systemImage: "rectangle.stack.badge.plus")
            }
            Button {
                selectedMealID = suggestedMealID
                addFoodMenu = true
            } label: { Label("Add Food", systemImage: "plus.circle.fill") }
                .accessibilityIdentifier("food-add-food")
        } header: { Text("Meals") }
            .id("food-meals")
    }

    private func mealRow(_ meal: MealSlot) -> some View {
        let mealLogs = logs.filter { $0.mealID == meal.id || $0.mealName == meal.name }
        return DisclosureGroup(isExpanded: Binding(
            get: { expandedMealIDs.contains(meal.id) },
            set: { isExpanded in
                if isExpanded { expandedMealIDs.insert(meal.id) }
                else { expandedMealIDs.remove(meal.id) }
            }
        )) {
            if mealLogs.isEmpty { Text("Nothing logged yet.").font(.caption).foregroundStyle(.secondary) }
            ForEach(mealLogs) { log in
                NavigationLink(destination: FoodLogEditorScreen(logID: log.id)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(log.foodName)
                        Text("\(format(log.quantity)) \(log.unit) · \(Int(log.calories)) kcal · \(Int(log.protein)) g protein")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .accessibilityIdentifier("food-log-\(log.id.uuidString)")
                .swipeActions { Button("Delete", role: .destructive) { store.deleteFoodLog(log.id) } }
            }
            Button {
                selectedMealID = meal.id
                presentFoodEntry(.search)
            } label: { Label("Add to Meal", systemImage: "plus") }
                .accessibilityIdentifier("add-to-meal-\(meal.id.uuidString)")
        } label: {
            HStack {
                Text(meal.name).font(.headline)
                Spacer()
                Text("\(mealLogs.count) items · \(Int(mealLogs.reduce(0) { $0 + $1.calories })) kcal")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .id("food-meal-\(meal.id.uuidString)")
        .contextMenu {
            Button("Rename meal", systemImage: "pencil") {
                renameMealID = meal.id
                mealNameDraft = meal.name
            }
        }
    }

    private var hydrationSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Water").font(.headline)
                    Text("\(waterTotal) mL" + (store.state.nutrition.waterGoalMilliliters.map { " of \($0) mL" } ?? " logged"))
                        .font(.caption).foregroundStyle(.secondary).accessibilityIdentifier("food-water-total")
                }
                Spacer()
                ForEach([250, 500, 750], id: \.self) { amount in
                    Button("+\(amount)") { store.addWater(amount, date: dateKey) }
                        .buttonStyle(.bordered).controlSize(.small).accessibilityIdentifier("water-quick-\(amount)")
                }
            }
            Button("Add custom amount…") { presentedSheet = .waterEntry(date: dateKey) }
                .accessibilityIdentifier("water-custom-entry")
            if let goal = store.state.nutrition.waterGoalMilliliters {
                ProgressView(value: min(1, Double(waterTotal) / Double(max(1, goal))))
            }
            ForEach(waterLogs) { log in
                NavigationLink(destination: WaterLogEditorScreen(logID: log.id)) {
                    LabeledContent("\(log.milliliters) mL", value: log.createdAt.formatted(date: .omitted, time: .shortened))
                }
                .accessibilityIdentifier("water-history-\(log.id.uuidString)")
            }
            Button("Water goal…") { presentedSheet = .waterGoal }.accessibilityIdentifier("water-goal-edit")
        } header: { Text("Hydration") }
            .id("food-hydration")
    }

    private var nutritionTrendsSection: some View {
        let days = lastSevenDays(endingAt: selectedDate)
        let calorieAverage = average(days.compactMap { $0.value.calories })
        let proteinAverage = average(days.compactMap { $0.value.protein })
        return Section {
            Picker("Nutrition trend", selection: $trendMetric) {
                ForEach(FoodTrendMetric.allCases) { metric in Text(metric.title).tag(metric) }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("food-trend-metric")
            Chart(days, id: \.key) { item in
                if let value = trendMetric.value(in: item.value) {
                    BarMark(x: .value("Day", item.key), y: .value(trendMetric.title, value))
                    .foregroundStyle(.blue.gradient)
                }
                if trendMetric == .calories, let goal = store.state.nutritionTargets(on: item.key).calories {
                    RuleMark(y: .value("Target", goal)).foregroundStyle(.secondary.opacity(0.5)).lineStyle(StrokeStyle(dash: [3, 3]))
                }
            }
            .frame(height: 150)
            .accessibilityIdentifier("food-seven-day-chart")
            .accessibilityLabel("\(trendMetric.title) over the last seven days")
            HStack {
                Text("Logged-day avg · \(calorieAverage.map(format) ?? "—") kcal")
                    .accessibilityIdentifier("food-average-calories")
                Spacer(minLength: 8)
                Text("Protein avg · \(proteinAverage.map(format) ?? "—") g")
                    .accessibilityIdentifier("food-average-protein")
            }
            .font(.caption)
            ForEach(days, id: \.key) { item in
                HStack {
                    Text(item.date.formatted(.dateTime.weekday(.abbreviated).day()))
                    Spacer()
                    Text(trendMetric.value(in: item.value).map { "\(Int($0)) \(trendMetric.unit)" } ?? "No log")
                    Text(adherenceLabel(store.state.nutritionAdherence(on: item.key)))
                        .foregroundStyle(adherenceColor(store.state.nutritionAdherence(on: item.key)))
                        .frame(width: 92, alignment: .trailing)
                }
                .font(.caption)
            }
        } header: { Text("Nutrition trends · 7 days") }
            .id("food-trends")
    }

    private var foodToolsSection: some View {
        Section {
            NavigationLink("Food History") { FoodHistoryScreen() }.accessibilityIdentifier("food-history-link")
            NavigationLink("Recently Deleted") { RecentlyDeletedFoodScreen() }.accessibilityIdentifier("food-recently-deleted-link")
            Button { presentedSheet = .copyMeals(date: dateKey) } label: { Label("Copy meals or day…", systemImage: "doc.on.doc") }
                .accessibilityIdentifier("food-copy-meals")
            Button { presentedSheet = .recipeBuilder } label: { Label("Create recipe", systemImage: "book.closed") }
                .accessibilityIdentifier("food-create-recipe")
            if let recipes = store.state.nutrition.recipes?.filter({ $0.deletedAt == nil }), !recipes.isEmpty {
                ForEach(recipes) { recipe in recipeRow(recipe) }
            }
        } header: { Text("Food tools") }
    }

    private func recipeRow(_ recipe: FoodRecipe) -> some View {
        Button {
            selectedMealID = suggestedMealID
            _ = store.logFood(store.foodDefinition(for: recipe), meal: currentMeal, quantity: 1, unit: recipe.yieldUnit, confirmed: true, date: dateKey)
        } label: {
            HStack {
                Label("Log \(recipe.name)", systemImage: "book.closed.fill")
                Spacer()
                Text("\(Int(store.foodDefinition(for: recipe).calories)) kcal / \(recipe.yieldUnit.dropLast())")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .accessibilityIdentifier("log-recipe-\(recipe.id)")
        .contextMenu {
            Button("Edit recipe", systemImage: "pencil") { presentedSheet = .editRecipe(recipe) }
            Button("Delete recipe", systemImage: "trash", role: .destructive) { store.deleteRecipe(recipe.id) }
        }
    }

    private var currentMeal: MealSlot {
        store.state.nutrition.meals.first(where: { $0.id == (selectedMealID ?? suggestedMealID) }) ?? store.state.nutrition.meals.first ?? MealSlot(name: "Meal 1")
    }
    private func presentFoodEntry(_ mode: FoodEntryMode) {
        presentedSheet = .addFood(mode: mode, meal: currentMeal, date: dateKey)
    }
    private var suggestedMealID: UUID? {
        guard !store.state.nutrition.meals.isEmpty else { return nil }
        let hour = Calendar.current.component(.hour, from: .now)
        let index = hour < 11 ? 0 : (hour < 16 ? 1 : 2)
        return store.state.nutrition.meals[min(index, store.state.nutrition.meals.count - 1)].id
    }
    private func shiftDay(_ amount: Int) {
        var calendar = Calendar.autoupdatingCurrent
        calendar.timeZone = .autoupdatingCurrent
        let dayStart = calendar.startOfDay(for: selectedDate)
        if let date = calendar.date(byAdding: .day, value: amount, to: dayStart) {
            selectedDate = calendar.startOfDay(for: date)
        }
    }
    private func ratio(_ value: Double?, _ goal: Double?) -> Double { min(1, max(0, (value ?? 0) / max(1, goal ?? 1))) }
    private func remaining(_ goal: Double?, _ value: Double?) -> Int { max(0, Int((goal ?? 0) - (value ?? 0))) }
    private func format(_ value: Double) -> String { value.formatted(.number.precision(.fractionLength(0...2))) }
    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
    private func lastSevenDays(endingAt end: Date) -> [(key: String, date: Date, value: NutritionTargets)] {
        (0..<7).compactMap { offset in
            guard let date = Calendar.current.date(byAdding: .day, value: offset - 6, to: end) else { return nil }
            let key = LocalDay.string(date)
            return (key, date, store.state.nutritionTotals(on: key))
        }
    }
}

private func adherenceLabel(_ value: LogbookState.NutritionAdherence) -> String {
    switch value {
    case .unlogged: "Not logged"
    case .noTargets: "No targets"
    case .belowGoal: "Below goal"
    case .aboveGoal: "Above goal"
    case .onTarget: "On target"
    }
}

private func adherenceColor(_ value: LogbookState.NutritionAdherence) -> Color {
    switch value {
    case .unlogged, .noTargets: .secondary
    case .belowGoal, .aboveGoal: .orange
    case .onTarget: .green
    }
}

private struct MacroTile: View {
    let name: String
    let value: Double
    let goal: Double?
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(name).font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            Text("\(Int(value)) / \(goal.map { "\(Int($0)) g" } ?? "—")").font(.system(size: 12, weight: .semibold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.75)
            ProgressView(value: min(1, value / max(1, goal ?? 1))).tint(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(7)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct FoodAddFlowScreen: View {
    let mode: FoodEntryMode
    let meal: MealSlot
    let date: String
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFood: FoodDefinition?
    @State private var showManual = false
    @State private var barcode = ""
    @State private var lookingUpBarcode = false
    @State private var errorMessage: String?
    @State private var cameraCode: String?

    var body: some View {
        Group {
            if mode == .manual {
                ManualFoodEntryScreen(meal: meal, date: date)
            } else {
                NavigationStack {
            Group {
                switch mode {
                case .search, .recent:
                    FoodSearchScreen(recentOnly: mode == .recent, onSelect: { selectedFood = $0 })
                case .manual:
                    EmptyView()
                case .scan:
                    VStack(spacing: 16) {
                        if !ProcessInfo.processInfo.arguments.contains("--ui-testing") {
                            FoodBarcodeCamera { cameraCode = $0 }
                                .frame(maxWidth: .infinity, maxHeight: 360)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        } else {
                            ContentUnavailableView("Barcode scanner", systemImage: "barcode.viewfinder", description: Text("Camera scanning is represented by manual barcode entry in simulator tests."))
                                .frame(maxHeight: 240)
                        }
                        TextField("Enter barcode", text: $barcode).keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder).accessibilityIdentifier("barcode-entry")
                        Button(lookingUpBarcode ? "Looking up…" : "Look up barcode") { Task { await lookupBarcode(barcode) } }
                            .buttonStyle(.borderedProminent).disabled(lookingUpBarcode || barcode.isEmpty)
                            .accessibilityIdentifier("barcode-lookup")
                        Button("Enter food manually") { showManual = true }.accessibilityIdentifier("barcode-manual-fallback")
                        if let errorMessage { Text(errorMessage).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center) }
                    }
                    .padding()
                }
            }
            .navigationTitle(mode == .recent ? "Recent Foods" : (mode == .scan ? "Scan Barcode" : "Search Foods"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.accessibilityIdentifier("food-add-done") } }
            .sheet(item: $selectedFood) { food in
                FoodQuantityConfirmationScreen(food: food, meal: meal, date: date)
                    .presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showManual) {
                ManualFoodEntryScreen(meal: meal, date: date).presentationDetents([.large]).presentationDragIndicator(.visible)
            }
            .onChange(of: cameraCode) { _, value in
                guard let value else { return }
                barcode = value
                Task { await lookupBarcode(value) }
            }
                }
            }
        }
    }

    @MainActor private func lookupBarcode(_ code: String) async {
        lookingUpBarcode = true
        errorMessage = nil
        defer { lookingUpBarcode = false }
        do {
            if let food = try await FoodCatalogService.shared.lookupBarcode(code) {
                store.cacheFoodDefinitions([food])
                selectedFood = food
            } else {
                errorMessage = "Barcode not found. Enter the food and label values manually; Logbook will not associate this barcode with your manual item."
                showManual = true
            }
        } catch {
            errorMessage = "Barcode lookup failed. Check your connection or enter the food manually. No barcode was saved."
        }
    }
}

private struct FoodSearchScreen: View {
    @EnvironmentObject private var store: LogbookStore
    let recentOnly: Bool
    let onSelect: (FoodDefinition) -> Void
    @State private var query = ""
    @State private var favoriteOnly = false
    @State private var remoteFoods: [FoodDefinition] = []
    @State private var isSearching = false
    @State private var searchError: String?

    private var favorites: Set<String> { Set(store.state.nutrition.favoriteFoodIDs ?? []) }
    private var recentFoods: [FoodDefinition] {
        var seen = Set<String>()
        return store.state.nutrition.logs.filter { $0.deletedAt == nil }.sorted { $0.confirmedAt > $1.confirmedAt }.compactMap { log in
            guard seen.insert(log.foodID).inserted else { return nil }
            return store.state.nutrition.foods.first { $0.id == log.foodID }
        }
    }
    private var visibleFoods: [FoodDefinition] {
        let savedRecipes = (store.state.nutrition.recipes ?? []).filter { $0.deletedAt == nil }.map { store.foodDefinition(for: $0) }
        let searchableFoods = store.state.nutrition.foods + savedRecipes
        let local = recentOnly ? recentFoods : searchableFoods.filter {
            query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) || ($0.barcode?.contains(query) ?? false)
        }
        let combined = local + (recentOnly ? [] : remoteFoods)
        var seen = Set<String>()
        return combined.filter { food in
            seen.insert(food.id).inserted && (!favoriteOnly || favorites.contains(food.id))
        }
    }

    var body: some View {
        List {
            if !recentOnly {
                Toggle("Favorites only", isOn: $favoriteOnly).accessibilityIdentifier("food-favorites-filter")
            }
            if isSearching { ProgressView("Searching Canadian Nutrient File and Open Food Facts…") }
            if let searchError { Text(searchError).font(.footnote).foregroundStyle(.secondary) }
            Section(recentOnly ? "Recently logged" : (favoriteOnly ? "Favorites" : "Foods")) {
                ForEach(visibleFoods) { food in
                    HStack(spacing: 10) {
                        Button { onSelect(food) } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(food.name).font(.headline)
                                Text("\(Int(food.calories)) kcal · \(Int(food.protein)) g protein per \(food.basisAmount.formatted()) \(food.basisUnit)")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(food.source).font(.caption2).foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("food-search-result-\(food.id)")
                        Button {
                            store.setFoodFavorite(food.id, isFavorite: !favorites.contains(food.id))
                        } label: {
                            Image(systemName: favorites.contains(food.id) ? "star.fill" : "star")
                                .foregroundStyle(favorites.contains(food.id) ? .yellow : .secondary)
                        }
                        .buttonStyle(.plain).accessibilityLabel(favorites.contains(food.id) ? "Remove favorite" : "Add favorite")
                        .accessibilityIdentifier("food-favorite-\(food.id)")
                    }
                }
                if visibleFoods.isEmpty && !isSearching {
                    ContentUnavailableView(recentOnly ? "No recent foods" : "No matching foods", systemImage: "fork.knife", description: Text(recentOnly ? "Logged foods are saved here for quick access." : "Search the local catalog and the Canadian Nutrient File / Open Food Facts, or use Manual Entry."))
                }
            }
            if !recentOnly {
                Section { Text("Canadian Nutrient File · Health Canada. Packaged-product data from Open Food Facts is community-contributed under its database license. Review provider values and verify the package label. Unverified portions are not offered as servings.").font(.caption2).foregroundStyle(.secondary) }
            }
        }
        .searchable(text: $query, prompt: "Food or product name")
        .task(id: query) { await runSearch(query) }
    }

    @MainActor private func runSearch(_ value: String) async {
        remoteFoods = []
        searchError = nil
        guard !recentOnly, value.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else { return }
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }
        isSearching = true
        defer { isSearching = false }
        do {
            let found = try await FoodCatalogService.shared.search(value)
            guard !Task.isCancelled else { return }
            remoteFoods = found
            store.cacheFoodDefinitions(found)
        } catch {
            searchError = "Online providers are unavailable. Saved foods, recent foods and manual entry still work offline."
        }
    }
}

private struct FoodQuantityConfirmationScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    let food: FoodDefinition
    let meal: MealSlot
    let date: String
    @State private var quantity: Double
    @State private var unit: String

    init(food: FoodDefinition, meal: MealSlot, date: String) {
        self.food = food; self.meal = meal; self.date = date
        let options = FoodQuantityConfirmationScreen.units(for: food)
        let initialUnit = options.first ?? food.basisUnit
        _unit = State(initialValue: initialUnit)
        let initialQuantity: Double
        switch initialUnit {
        case "g": initialQuantity = food.basisAmount
        case "oz": initialQuantity = food.basisAmount * 0.0352739619
        default: initialQuantity = 1
        }
        _quantity = State(initialValue: initialQuantity)
    }

    private var multiplier: Double { food.multiplier(for: quantity, unit: unit) ?? 0 }
    private static func units(for food: FoodDefinition) -> [String] {
        guard food.basisUnit.caseInsensitiveCompare("g") == .orderedSame else { return [food.basisUnit] }
        var result = ["g", "oz"]
        if let serving = food.verifiedServingGrams, serving > 0 { result.append("serving") }
        return result
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Confirm amount · \(meal.name)") {
                    Text(food.name).font(.headline)
                    HStack {
                        TextField("Amount", value: $quantity, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad).accessibilityIdentifier("food-quantity")
                        Picker("Unit", selection: $unit) {
                            ForEach(Self.units(for: food), id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu).accessibilityIdentifier("food-quantity-unit")
                    }
                    Text("\(date) · \(food.source)").font(.caption).foregroundStyle(.secondary)
                }
                Section("Nutrition preview") {
                    LabeledContent("Calories", value: "\(Int(food.calories * multiplier)) kcal")
                    LabeledContent("Protein", value: "\(Int(food.protein * multiplier)) g")
                    LabeledContent("Carbohydrates", value: "\(Int(food.carbohydrates * multiplier)) g")
                    LabeledContent("Fat", value: "\(Int(food.fat * multiplier)) g")
                }
            }
            .navigationTitle("Review food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log food") {
                        if store.logFood(food, meal: meal, quantity: quantity, unit: unit, confirmed: true, date: date) { dismiss() }
                    }
                    .disabled(quantity <= 0 || multiplier <= 0).accessibilityIdentifier("food-confirm-log")
                }
            }
        }
    }
}

private struct ManualFoodEntryScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    let meal: MealSlot
    let date: String
    @State private var name = ""
    @State private var basisAmount = "100"
    @State private var basisUnit = "g"
    @State private var logAmount = "100"
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @FocusState private var numericFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Food and serving") {
                    TextField("Name", text: $name).accessibilityIdentifier("manual-food-name")
                    HStack { TextField("Nutrition basis amount", text: $basisAmount).keyboardType(.decimalPad).focused($numericFieldFocused); Picker("Unit", selection: $basisUnit) { ForEach(["g", "oz", "ml", "serving", "piece"], id: \.self) { Text($0).tag($0) } }.pickerStyle(.menu) }
                    HStack { Text("Amount to log"); Spacer(); TextField("Amount", text: $logAmount).keyboardType(.decimalPad).focused($numericFieldFocused).multilineTextAlignment(.trailing).frame(width: 100).accessibilityIdentifier("manual-food-quantity"); Text(basisUnit).foregroundStyle(.secondary) }
                }
                Section("Nutrition for the basis amount") {
                    numeric("Calories", text: $calories, unit: "kcal")
                    numeric("Protein", text: $protein, unit: "g")
                    numeric("Carbohydrates", text: $carbs, unit: "g")
                    numeric("Fat", text: $fat, unit: "g")
                }
                Text("Enter values from the label or a trusted source. Manual entries are saved only to your personal food library. Unknown barcodes are never linked automatically.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save & Log") { save() }
                        .disabled(!isValid).accessibilityIdentifier("manual-food-save")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { numericFieldFocused = false }.accessibilityIdentifier("keyboard-done")
                }
            }
        }
    }
    private var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let basis = Double(basisAmount), basis > 0,
              let quantity = Double(logAmount), quantity > 0 else { return false }
        return [calories, protein, carbs, fat].allSatisfy { value in Double(value).map { $0.isFinite && $0 >= 0 } ?? false }
    }
    private func numeric(_ title: String, text: Binding<String>, unit: String) -> some View {
        HStack {
            TextField(title, text: text).keyboardType(.decimalPad)
                .focused($numericFieldFocused)
                .accessibilityIdentifier("manual-food-\(title.lowercased().replacingOccurrences(of: " ", with: "-"))")
            Text(unit).foregroundStyle(.secondary)
        }
    }
    private func save() {
        guard let basis = Double(basisAmount), let quantity = Double(logAmount),
              let cals = Double(calories), let p = Double(protein), let c = Double(carbs), let f = Double(fat) else { return }
        let food = FoodDefinition(id: "personal-\(UUID().uuidString)", name: name.trimmingCharacters(in: .whitespacesAndNewlines), basisAmount: basis, basisUnit: basisUnit, calories: cals, protein: p, carbohydrates: c, fat: f, source: "Personal manual entry", isPersonal: true)
        guard food.multiplier(for: quantity, unit: basisUnit) != nil else { return }
        store.addFoodDefinition(food)
        _ = store.logFood(food, meal: meal, quantity: quantity, unit: basisUnit, confirmed: true, date: date)
        dismiss()
    }
}

private struct FoodLogEditorScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    let logID: UUID
    @State private var name = ""
    @State private var quantity = ""
    @State private var unit = "g"
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var selectedMealID: UUID?
    @State private var date = Date.now
    private var original: FoodLog? { store.state.nutrition.logs.first { $0.id == logID && $0.deletedAt == nil } }
    var body: some View {
        Form {
            Section("Entry") {
                TextField("Food name", text: $name)
                HStack { TextField("Quantity", text: $quantity).keyboardType(.decimalPad); TextField("Unit", text: $unit).frame(width: 90) }
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Picker("Meal", selection: $selectedMealID) { ForEach(store.state.nutrition.meals) { Text($0.name).tag(Optional($0.id)) } }
            }
            Section("Correct these logged values") {
                field("Calories", text: $calories, unit: "kcal")
                field("Protein", text: $protein, unit: "g")
                field("Carbohydrates", text: $carbs, unit: "g")
                field("Fat", text: $fat, unit: "g")
            }
            Text("Changes apply to this historical entry only; they do not modify a shared catalogue item.").font(.footnote).foregroundStyle(.secondary)
        }
        .navigationTitle("Edit food entry")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(!valid).accessibilityIdentifier("food-log-edit-save") } }
        .onAppear(perform: load)
    }
    private var valid: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && (Double(quantity) ?? 0) > 0 && [calories, protein, carbs, fat].allSatisfy { (Double($0) ?? -1) >= 0 } }
    private func field(_ title: String, text: Binding<String>, unit: String) -> some View {
        HStack {
            TextField(title, text: text).keyboardType(.decimalPad)
                .accessibilityIdentifier("food-log-\(title.lowercased().replacingOccurrences(of: " ", with: "-"))")
            Text(unit).foregroundStyle(.secondary)
        }
    }
    private func load() {
        guard let log = original else { return }
        name = log.foodName; quantity = String(log.quantity); unit = log.unit
        calories = String(log.calories); protein = String(log.protein); carbs = String(log.carbohydrates); fat = String(log.fat)
        selectedMealID = log.mealID
        date = LocalDay.formatter.date(from: log.date) ?? .now
    }
    private func save() {
        guard let log = original,
              let amount = Double(quantity), let cals = Double(calories), let p = Double(protein), let c = Double(carbs), let f = Double(fat),
              let meal = store.state.nutrition.meals.first(where: { $0.id == selectedMealID }) ?? store.state.nutrition.meals.first else { return }
        if store.updateFoodLog(log.id, foodName: name, mealID: meal.id, mealName: meal.name, quantity: amount, unit: unit, calories: cals, protein: p, carbohydrates: c, fat: f, date: LocalDay.string(date)) { dismiss() }
    }
}

private struct FoodHistoryScreen: View {
    @EnvironmentObject private var store: LogbookStore
    private var logs: [FoodLog] { store.state.nutrition.logs.filter { $0.deletedAt == nil }.sorted { ($0.date, $0.confirmedAt) > ($1.date, $1.confirmedAt) } }
    var body: some View {
        List {
            if logs.isEmpty { ContentUnavailableView("No food history", systemImage: "fork.knife", description: Text("Logged meals will appear here.")) }
            ForEach(logs) { log in
                NavigationLink(destination: FoodLogEditorScreen(logID: log.id)) {
                    VStack(alignment: .leading, spacing: 3) { Text(log.foodName); Text("\(log.date) · \(log.mealName) · \(Int(log.calories)) kcal").font(.caption).foregroundStyle(.secondary) }
                }
                .accessibilityIdentifier("food-history-\(log.id.uuidString)")
                .swipeActions { Button("Delete", role: .destructive) { store.deleteFoodLog(log.id) } }
            }
        }
        .navigationTitle("Food History")
    }
}

private struct RecentlyDeletedFoodScreen: View {
    @EnvironmentObject private var store: LogbookStore
    var body: some View {
        List {
            let logs = store.recentlyDeletedFoodLogs()
            let water = store.recentlyDeletedWaterLogs()
            let recipes = store.recentlyDeletedRecipes()
            if logs.isEmpty && water.isEmpty && recipes.isEmpty {
                ContentUnavailableView("Recently Deleted is empty", systemImage: "trash", description: Text("Deleted food entries, water logs and recipes can be restored for 30 days."))
            }
            if !logs.isEmpty {
                Section("Food entries") {
                    ForEach(logs) { log in
                        HStack {
                            VStack(alignment: .leading) { Text(log.foodName); Text("\(log.date) · \(Int(log.calories)) kcal").font(.caption).foregroundStyle(.secondary) }
                            Spacer()
                            Button("Restore") { _ = store.restoreDeletedFoodLog(log.id) }.accessibilityIdentifier("restore-food-\(log.id.uuidString)")
                            Button("Delete Permanently", role: .destructive) { store.permanentlyDeleteFoodLog(log.id) }
                                .accessibilityIdentifier("permanently-delete-food-\(log.id.uuidString)")
                        }
                    }
                }
            }
            if !water.isEmpty {
                Section("Water logs") {
                    ForEach(water) { log in
                        HStack {
                            Text("\(log.date) · \(log.milliliters) mL")
                            Spacer()
                            Button("Restore") { _ = store.restoreDeletedWaterLog(log.id) }.accessibilityIdentifier("restore-water-\(log.id.uuidString)")
                            Button("Delete Permanently", role: .destructive) { store.permanentlyDeleteWaterLog(log.id) }
                                .accessibilityIdentifier("permanently-delete-water-\(log.id.uuidString)")
                        }
                    }
                }
            }
            if !recipes.isEmpty {
                Section("Recipes") {
                    ForEach(recipes) { recipe in
                        HStack {
                            Text(recipe.name)
                            Spacer()
                            Button("Restore") { _ = store.restoreDeletedRecipe(recipe.id) }.accessibilityIdentifier("restore-recipe-\(recipe.id)")
                            Button("Delete Permanently", role: .destructive) { store.permanentlyDeleteRecipe(recipe.id) }
                                .accessibilityIdentifier("permanently-delete-recipe-\(recipe.id)")
                        }
                    }
                }
            }
        }
        .navigationTitle("Recently Deleted")
    }
}

private struct CopyMealsScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    let destinationDate: String
    @State private var sourceDate = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
    @State private var destination = Date.now
    @State private var mealName = ""
    @State private var status: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("Copy from") { DatePicker("Source day", selection: $sourceDate, displayedComponents: .date) }
                Section("Copy to") { DatePicker("Destination day", selection: $destination, displayedComponents: .date); TextField("Optional meal name", text: $mealName) }
                Section("If matching meals already exist") {
                    Button("Add copied entries") { copy(replace: false) }.accessibilityIdentifier("copy-food-add")
                    Button("Replace matching meals", role: .destructive) { copy(replace: true) }.accessibilityIdentifier("copy-food-replace")
                    Text("Replace removes only entries in meal names present in the source. Other destination meals are preserved.").font(.footnote).foregroundStyle(.secondary)
                }
                if let status { Text(status).accessibilityIdentifier("copy-food-status") }
            }
            .navigationTitle("Copy meals")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
            .onAppear { destination = LocalDay.formatter.date(from: destinationDate) ?? .now }
        }
    }
    private func copy(replace: Bool) {
        let source = LocalDay.string(sourceDate); let target = LocalDay.string(destination)
        let count = store.copyMeals(from: source, to: target, mealName: mealName.isEmpty ? nil : mealName, replaceMatchingMeals: replace)
        status = count == 0 ? "No entries found on \(source)." : "Copied \(count) food entries to \(target)."
    }
}

private struct WaterLogEditorScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    let logID: UUID
    @State private var amount = ""
    @State private var date = Date.now
    private var original: WaterLog? { store.state.nutrition.water.first { $0.id == logID } }
    var body: some View {
        Form {
            TextField("Milliliters", text: $amount).keyboardType(.numberPad)
            DatePicker("Date", selection: $date, displayedComponents: .date)
            Button("Delete water entry", role: .destructive) { store.removeWater(logID); dismiss() }
        }
        .navigationTitle("Edit water")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled((Int(amount) ?? 0) <= 0) } }
        .onAppear { if let original { amount = String(original.milliliters); date = LocalDay.formatter.date(from: original.date) ?? .now } }
    }
    private func save() { guard let amount = Int(amount), store.updateWaterLog(logID, milliliters: amount, date: LocalDay.string(date)) else { return }; dismiss() }
}

private struct WaterGoalScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    @State private var amount = ""
    var body: some View {
        NavigationStack {
            Form {
                Section("Daily hydration goal") {
                    TextField("Milliliters", text: $amount).keyboardType(.numberPad).accessibilityIdentifier("water-goal-amount")
                    Text("Enter a value from 1 to 10,000 mL, or leave blank to remove the goal.").font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Water goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { store.setWaterGoal(Int(amount)); dismiss() }.disabled(!valid) }
            }
            .onAppear { amount = store.state.nutrition.waterGoalMilliliters.map(String.init) ?? "" }
        }
    }
    private var valid: Bool {
        let value = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return true }
        return Int(value).map { (1...10_000).contains($0) } ?? false
    }
}

private struct WaterEntryScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    let date: String
    @State private var amount = ""
    var body: some View {
        NavigationStack {
            Form {
                Section("Water amount") {
                    TextField("Milliliters", text: $amount)
                        .keyboardType(.numberPad)
                        .focused($inputFocused)
                        .accessibilityIdentifier("water-entry-amount")
                    Text("Enter a custom amount from 1 to 5,000 mL.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Log date") { Text(date) }
            }
            .navigationTitle("Add water")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let milliliters = Int(amount), (1...5000).contains(milliliters) else { return }
                        store.addWater(milliliters, date: date)
                        dismiss()
                    }
                    .disabled(!valid)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { dismissKeyboard() }.accessibilityIdentifier("keyboard-done")
                }
            }
        }
    }
    private var valid: Bool { Int(amount).map { (1...5000).contains($0) } ?? false }
    @FocusState private var inputFocused: Bool
    private func dismissKeyboard() { inputFocused = false }
}

private struct RecipeEditorScreen: View {
    let recipe: FoodRecipe?
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var yieldAmount = "1"
    @State private var yieldUnit = "servings"
    @State private var ingredients: [FoodRecipeIngredient] = []
    @State private var selectedFood: FoodDefinition?
    @State private var amount = "100"
    @State private var unit = "g"
    @State private var showAddIngredient = false
    private var totalCalories: Double { ingredients.reduce(0) { $0 + $1.calories } }
    var body: some View {
        NavigationStack {
            Form {
                Section("Recipe") { TextField("Recipe name", text: $name).accessibilityIdentifier("recipe-name"); HStack { TextField("Yield", text: $yieldAmount).keyboardType(.decimalPad); Picker("Yield unit", selection: $yieldUnit) { Text("servings").tag("servings"); Text("g").tag("g") }.pickerStyle(.menu) } }
                Section("Ingredients") {
                    ForEach(ingredients) { item in
                        HStack { Text(item.foodName); Spacer(); Text("\(item.amount.formatted()) \(item.unit) · \(Int(item.calories)) kcal") }
                    }
                    .onDelete { ingredients.remove(atOffsets: $0) }
                    Button("Add ingredient") { showAddIngredient = true }.accessibilityIdentifier("recipe-add-ingredient")
                }
                Section("Calculated per yield") {
                    LabeledContent("Calories", value: "\(Int(totalCalories / max(1, Double(yieldAmount) ?? 1))) kcal")
                    LabeledContent("Protein", value: "\(Int(ingredients.reduce(0) { $0 + $1.protein } / max(1, Double(yieldAmount) ?? 1))) g")
                }
            }
            .navigationTitle("Recipe Builder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save recipe") {
                        _ = store.saveRecipe(name: name, ingredients: ingredients, yieldAmount: Double(yieldAmount) ?? 0, yieldUnit: yieldUnit, id: recipe?.id)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || ingredients.isEmpty || (Double(yieldAmount) ?? 0) <= 0)
                    .accessibilityIdentifier("recipe-save")
                }
            }
            .sheet(isPresented: $showAddIngredient) {
                RecipeIngredientPicker { selectedFood = $0 }
                    .presentationDetents([.large]).presentationDragIndicator(.visible)
            }
            .sheet(item: $selectedFood) { food in
                RecipeIngredientAmountScreen(food: food) { ingredient in ingredients.append(ingredient) }
                    .presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
            }
            .onAppear {
                guard let recipe else { return }
                name = recipe.name
                yieldAmount = String(recipe.yieldAmount)
                yieldUnit = recipe.yieldUnit
                ingredients = recipe.ingredients
            }
        }
    }

    init(recipe: FoodRecipe? = nil) { self.recipe = recipe }
}

private struct RecipeIngredientPicker: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    let onSelect: (FoodDefinition) -> Void
    @State private var query = ""
    var body: some View {
        NavigationStack {
            List(store.state.nutrition.foods.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }) { food in
                Button(food.name) { onSelect(food); dismiss() }.accessibilityIdentifier("recipe-food-\(food.id)")
            }
            .searchable(text: $query, prompt: "Choose a saved food")
            .navigationTitle("Choose ingredient")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

private struct RecipeIngredientAmountScreen: View {
    let food: FoodDefinition
    let onAdd: (FoodRecipeIngredient) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var quantity = "100"
    @State private var unit = "g"
    var body: some View {
        NavigationStack {
            Form {
                Section(food.name) { TextField("Amount", text: $quantity).keyboardType(.decimalPad).accessibilityIdentifier("recipe-ingredient-quantity"); TextField("Unit", text: $unit) }
                Section("Added nutrition") { Text("\(Int(food.calories * (food.multiplier(for: Double(quantity) ?? 0, unit: unit) ?? 0))) kcal") }
            }
            .navigationTitle("Ingredient amount")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard let value = Double(quantity), let factor = food.multiplier(for: value, unit: unit) else { return }
                        let ingredient = FoodRecipeIngredient(
                            foodID: food.id, foodName: food.name, amount: value, unit: unit,
                            calories: food.calories * factor, protein: food.protein * factor,
                            carbohydrates: food.carbohydrates * factor, fat: food.fat * factor
                        )
                        onAdd(ingredient); dismiss()
                    }
                    .disabled((Double(quantity) ?? 0) <= 0)
                }
            }
            .onAppear { unit = food.basisUnit; quantity = String(food.basisAmount) }
        }
    }
}

struct NutritionTargetsScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @Environment(\.dismiss) private var dismiss
    let effectiveDate: String
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbohydrates = ""
    @State private var fat = ""

    init(effectiveDate: String = LocalDay.string()) { self.effectiveDate = effectiveDate }

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily targets · \(effectiveDate)") {
                    targetField("Calories", text: $calories, unit: "kcal")
                    targetField("Protein", text: $protein, unit: "g")
                    targetField("Carbohydrates", text: $carbohydrates, unit: "g")
                    targetField("Fat", text: $fat, unit: "g")
                }
                Section { Text("This snapshot applies to this date and later dates until another target change. Existing historical targets remain unchanged.").font(.footnote).foregroundStyle(.secondary) }
            }
            .navigationTitle("Nutrition targets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.setNutritionTargets(calories: Double(calories), protein: Double(protein), carbohydrates: Double(carbohydrates), fat: Double(fat), effectiveDate: effectiveDate)
                        dismiss()
                    }
                    .disabled(!validTargets)
                }
            }
            .onAppear {
                let targets = store.state.nutritionTargets(on: effectiveDate)
                calories = targets.calories.map { String(Int($0)) } ?? ""
                protein = targets.protein.map { String(Int($0)) } ?? ""
                carbohydrates = targets.carbohydrates.map { String(Int($0)) } ?? ""
                fat = targets.fat.map { String(Int($0)) } ?? ""
            }
        }
    }
    private func targetField(_ label: String, text: Binding<String>, unit: String) -> some View {
        HStack { TextField(label, text: text).keyboardType(.decimalPad).accessibilityIdentifier("nutrition-target-\(label.lowercased())"); Text(unit).foregroundStyle(.secondary) }
    }
    private var validTargets: Bool {
        [calories, protein, carbohydrates, fat].allSatisfy { raw in
            guard !raw.isEmpty else { return true }
            guard let value = Double(raw) else { return false }
            return value.isFinite && value >= 0
        }
    }
}
