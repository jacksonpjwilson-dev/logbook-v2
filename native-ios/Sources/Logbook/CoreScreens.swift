import SwiftUI

struct TrainingScreen: View {
    @EnvironmentObject private var store: LogbookStore
    @State private var showCreate = false
    @State private var workoutName = ""
    @State private var showActiveWorkout = false
    @State private var showDeleteTemplate: UUID?

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
                }
            }

            Section {
                if store.state.training.templates.isEmpty {
                    ContentUnavailableView("Create your first workout", systemImage: "dumbbell", description: Text("Choose a name, add exercises from the built-in library, then start a session. Your history begins when you save a workout."))
                        .listRowBackground(Color.clear)
                }
                ForEach(store.state.training.templates) { template in
                    NavigationLink(destination: WorkoutTemplateScreen(templateID: template.id)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name).font(.headline)
                            Text("\(template.exercises.count) exercises · \(template.exercises.reduce(0) { $0 + $1.sets.count }) planned sets")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) { showDeleteTemplate = template.id }
                    }
                }
            } header: {
                HStack {
                    Text("Your workouts")
                    Spacer()
                    Button { showCreate = true } label: { Label("New", systemImage: "plus") }
                        .labelStyle(.titleAndIcon)
                }
            }

            Section("Recent sessions") {
                if store.state.training.completedSessions.isEmpty {
                    Text("Completed workouts will appear here.").foregroundStyle(.secondary)
                } else {
                    ForEach(store.state.training.completedSessions.sorted { $0.startedAt > $1.startedAt }.prefix(8)) { session in
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
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showCreate = true } label: { Image(systemName: "plus") }.accessibilityLabel("New workout") } }
        .alert("New workout", isPresented: $showCreate) {
            TextField("Workout name", text: $workoutName)
            Button("Create") {
                if store.addTemplate(name: workoutName) != nil { workoutName = "" }
            }
            Button("Cancel", role: .cancel) { workoutName = "" }
        } message: { Text("You can add exercises after creating it.") }
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
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name).font(.headline)
                                Text("\(exercise.muscle) · \(exercise.sets.count) sets · \(exercise.equipment)").font(.caption).foregroundStyle(.secondary)
                            }
                            .swipeActions {
                                Button("Remove", role: .destructive) { store.removeExercise(exercise.id, fromTemplate: templateID) }
                            }
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
            if let template { ActiveWorkoutScreen(onStart: { store.startWorkout(template) }) }
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
        return store.state.training.exercises.filter { $0.name.localizedCaseInsensitiveContains(search) || $0.group.localizedCaseInsensitiveContains(search) || $0.equipment.localizedCaseInsensitiveContains(search) }
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

    var body: some View {
        NavigationStack {
            Form {
                TextField("Exercise name", text: $name)
                TextField("Primary muscle", text: $muscle)
                TextField("Equipment", text: $equipment)
            }
            .navigationTitle("Custom exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let item = store.addCustomExercise(name: name, muscle: muscle, equipment: equipment.isEmpty ? "Other" : equipment) else { return }
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
    @State private var showFinishConfirmation = false
    @State private var showDiscardConfirmation = false
    @State private var incompleteCount = 0
    var onStart: (() -> Void)?

    private var session: WorkoutSession? { store.state.training.activeSession }

    var body: some View {
        NavigationStack {
            Group {
                if let session {
                    List {
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
                            Section {
                                ForEach(exercise.sets) { set in
                                    WorkoutSetEditor(exercise: exercise, set: set)
                                }
                                Button { store.addSet(toExercise: exercise.id) } label: { Label("Add set", systemImage: "plus") }
                            } header: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(exercise.name)
                                    Text("\(exercise.muscle) · Previous values never mark a set complete")
                                        .font(.caption2).textCase(nil).foregroundStyle(.secondary)
                                }
                            }
                        }
                        Section {
                            Button {
                                let result = store.finishWorkout(confirmIncomplete: false)
                                if result == -1 { dismiss() }
                                else if result > 0 { incompleteCount = result; showFinishConfirmation = true }
                            } label: {
                                Label("Finish & Save", systemImage: "checkmark.circle.fill").frame(maxWidth: .infinity, alignment: .center)
                            }
                            .font(.headline)
                            Button("Discard workout", role: .destructive) { showDiscardConfirmation = true }
                                .frame(maxWidth: .infinity, alignment: .center)
                        } footer: {
                            Text("The full plan is saved, including unfinished sets. Only completed sets count toward workout statistics.")
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
                ExercisePickerScreen { store.addExerciseToActive($0) }
                    .presentationDetents([.large]).presentationDragIndicator(.visible)
            }
            .confirmationDialog("Save this workout with unfinished sets?", isPresented: $showFinishConfirmation, titleVisibility: .visible) {
                Button("Finish & Save", role: .destructive) { _ = store.finishWorkout(confirmIncomplete: true); dismiss() }
                Button("Return to workout", role: .cancel) { }
            } message: { Text("\(incompleteCount) planned sets will remain saved as unfinished. Only completed sets count in statistics.") }
            .confirmationDialog("Discard this workout?", isPresented: $showDiscardConfirmation, titleVisibility: .visible) {
                Button("Discard workout", role: .destructive) { store.discardWorkout(); dismiss() }
                Button("Keep working", role: .cancel) { }
            }
            .onAppear { if session == nil { onStart?() } }
        }
    }

    private func elapsed(_ session: WorkoutSession, now: Date) -> String {
        let end = session.pausedAt ?? now
        let seconds = max(0, Int(end.timeIntervalSince(session.startedAt) - session.pausedSeconds))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct WorkoutSetEditor: View {
    @EnvironmentObject private var store: LogbookStore
    let exercise: WorkoutExercise
    let set: WorkoutSet

    var body: some View {
        HStack(spacing: 7) {
            Text("\(exercise.sets.firstIndex(of: set).map { $0 + 1 } ?? 1)")
                .font(.caption.monospacedDigit().weight(.semibold)).frame(width: 25)
            TextField("kg", value: weight, format: .number.precision(.fractionLength(0...2)))
                .keyboardType(.decimalPad).textFieldStyle(.roundedBorder).frame(maxWidth: .infinity).accessibilityLabel("Weight in kilograms")
            Text("×").foregroundStyle(.secondary)
            TextField("Reps", value: reps, format: .number).keyboardType(.numberPad).textFieldStyle(.roundedBorder).frame(width: 62).accessibilityLabel("Repetitions")
            Button { _ = store.toggleSet(exerciseID: exercise.id, setID: set.id) } label: {
                Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 25)).foregroundStyle(set.completed ? Color.green : Color.secondary)
            }
            .buttonStyle(.plain).accessibilityLabel(set.completed ? "Mark set not done" : "Mark set complete")
        }
    }

    private var weight: Binding<Double> {
        Binding(get: { set.weightKg ?? 0 }, set: { store.updateSet(exerciseID: exercise.id, setID: set.id, weightKg: $0 > 0 ? $0 : nil, reps: set.reps) })
    }
    private var reps: Binding<Int> {
        Binding(get: { set.reps }, set: { store.updateSet(exerciseID: exercise.id, setID: set.id, weightKg: set.weightKg, reps: max(1, $0)) })
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
