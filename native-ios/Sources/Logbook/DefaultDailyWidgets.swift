import SwiftUI

/// Purpose-built content for the four approved Default Daily widgets. Other
/// themes and Home pages continue to use their existing widget renderer.
struct DefaultDailyWidgetView: View {
    let widget: HomeWidget
    let palette: ThemePalette
    let state: LogbookState
    let openFood: () -> Void
    let openTraining: () -> Void
    let openCheckIn: (CheckInSection) -> Void
    let startWorkout: (WorkoutTemplate) -> Void

    var body: some View {
        switch widget.kind {
        case .calories:
            Button(action: openFood) {
                NutritionRemainingContent(state: state, palette: palette)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home-widget-kcal")
            .accessibilityLabel("Calories and macros remaining. View Food.")
        case .nextWorkout:
            workoutWidget
        case .trainingStreak:
            HabitsContent(
                state: state,
                palette: palette,
                openCheckIn: openCheckIn
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("home-widget-streak")
        case .vitals:
            CheckInContent(
                state: state,
                palette: palette,
                openCheckIn: openCheckIn
            )
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("home-widget-vitals")
        default:
            EmptyView()
        }
    }

    private var workoutWidget: some View {
        let workout = nextWorkout
        return ZStack(alignment: .bottom) {
            Button(action: openTraining) {
                WorkoutContent(workout: workout, palette: palette)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("home-widget-next")
            .accessibilityLabel("Next workout, \(workout.name), \(workout.exerciseCount) exercises, \(workout.duration.map { "about \($0) minutes" } ?? "estimated duration unavailable"), \(workout.lastCompletion). View Workout.")

            HStack(spacing: 8) {
                Button {
                    if state.training.activeSession != nil {
                        openTraining()
                    } else if let template = workout.template {
                        startWorkout(template)
                    } else {
                        openTraining()
                    }
                } label: {
                    Text(state.training.activeSession == nil ? (workout.template == nil ? "Plan Workout" : "Start Workout") : "Resume")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(palette.onAccentColor)
                        .padding(.horizontal, 10)
                        .frame(height: 23)
                        .background(palette.accentColor, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("start-next-workout")

                Spacer(minLength: 0)

                Button(action: openTraining) {
                    Label("View Workout", systemImage: "chevron.right")
                        .labelStyle(TrailingChevronLabelStyle())
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(palette.accentColor)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("view-next-workout")
            }
            .padding(.horizontal, 13)
            .padding(.bottom, 10)
        }
    }

    private var nextWorkout: WorkoutSummary {
        let active = state.training.activeSession
        let template: WorkoutTemplate? = {
            if let active, let templateID = active.templateID {
                return state.training.templates.first { $0.id == templateID }
            }
            guard state.training.templates.indices.contains(state.training.rotationIndex) else { return nil }
            return state.training.templates[state.training.rotationIndex]
        }()
        let name = active?.templateName ?? template?.name ?? "No workout planned"
        let exerciseCount = active?.exercises.count ?? template?.exercises.count ?? 0
        let muscleNames = active?.exercises.map(\.muscle) ?? template?.exercises.map(\.muscle) ?? []
        let muscles = Array(Set(muscleNames.filter { !$0.isEmpty })).sorted().joined(separator: " · ")
        let setCount = active?.exercises.reduce(0) { $0 + $1.sets.count } ?? template?.exercises.reduce(0) { $0 + $1.sets.count } ?? 0
        let minutes = exerciseCount == 0 ? nil : max(1, setCount * 2 + exerciseCount * 2 + 5)
        let last = state.training.completedSessions
            .compactMap(\.finishedAt)
            .max()
            .map { RelativeDateTimeFormatter().localizedString(for: $0, relativeTo: .now) } ?? "No previous completion"
        let position = state.training.templates.firstIndex { $0.id == template?.id }.map { "\($0 + 1) of \(state.training.templates.count)" } ?? ""
        return WorkoutSummary(
            template: template,
            name: name,
            muscles: muscles.isEmpty ? (exerciseCount == 0 ? "No exercises planned" : "Muscle groups not set") : muscles,
            exerciseCount: exerciseCount,
            duration: minutes,
            lastCompletion: last,
            position: position
        )
    }
}

private struct WorkoutSummary {
    let template: WorkoutTemplate?
    let name: String
    let muscles: String
    let exerciseCount: Int
    let duration: Int?
    let lastCompletion: String
    let position: String
}

private struct NutritionRemainingContent: View {
    let state: LogbookState
    let palette: ThemePalette

    private var totals: NutritionTargets { state.nutritionTotals(on: LocalDay.string()) }
    private var calorieGoal: Double? { state.nutrition.targets.calories }
    private var caloriesConsumed: Double { totals.calories ?? 0 }
    private var caloriesRemaining: Int { Int(max(0, (calorieGoal ?? 0) - caloriesConsumed)) }

    var body: some View {
        DefaultDailyCardSurface(palette: palette) {
            GeometryReader { geometry in
                let compact = geometry.size.width < 220
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 5) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(palette.accentColor)
                        Text("CALORIES & MACROS REMAINING")
                            .font(.system(size: compact ? 7.8 : 8.5, weight: .semibold))
                            .tracking(compact ? 0.25 : 0.55)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(palette.mutedColor)

                    Text(calorieGoal == nil ? "Set a calorie target" : "\(caloriesRemaining.formatted()) kcal left")
                        .font(.system(size: compact ? 18 : 22, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                        .foregroundStyle(palette.textColor)
                        .padding(.top, 4)
                    Text(calorieGoal.map { "\(Int(caloriesConsumed).formatted()) / \(Int($0).formatted()) kcal logged" } ?? "Calories update from your food log")
                        .font(.system(size: compact ? 8.5 : 9.5, weight: .regular))
                        .lineLimit(1)
                        .foregroundStyle(palette.mutedColor)
                        .padding(.top, 1)

                    Spacer(minLength: compact ? 4 : 7)

                    HStack(alignment: .center, spacing: compact ? 6 : 9) {
                        calorieRing(diameter: compact ? 69 : 83)
                        VStack(spacing: compact ? 4 : 6) {
                            macroRow("Protein", symbol: "dumbbell.fill", consumed: totals.protein ?? 0, goal: state.nutrition.targets.protein, color: palette.accentColor, iconColor: palette.accentColor, unit: "g", compact: compact)
                            macroRow("Carbs", symbol: "leaf.fill", consumed: totals.carbohydrates ?? 0, goal: state.nutrition.targets.carbohydrates, color: Color(hex: "#426B8D"), iconColor: Color(hex: "#426B8D"), unit: "g", compact: compact)
                            macroRow("Fat", symbol: "drop.fill", consumed: totals.fat ?? 0, goal: state.nutrition.targets.fat, color: Color(hex: "#A8C7E7"), iconColor: Color(hex: "#6D94BC"), unit: "g", compact: compact)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: compact ? 4 : 7)

                    HStack {
                        Spacer()
                        Label("View Food", systemImage: "chevron.right")
                            .labelStyle(TrailingChevronLabelStyle())
                            .font(.system(size: compact ? 8 : 9, weight: .semibold))
                            .foregroundStyle(palette.accentColor)
                    }
                }
                .padding(13)
            }
        }
    }

    private func calorieRing(diameter: CGFloat) -> some View {
        let ringSize = diameter - 11
        VStack(spacing: 3) {
            ZStack {
                Circle().stroke(palette.accentColor.opacity(0.18), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: calorieGoal.map { $0 > 0 ? min(1, caloriesConsumed / $0) : 0 } ?? 0)
                    .stroke(palette.accentColor, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text(calorieGoal == nil ? "—" : caloriesRemaining.formatted())
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                    Text("kcal left").font(.system(size: 7.5, weight: .medium))
                }
                .foregroundStyle(palette.textColor)
            }
            .frame(width: ringSize, height: ringSize)
            Text(calorieGoal.map { "\(Int(caloriesConsumed))/\(Int($0)) kcal" } ?? "Set calorie goal")
                .font(.system(size: 7.5, weight: .medium))
                .foregroundStyle(palette.mutedColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(width: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Calories remaining, \(caloriesRemaining) kilocalories. \(Int(caloriesConsumed)) of \(Int(calorieGoal ?? 0)) logged.")
    }

    private func macroRow(_ name: String, symbol: String, consumed: Double, goal: Double?, color: Color, iconColor: Color, unit: String, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 1 : 2) {
            HStack(spacing: 3) {
                Image(systemName: symbol)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(iconColor)
                Text(name).font(.system(size: compact ? 7.8 : 8.5, weight: .semibold))
                Spacer(minLength: 1)
                Text(goal.map { "\(Int(max(0, $0 - consumed))) left" } ?? "Set goal")
                    .font(.system(size: compact ? 6.7 : 7.4, weight: .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
            }
            .foregroundStyle(palette.textColor)
            if compact {
                Text(goal.map { "\(Int(consumed))/\(Int($0)) \(unit)" } ?? "Set a \(name.lowercased()) goal")
                    .font(.system(size: 6.8, weight: .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                    .foregroundStyle(palette.mutedColor)
            } else {
                Text(goal.map { "\(Int(consumed))/\(Int($0)) \(unit)" } ?? "Set a \(name.lowercased()) goal")
                    .font(.system(size: 6.8, weight: .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(palette.mutedColor)
            }
            GeometryReader { proxy in
                let fraction = goal.map { $0 > 0 ? min(1, consumed / $0) : 0 } ?? 0
                ZStack(alignment: .leading) {
                    Capsule().fill(palette.textColor.opacity(0.13))
                    Capsule().fill(color).frame(width: proxy.size.width * fraction)
                }
            }
            .frame(height: compact ? 3.5 : 4)
            .accessibilityLabel("\(name), \(Int(consumed)) of \(Int(goal ?? 0)) \(unit), \(Int(max(0, (goal ?? 0) - consumed))) remaining")
        }
    }
}

private struct WorkoutContent: View {
    let workout: WorkoutSummary
    let palette: ThemePalette

    var body: some View {
        DefaultDailyCardSurface(palette: palette) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 5) {
                    Image(systemName: "dumbbell.fill").font(.system(size: 9, weight: .semibold)).foregroundStyle(palette.accentColor)
                    Text("NEXT WORKOUT").font(.system(size: 8.5, weight: .semibold)).tracking(0.65)
                    Spacer()
                    if !workout.position.isEmpty {
                        Text(workout.position).font(.system(size: 8, weight: .medium)).foregroundStyle(palette.mutedColor)
                    }
                }
                .foregroundStyle(palette.mutedColor)
                Text(workout.name)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                    .foregroundStyle(palette.textColor)
                    .padding(.top, 3)
                Text(workout.muscles)
                    .font(.system(size: 9, weight: .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .foregroundStyle(palette.mutedColor)
                    .padding(.top, 2)
                HStack(spacing: 4) {
                    Image(systemName: "clock").font(.system(size: 8, weight: .medium))
                    Text("\(workout.exerciseCount) exercises")
                    Text("·")
                    Text(workout.duration.map { "~\($0) min" } ?? "Duration —")
                    Text("·")
                    Text("Last \(workout.lastCompletion)")
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
                .font(.system(size: 7.8, weight: .regular))
                .foregroundStyle(palette.mutedColor)
                .padding(.top, 2)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 38)
        }
    }
}

private struct HabitsContent: View {
    let state: LogbookState
    let palette: ThemePalette
    let openCheckIn: (CheckInSection) -> Void

    private var metrics: DailyHomeMetrics { DailyHomeMetrics(state: state) }

    var body: some View {
        DefaultDailyCardSurface(palette: palette) {
            GeometryReader { geometry in
                let compact = geometry.size.height < 108
                VStack(alignment: .leading, spacing: compact ? 1 : 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill").font(.system(size: 9, weight: .semibold)).foregroundStyle(palette.accentColor)
                        Text("\(metrics.perfectDayStreak)-day streak")
                            .font(.system(size: compact ? 9.5 : 10.5, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(palette.textColor)
                        Spacer(minLength: 0)
                    }
                    .frame(height: compact ? 12 : 14)
                    statusButton(.sleep, title: "Sleep", value: metrics.sleep.map { sleepDuration($0.durationMinutes) } ?? "Log", compact: compact)
                    statusButton(.weight, title: "Weight", value: metrics.weight.map { displayWeight($0.kilograms) } ?? "Log", compact: compact)
                    statusButton(.supplements, title: "Supplements", value: supplementValue, compact: compact)
                    HStack {
                        Spacer()
                        Text("\(metrics.completedCount)/\(metrics.eligibleCount) complete")
                            .font(.system(size: compact ? 7 : 8, weight: .medium))
                            .foregroundStyle(palette.mutedColor)
                    }
                    .frame(height: compact ? 9 : 10)
                }
                .padding(.horizontal, compact ? 7 : 9)
                .padding(.vertical, compact ? 5 : 8)
            }
        }
    }

    private var supplementValue: String {
        metrics.dueSupplements.isEmpty ? "None due" : "\(metrics.takenSupplementCount)/\(metrics.dueSupplements.count)"
    }

    private func statusButton(_ section: CheckInSection, title: String, value: String, compact: Bool) -> some View {
        Button { openCheckIn(section) } label: {
            HStack(spacing: 4) {
                Image(systemName: statusSymbol(section))
                    .font(.system(size: compact ? 7 : 8, weight: .semibold))
                    .foregroundStyle(isComplete(section) ? Color(hex: "#318466") : palette.mutedColor.opacity(0.7))
                Text(title)
                    .font(.system(size: compact ? 7.5 : 8.5, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                    .foregroundStyle(palette.textColor)
                Spacer(minLength: 0)
                Text(value)
                    .font(.system(size: compact ? 6.8 : 7.5, weight: .regular))
                    .foregroundStyle(palette.mutedColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            .contentShape(Rectangle())
            .frame(height: compact ? 18 : 19)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("habit-\(section.rawValue)")
        .accessibilityLabel(accessibilityLabel(title: title, value: value, section: section))
    }

    private func isComplete(_ section: CheckInSection) -> Bool {
        switch section {
        case .sleep: return metrics.sleep != nil
        case .weight: return metrics.weight != nil
        case .supplements: return !metrics.dueSupplements.isEmpty && metrics.supplementsComplete
        }
    }

    private func statusSymbol(_ section: CheckInSection) -> String {
        if section == .supplements, metrics.dueSupplements.isEmpty { return "minus.circle" }
        return isComplete(section) ? "checkmark.circle.fill" : "circle"
    }

    private func accessibilityLabel(title: String, value: String, section: CheckInSection) -> String {
        if section == .supplements, metrics.dueSupplements.isEmpty {
            return "Supplements, none due, neutral. Open supplements check-in."
        }
        return "\(title), \(value), \(isComplete(section) ? "complete" : "incomplete"). Open \(title) check-in."
    }

    private func displayWeight(_ kilograms: Double) -> String {
        let value = state.home.preferredWeightUnit == "lb" ? kilograms * 2.2046226218 : kilograms
        return value.formatted(.number.precision(.fractionLength(1))) + " " + state.home.preferredWeightUnit
    }
}

private struct CheckInContent: View {
    let state: LogbookState
    let palette: ThemePalette
    let openCheckIn: (CheckInSection) -> Void

    private var metrics: DailyHomeMetrics { DailyHomeMetrics(state: state) }

    var body: some View {
        DefaultDailyCardSurface(palette: palette) {
            GeometryReader { geometry in
                let compact = geometry.size.height < 108
                VStack(alignment: .leading, spacing: compact ? 1 : 3) {
                    HStack {
                        Text("DAILY CHECK-IN")
                            .font(.system(size: compact ? 7.3 : 8, weight: .semibold))
                            .tracking(0.35)
                            .foregroundStyle(palette.mutedColor)
                        Spacer()
                        Button { openCheckIn(.supplements) } label: {
                            Image(systemName: "checklist")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(palette.accentColor)
                                .frame(width: 18, height: compact ? 14 : 18)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("checkin-checklist")
                        .accessibilityLabel("Open check-in checklist")
                    }
                    HStack(spacing: 4) {
                        checkInValue(.sleep, symbol: "moon.fill", title: "Sleep", value: metrics.sleep.map { sleepDuration($0.durationMinutes) } ?? "—", compact: compact)
                        checkInValue(.weight, symbol: "scalemass.fill", title: "Weight", value: metrics.weight.map { displayWeight($0.kilograms) } ?? "—", compact: compact)
                    }
                    Button { openCheckIn(.supplements) } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pills.fill").font(.system(size: 8, weight: .medium)).foregroundStyle(palette.accentColor)
                            Text("Supplements")
                                .font(.system(size: compact ? 7.5 : 8.5, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                                .foregroundStyle(palette.textColor)
                            Spacer(minLength: 1)
                            Text(metrics.dueSupplements.isEmpty ? "None due" : "\(metrics.takenSupplementCount)/\(metrics.dueSupplements.count) taken")
                                .font(.system(size: compact ? 6.8 : 7.4, weight: .regular))
                                .foregroundStyle(palette.mutedColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.62)
                        }
                        .frame(height: compact ? 18 : 22)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("checkin-supplements")
                    .accessibilityLabel("Supplements, \(metrics.dueSupplements.isEmpty ? "none due" : "\(metrics.takenSupplementCount) of \(metrics.dueSupplements.count) taken"). Open supplement check-in.")
                }
                .padding(.horizontal, compact ? 7 : 9)
                .padding(.vertical, compact ? 4 : 8)
            }
        }
    }

    private func checkInValue(_ section: CheckInSection, symbol: String, title: String, value: String, compact: Bool) -> some View {
        Button { openCheckIn(section) } label: {
            VStack(alignment: .leading, spacing: compact ? 1 : 2) {
                HStack(spacing: 3) {
                    Image(systemName: symbol).font(.system(size: compact ? 7 : 8, weight: .medium)).foregroundStyle(palette.accentColor)
                    Text(title).font(.system(size: compact ? 6.8 : 7.5, weight: .medium)).foregroundStyle(palette.mutedColor)
                }
                Text(value)
                    .font(.system(size: compact ? 10.5 : 12.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .frame(maxWidth: .infinity, minHeight: compact ? 30 : 37, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("checkin-\(section.rawValue)")
        .accessibilityLabel("\(title), \(value). Open \(title.lowercased()) check-in.")
    }

    private func displayWeight(_ kilograms: Double) -> String {
        let value = state.home.preferredWeightUnit == "lb" ? kilograms * 2.2046226218 : kilograms
        return value.formatted(.number.precision(.fractionLength(1))) + " " + state.home.preferredWeightUnit
    }
}

private struct DefaultDailyCardSurface<Content: View>: View {
    let palette: ThemePalette
    let content: Content

    init(palette: ThemePalette, @ViewBuilder content: () -> Content) {
        self.palette = palette
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background {
                shape.fill(.ultraThinMaterial)
                    .overlay(shape.fill(palette.surfaceColor.opacity(0.24)))
                    .overlay(shape.fill(Color.white.opacity(0.25)))
            }
            .overlay(shape.stroke(Color.white.opacity(0.64), lineWidth: 0.85))
            .overlay(shape.stroke(palette.accentColor.opacity(0.16), lineWidth: 0.6))
            .clipShape(shape)
            .shadow(color: Color(hex: "#557493").opacity(0.12), radius: 9, x: 0, y: 5)
    }
}

private struct TrailingChevronLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
            configuration.title
        }
    }
}

private func sleepDuration(_ minutes: Int) -> String {
    let hours = minutes / 60
    let remainder = minutes % 60
    return remainder == 0 ? "\(hours)h" : "\(hours)h \(remainder)m"
}
