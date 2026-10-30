import ActivityKit
import SwiftUI
import WidgetKit

private struct LogbookEntry: TimelineEntry {
    var date: Date
    var state: LogbookState
}

private struct LogbookProvider: TimelineProvider {
    func placeholder(in context: Context) -> LogbookEntry { LogbookEntry(date: .now, state: .empty) }

    func getSnapshot(in context: Context, completion: @escaping (LogbookEntry) -> Void) {
        completion(LogbookEntry(date: .now, state: loadState()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LogbookEntry>) -> Void) {
        let entry = LogbookEntry(date: .now, state: loadState())
        completion(Timeline(entries: [entry], policy: .after(Date.now.addingTimeInterval(30 * 60))))
    }

    private func loadState() -> LogbookState {
        (try? SharedStateFile.load()) ?? .empty
    }
}

private struct NutritionWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LogbookEntry
    private var theme: ThemePalette { entry.state.home.theme.palette }
    private var totals: NutritionTargets { entry.state.nutritionTotals(on: LocalDay.string(entry.date)) }
    private var caloriesLeft: Int? {
        guard let goal = entry.state.nutrition.targets.calories else { return nil }
        return max(0, Int(goal - (totals.calories ?? 0)))
    }

    @ViewBuilder
    var body: some View {
        switch family {
        case .accessoryCircular:
            Gauge(value: progress) {
                Image(systemName: "flame.fill")
            } currentValueLabel: {
                Text(caloriesLeft.map { String($0) } ?? "—").font(.system(.caption2, design: .rounded).bold())
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .widgetURL(URL(string: "logbook://food"))
        case .accessoryInline:
            Label(caloriesLeft.map { "\($0) calories left" } ?? "Set nutrition target", systemImage: "flame.fill")
                .widgetURL(URL(string: "logbook://food"))
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 3) {
                Text(caloriesLeft.map { "\($0) kcal left" } ?? "Nutrition")
                    .font(.headline).lineLimit(1)
                Text("Protein \(Int(totals.protein ?? 0)) g")
                    .font(.caption).foregroundStyle(.secondary)
                if let goal = entry.state.nutrition.targets.protein { ProgressView(value: min(1, (totals.protein ?? 0) / max(1, goal))) }
            }
            .widgetURL(URL(string: "logbook://food"))
        default:
            VStack(alignment: .leading, spacing: 8) {
                HStack { Image(systemName: "flame.fill").foregroundStyle(theme.accentColor); Text("LOGBOOK").font(.system(size: 9, weight: .bold)).tracking(1.2); Spacer() }
                if let caloriesLeft {
                    Text("\(caloriesLeft)").font(.system(size: family == .systemSmall ? 29 : 34, weight: .bold, design: .rounded)).minimumScaleFactor(0.7)
                    Text("calories left").font(.caption2).foregroundStyle(theme.mutedColor)
                } else {
                    Text("Set your target").font(.headline).lineLimit(2)
                    Text("Tap to configure nutrition goals").font(.caption2).foregroundStyle(theme.mutedColor)
                }
                if family == .systemMedium {
                    Divider().overlay(theme.mutedColor.opacity(0.4))
                    HStack {
                        macro("Protein", value: totals.protein ?? 0)
                        macro("Carbs", value: totals.carbohydrates ?? 0)
                        macro("Fat", value: totals.fat ?? 0)
                    }
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(theme.textColor)
            .padding(12)
            .containerBackground(for: .widget) {
                ZStack { theme.surfaceColor.opacity(0.92); theme.accentColor.opacity(0.11) }
            }
            .widgetURL(URL(string: "logbook://food"))
        }
    }

    private func macro(_ name: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(Int(value)) g").font(.caption.weight(.bold))
            Text(name).font(.system(size: 9)).foregroundStyle(theme.mutedColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progress: Double {
        guard let goal = entry.state.nutrition.targets.calories, goal > 0 else { return 0 }
        return min(1, (totals.calories ?? 0) / goal)
    }
}

private struct TrainingWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LogbookEntry
    private var theme: ThemePalette { entry.state.home.theme.palette }
    private var sessions: [WorkoutSession] { entry.state.training.completedSessions.filter { $0.localDate >= weekStart() } }
    private var active: WorkoutSession? { entry.state.training.activeSession }

    @ViewBuilder var body: some View {
        switch family {
        case .accessoryCircular:
            if let active {
                Gauge(value: workoutProgress) {
                    Image(systemName: "dumbbell.fill")
                } currentValueLabel: {
                    Text("\(active.exercises.flatMap(\.sets).filter(\.completed).count)")
                        .font(.system(.caption2, design: .rounded).bold())
                }
                .gaugeStyle(.accessoryCircularCapacity)
            } else {
                VStack(spacing: 1) { Image(systemName: "dumbbell.fill"); Text("\(sessions.count)").font(.system(.caption2, design: .rounded).bold()) }
            }
            .widgetURL(URL(string: "logbook://training"))
        case .accessoryInline:
            Label(active.map { "\($0.templateName) in progress" } ?? "\(sessions.count) workouts this week", systemImage: "dumbbell.fill")
                .widgetURL(URL(string: "logbook://training"))
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 3) {
                Text(active?.templateName ?? "\(sessions.count) workouts this week").font(.headline).lineLimit(1)
                if let active { Text("\(active.exercises.flatMap(\.sets).filter(\.completed).count) of \(active.exercises.flatMap(\.sets).count) sets").font(.caption) }
                else { Text("Tap to open Training").font(.caption).foregroundStyle(.secondary) }
            }
            .widgetURL(URL(string: "logbook://training"))
        default:
            VStack(alignment: .leading, spacing: 8) {
                HStack { Image(systemName: "dumbbell.fill").foregroundStyle(theme.accentColor); Text("TRAINING").font(.system(size: 9, weight: .bold)).tracking(1.2); Spacer() }
                if let active {
                    Text(active.templateName).font(.headline).lineLimit(1)
                    Text("Workout in progress").font(.caption).foregroundStyle(theme.mutedColor)
                    Text("\(active.exercises.flatMap(\.sets).filter(\.completed).count) / \(active.exercises.flatMap(\.sets).count) sets")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                } else {
                    Text("\(sessions.count)").font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("workouts this week").font(.caption).foregroundStyle(theme.mutedColor)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(theme.textColor)
            .padding(12)
            .containerBackground(for: .widget) { theme.surfaceColor.opacity(0.92) }
            .widgetURL(URL(string: "logbook://training"))
        }
    }

    private func weekStart() -> String {
        let parts = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entry.date)
        return LocalDay.string(Calendar.current.date(from: parts) ?? entry.date)
    }

    private var workoutProgress: Double {
        guard let active, active.exercises.flatMap(\.sets).count > 0 else { return 0 }
        return Double(active.exercises.flatMap(\.sets).filter(\.completed).count) / Double(active.exercises.flatMap(\.sets).count)
    }
}

struct LogbookNutritionWidget: Widget {
    let kind = "LogbookNutritionWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LogbookProvider()) { entry in NutritionWidgetView(entry: entry) }
            .configurationDisplayName("Calories & Macros")
            .description("See today’s recorded nutrition progress.")
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct LogbookTrainingWidget: Widget {
    let kind = "LogbookTrainingWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LogbookProvider()) { entry in TrainingWidgetView(entry: entry) }
            .configurationDisplayName("Workout Progress")
            .description("See your active session or completed workouts this week.")
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct LogbookWidgetsBundle: WidgetBundle {
    var body: some Widget {
        LogbookNutritionWidget()
        LogbookTrainingWidget()
        WorkoutLiveActivityWidget()
    }
}

struct WorkoutLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            LiveWorkoutLockScreen(context: context)
                .widgetURL(URL(string: "logbook://training"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Label("Workout", systemImage: "dumbbell.fill") }
                DynamicIslandExpandedRegion(.trailing) { Text("\(context.state.completedSets)/\(context.state.plannedSets) sets").font(.caption.bold()) }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack { Text(context.attributes.workoutName).lineLimit(1); Spacer(); workoutElapsed(context.state) }
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill")
            } compactTrailing: {
                Text("\(context.state.completedSets)/\(context.state.plannedSets)").font(.caption2.monospacedDigit())
            } minimal: {
                Image(systemName: "dumbbell.fill")
            }
            .widgetURL(URL(string: "logbook://training"))
            .keylineTint(Color.cyan)
        }
    }
}

private struct LiveWorkoutLockScreen: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "dumbbell.fill").font(.title2).foregroundStyle(.cyan)
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.workoutName).font(.headline).lineLimit(1)
                Text(context.state.isPaused ? "Paused" : "Workout in progress").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(context.state.completedSets)/\(context.state.plannedSets)").font(.title3.bold().monospacedDigit())
                Text("sets").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding()
        .activityBackgroundTint(Color(red: 0.08, green: 0.15, blue: 0.22))
        .activitySystemActionForegroundColor(.white)
    }
}

private func workoutElapsed(_ state: WorkoutActivityAttributes.ContentState) -> some View {
    Group {
        if state.isPaused { Text("Paused") }
        else { Text(timerInterval: state.activeClockStart...Date.distantFuture, countsDown: false).monospacedDigit() }
    }
    .font(.caption.monospacedDigit())
}
