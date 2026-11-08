import Foundation
import SwiftUI

enum LogbookTheme: String, CaseIterable, Codable, Identifiable, Equatable {
    case defaultTheme = "default"
    case modernClean = "modern-clean"
    case sunsetVibes = "sunset-vibes"
    case oceanBreeze = "ocean-breeze"
    case monochromePro = "monochrome-pro"
    case softPastel = "soft-pastel"
    case premiumGlass = "premium-glass"
    case mountainDawn = "mountain-dawn"
    case coastalMinimal = "coastal-minimal"
    case midnightLuxe = "midnight-luxe"
    case cherryBlossom = "cherry-blossom"
    case arcticMountain = "arctic-mountain"
    case slateGlass = "slate-glass"
    case midnightGlass = "midnight-glass"
    case monochrome = "monochrome"
    case neonGradient = "neon-gradient"
    case tealCoral = "teal-coral"

    var id: String { rawValue }
    var title: String {
        switch self {
        case .defaultTheme: "Default"
        case .modernClean: "Modern Clean"
        case .sunsetVibes: "Sunset Vibes"
        case .oceanBreeze: "Ocean Breeze"
        case .monochromePro: "Monochrome Pro"
        case .softPastel: "Soft Pastel"
        case .premiumGlass: "Premium Glass"
        case .mountainDawn: "Mountain Dawn"
        case .coastalMinimal: "Coastal Minimal"
        case .midnightLuxe: "Midnight Luxe"
        case .cherryBlossom: "Cherry Blossom"
        case .arcticMountain: "Arctic Mountain"
        case .slateGlass: "Slate Glass"
        case .midnightGlass: "Midnight Glass"
        case .monochrome: "Monochrome"
        case .neonGradient: "Neon Gradient"
        case .tealCoral: "Teal & Coral"
        }
    }

    var palette: ThemePalette {
        switch self {
        // Provisional starter values from the v2 handoff manifest. They remain
        // explicitly subject to visual review; the reference is conceptual.
        case .defaultTheme: .init(surface: "#D6E4F5", text: "#25456E", muted: "#426487", accent: "#7FAEE2", onAccent: "#FFFFFF", light: true)
        case .modernClean: .init(surface: "#1C3B82", text: "#FFFFFF", muted: "#DCE8FF", accent: "#B4F0E4", onAccent: "#123C37", light: false)
        case .sunsetVibes: .init(surface: "#4F2038", text: "#FFF9FA", muted: "#F5D9E1", accent: "#FFD599", onAccent: "#533117", light: false)
        case .oceanBreeze: .init(surface: "#064455", text: "#F5FEFF", muted: "#C9EDF2", accent: "#8AF0D5", onAccent: "#073B33", light: false)
        case .monochromePro: .init(surface: "#202226", text: "#FFFFFF", muted: "#D6D9DF", accent: "#E3E7EC", onAccent: "#20252B", light: false)
        case .softPastel: .init(surface: "#FFF8FF", text: "#27324E", muted: "#50586D", accent: "#4656A6", onAccent: "#FFFFFF", light: true)
        case .premiumGlass: .init(surface: "#1B3043", text: "#F8FBFF", muted: "#D5E0EB", accent: "#93E7D6", onAccent: "#123A33", light: false)
        case .mountainDawn: .init(surface: "#163A54", text: "#F8FCFF", muted: "#CEE2ED", accent: "#A1EBD5", onAccent: "#12392E", light: false)
        case .coastalMinimal: .init(surface: "#F5FCFF", text: "#173B52", muted: "#436174", accent: "#176B76", onAccent: "#FFFFFF", light: true)
        case .midnightLuxe: .init(surface: "#191815", text: "#FFF7E3", muted: "#E1D3B7", accent: "#E7C47B", onAccent: "#38280B", light: false)
        case .cherryBlossom: .init(surface: "#FFF2F6", text: "#4E2639", muted: "#795064", accent: "#A62964", onAccent: "#FFFFFF", light: true)
        case .arcticMountain: .init(surface: "#F1F8FF", text: "#183B59", muted: "#47627C", accent: "#216B9D", onAccent: "#FFFFFF", light: true)
        case .slateGlass: .init(surface: "#253446", text: "#F7FAFF", muted: "#D7E0EB", accent: "#B0CADF", onAccent: "#1D3448", light: false)
        case .midnightGlass: .init(surface: "#0C192D", text: "#F6FAFF", muted: "#C6D7F0", accent: "#9BC7FF", onAccent: "#122E58", light: false)
        case .monochrome: .init(surface: "#FAFBFC", text: "#20262F", muted: "#515C6B", accent: "#3D4B5C", onAccent: "#FFFFFF", light: true)
        case .neonGradient: .init(surface: "#131235", text: "#FBF7FF", muted: "#DED4FF", accent: "#D7AAFF", onAccent: "#3A145A", light: false)
        case .tealCoral: .init(surface: "#073D45", text: "#F6FFFE", muted: "#CBE8E8", accent: "#FFB3A2", onAccent: "#542A24", light: false)
        }
    }

    /// Shared semantic theme values used by the native Home surfaces. Existing
    /// themes keep their established rendering until their later review gate.
    var tokens: ThemeTokens {
        if self == .defaultTheme {
            return ThemeTokens(
                backgroundAsset: "default",
                backgroundBase: Color(hex: "#F3F7FC"),
                surfaceTint: palette.surfaceColor,
                text: palette.textColor,
                secondaryText: palette.mutedColor,
                accent: palette.accentColor,
                onAccent: palette.onAccentColor,
                cardOpacity: 0.86,
                cornerRadius: 22,
                borderOpacity: 0.24,
                shadowOpacity: 0.08,
                backgroundBlurRadius: 12,
                cardShadowRadius: 12,
                isLight: true
            )
        }
        return ThemeTokens(
            backgroundAsset: rawValue,
            backgroundBase: palette.surfaceColor,
            surfaceTint: palette.surfaceColor,
            text: palette.textColor,
            secondaryText: palette.mutedColor,
            accent: palette.accentColor,
            onAccent: palette.onAccentColor,
            cardOpacity: palette.light ? 0.86 : 0.78,
            cornerRadius: 25,
            borderOpacity: palette.light ? 0.30 : 0.42,
            shadowOpacity: 0.22,
            backgroundBlurRadius: 12,
            cardShadowRadius: 12,
            isLight: palette.light
        )
    }
}

struct ThemeTokens {
    let backgroundAsset: String
    let backgroundBase: Color
    let surfaceTint: Color
    let text: Color
    let secondaryText: Color
    let accent: Color
    let onAccent: Color
    let cardOpacity: Double
    let cornerRadius: CGFloat
    let borderOpacity: Double
    let shadowOpacity: Double
    let backgroundBlurRadius: CGFloat
    let cardShadowRadius: CGFloat
    let isLight: Bool
}

struct ThemePalette {
    let surface: String
    let text: String
    let muted: String
    let accent: String
    let onAccent: String
    let light: Bool

    var surfaceColor: Color { Color(hex: surface) }
    var textColor: Color { Color(hex: text) }
    var mutedColor: Color { Color(hex: muted) }
    var accentColor: Color { Color(hex: accent) }
    var onAccentColor: Color { Color(hex: onAccent) }
}

extension Color {
    init(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        let number = UInt64(value, radix: 16) ?? 0
        let r, g, b, a: UInt64
        if value.count == 8 {
            (r, g, b, a) = (number >> 24, (number >> 16) & 0xFF, (number >> 8) & 0xFF, number & 0xFF)
        } else {
            (r, g, b, a) = (number >> 16, (number >> 8) & 0xFF, number & 0xFF, 255)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

enum WidgetSize: String, Codable, CaseIterable, Identifiable, Equatable {
    case small, medium, large
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var rows: Int { self == .large ? 2 : 1 }
}

enum WidgetKind: String, Codable, CaseIterable, Identifiable, Equatable {
    case calories = "kcal", macros, protein, water, meals, quickLog = "favs", mealTiming = "timing", fibre, weeklyCalories = "kcalavg", easyNext = "easynext"
    case workoutSplit = "split", nextWorkout = "next", thisWeek = "week", lastWorkout = "last", personalRecords = "prs", volumeTrend = "volume", trainingStreak = "streak", muscleGroups = "muscles", restTimer = "rest", upcomingPlan = "plan"
    case lastNight = "sleeplast", sleepChart = "sleep7", sleepConsistency = "consist", weight, weightTrend = "wtrend", measurements = "measure", supplements = "supps", vitals, bedtimeTarget = "bedtime"
    case graph, calendarHeatmap = "calheat", monthSummary = "month", bestWeek = "bestweek", compare, milestones, journal, allTimeTotals = "totals", today

    var id: String { rawValue }
    var title: String {
        switch self {
        case .calories: "Calories left"
        case .macros: "Macros"
        case .protein: "Protein goal"
        case .water: "Water"
        case .meals: "Today’s meals"
        case .quickLog: "Quick log"
        case .mealTiming: "Meal timing"
        case .fibre: "Fibre"
        case .weeklyCalories: "Weekly calories"
        case .easyNext: "Easy Next"
        case .workoutSplit: "Workout split"
        case .nextWorkout: "Next workout"
        case .thisWeek: "This week"
        case .lastWorkout: "Last workout"
        case .personalRecords: "Personal records"
        case .volumeTrend: "Volume trend"
        case .trainingStreak: "Training streak"
        case .muscleGroups: "Muscle groups"
        case .restTimer: "Rest timer"
        case .upcomingPlan: "Upcoming plan"
        case .lastNight: "Last night"
        case .sleepChart: "Sleep chart"
        case .sleepConsistency: "Sleep consistency"
        case .weight: "Weight"
        case .weightTrend: "Weight trend"
        case .measurements: "Measurements"
        case .supplements: "Supplements"
        case .vitals: "Steps & resting HR"
        case .bedtimeTarget: "Bedtime target"
        case .graph: "Progress graph"
        case .calendarHeatmap: "Calendar heatmap"
        case .monthSummary: "Month summary"
        case .bestWeek: "Best week"
        case .compare: "Compare"
        case .milestones: "Milestones"
        case .journal: "Journal"
        case .allTimeTotals: "All-time totals"
        case .today: "Today"
        }
    }
    var family: String {
        switch self {
        case .calories, .macros, .protein, .water, .meals, .quickLog, .mealTiming, .fibre, .weeklyCalories, .easyNext: "Food"
        case .workoutSplit, .nextWorkout, .thisWeek, .lastWorkout, .personalRecords, .volumeTrend, .trainingStreak, .muscleGroups, .restTimer, .upcomingPlan: "Training"
        case .lastNight, .sleepChart, .sleepConsistency, .weight, .weightTrend, .measurements, .supplements, .vitals, .bedtimeTarget: "Body"
        case .graph, .calendarHeatmap, .monthSummary, .bestWeek, .compare, .milestones, .journal, .allTimeTotals: "History"
        case .today: "Home"
        }
    }
    var icon: String {
        switch self {
        case .calories, .weeklyCalories: "flame.fill"
        case .macros, .protein, .meals, .quickLog, .mealTiming, .fibre, .easyNext: "fork.knife"
        case .water: "drop.fill"
        case .workoutSplit, .nextWorkout, .lastWorkout, .upcomingPlan: "dumbbell.fill"
        case .thisWeek, .calendarHeatmap, .monthSummary: "calendar"
        case .personalRecords, .bestWeek, .milestones: "trophy.fill"
        case .volumeTrend, .graph, .compare, .allTimeTotals: "chart.xyaxis.line"
        case .trainingStreak, .sleepConsistency, .vitals: "checkmark.circle.fill"
        case .muscleGroups: "figure.strengthtraining.traditional"
        case .restTimer: "timer"
        case .lastNight, .sleepChart, .bedtimeTarget: "moon.fill"
        case .weight, .weightTrend: "scalemass.fill"
        case .measurements: "ruler"
        case .supplements: "pills.fill"
        case .journal: "book.closed.fill"
        case .today: "sun.max.fill"
        }
    }
}

struct HomeWidget: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var kind: WidgetKind
    var size: WidgetSize
    var row: Int
    var column: Int
    var variant: String?
}

struct HomePage: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var widgets: [HomeWidget]
}

struct HomeState: Codable {
    var theme: LogbookTheme = .defaultTheme
    var pages: [HomePage] = HomeState.defaultPages
    var undoPages: [HomePage]? = nil
    var hapticsEnabled = false
    var preferredWeightUnit = "kg"
    var dailyCalorieGoal: Double?
    var dailyProteinGoal: Double?

    static var defaultPages: [HomePage] {
        [
            defaultDailyPage,
            HomePage(name: "Training", widgets: [
                HomeWidget(kind: .workoutSplit, size: .large, row: 0, column: 0),
                HomeWidget(kind: .calendarHeatmap, size: .large, row: 2, column: 0, variant: "Workout Calendar")
            ]),
            HomePage(name: "Food", widgets: [
                HomeWidget(kind: .calories, size: .large, row: 0, column: 0, variant: "Nutrition Today"),
                HomeWidget(kind: .meals, size: .medium, row: 2, column: 0),
                HomeWidget(kind: .fibre, size: .small, row: 3, column: 0, variant: "Nutrition Streak"),
                HomeWidget(kind: .easyNext, size: .small, row: 3, column: 1)
            ]),
            HomePage(name: "Progress & History", widgets: [
                HomeWidget(kind: .graph, size: .large, row: 0, column: 0),
                HomeWidget(kind: .calendarHeatmap, size: .medium, row: 2, column: 0),
                HomeWidget(kind: .personalRecords, size: .small, row: 3, column: 0),
                HomeWidget(kind: .mealTiming, size: .small, row: 3, column: 1, variant: "Nutrition Adherence")
            ])
        ]
    }

    static var defaultDailyPage: HomePage {
        HomePage(name: "Daily", widgets: [
            HomeWidget(kind: .calories, size: .large, row: 0, column: 0, variant: "Calories & Macros Remaining"),
            HomeWidget(kind: .nextWorkout, size: .medium, row: 2, column: 0),
            HomeWidget(kind: .trainingStreak, size: .small, row: 3, column: 0, variant: "Habits Streak"),
            HomeWidget(kind: .vitals, size: .small, row: 3, column: 1, variant: "Daily Check-in")
        ])
    }

    /// Migrates only the untouched previous Daily default. User-arranged pages are preserved.
    @discardableResult
    mutating func migrateUntouchedDailyLayout() -> Bool {
        guard let index = pages.firstIndex(where: { $0.name == "Daily" }),
              Self.matchesPreviousDailyDefault(pages[index]) || Self.matchesPreviousNamedDailyDefault(pages[index]) else { return false }

        let previous = pages[index]
        var updated = Self.defaultDailyPage
        updated.id = previous.id
        for newIndex in updated.widgets.indices {
            if let old = previous.widgets.first(where: { $0.kind == updated.widgets[newIndex].kind }) {
                updated.widgets[newIndex].id = old.id
            }
        }
        pages[index] = updated
        return true
    }

    private static func matchesPreviousNamedDailyDefault(_ page: HomePage) -> Bool {
        guard page.widgets.count == 4 else { return false }
        let expected: [(WidgetKind, WidgetSize, Int, Int, String?)] = [
            (.calories, .large, 0, 0, "Calories & Protein Remaining"),
            (.nextWorkout, .medium, 2, 0, nil),
            (.trainingStreak, .small, 3, 0, "Habits Streak"),
            (.vitals, .small, 3, 1, "Daily Check-in")
        ]
        return expected.allSatisfy { item in
            page.widgets.contains {
                $0.kind == item.0 && $0.size == item.1 && $0.row == item.2 &&
                    $0.column == item.3 && $0.variant == item.4
            }
        }
    }

    private static func matchesPreviousDailyDefault(_ page: HomePage) -> Bool {
        guard page.widgets.count == 4 else { return false }
        let expected: [(WidgetKind, WidgetSize, Int, Int, String?)] = [
            (.calories, .medium, 0, 0, nil),
            (.nextWorkout, .medium, 1, 0, nil),
            (.trainingStreak, .small, 2, 0, "Habits Streak"),
            (.vitals, .small, 2, 1, "Daily Check-in")
        ]
        return expected.allSatisfy { expectedWidget in
            page.widgets.contains { widget in
                widget.kind == expectedWidget.0 && widget.size == expectedWidget.1 &&
                    widget.row == expectedWidget.2 && widget.column == expectedWidget.3 &&
                    widget.variant == expectedWidget.4
            }
        }
    }
}

enum ExerciseTrackingMode: String, Codable, CaseIterable, Identifiable {
    case weightAndReps = "weight-reps"
    case repsOnly = "reps"
    case duration = "duration"
    case weightAndDistance = "weight-distance"

    var id: String { rawValue }
    var title: String {
        switch self {
        case .weightAndReps: "Weight + reps"
        case .repsOnly: "Reps only"
        case .duration: "Duration"
        case .weightAndDistance: "Weight + distance"
        }
    }
}

struct ExerciseDefinition: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var group: String
    var secondary: [String] = []
    var equipment: String
    var description: String = ""
    var isCustom = false
    var trackingMode: ExerciseTrackingMode? = .weightAndReps
}

struct PlannedSet: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var reps = 8
    var kind = "working"
}

struct PlannedExercise: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var exerciseID: String
    var name: String
    var muscle: String
    var equipment: String
    var sets: [PlannedSet] = (0..<3).map { _ in PlannedSet() }
    var supersetID: UUID?
    var restSeconds: Int? = nil
    var trackingMode: ExerciseTrackingMode? = nil
}

struct WorkoutTemplate: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var exercises: [PlannedExercise] = []
    var version = 1
}

struct WorkoutSet: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var weightKg: Double?
    var reps: Int = 8
    var completed = false
    var kind = "working"
    var durationSeconds: Int? = nil
    var distanceMeters: Double? = nil
}

struct WorkoutExercise: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var exerciseID: String
    var name: String
    var muscle: String
    var equipment: String
    var sets: [WorkoutSet]
    var supersetID: UUID?
    var notes = ""
    var restSeconds: Int? = nil
    var hasStarted: Bool? = false
    var trackingMode: ExerciseTrackingMode? = nil
}

struct WorkoutRestTimer: Codable, Hashable {
    var baseDurationSeconds = 90
    var activeDurationSeconds: Int?
    var endsAt: Date?
    var currentDurationSeconds: Int { activeDurationSeconds ?? baseDurationSeconds }
    var pausedRemainingSeconds: Int?

    var isPaused: Bool { pausedRemainingSeconds != nil }

    func remainingSeconds(at date: Date = .now) -> Int {
        if let pausedRemainingSeconds { return max(0, pausedRemainingSeconds) }
        guard let endsAt else { return 0 }
        return max(0, Int(ceil(endsAt.timeIntervalSince(date))))
    }

    var isRunning: Bool { endsAt.map { pausedRemainingSeconds == nil && $0 > .now } ?? false }

    mutating func start(seconds: Int? = nil, at date: Date = .now) {
        let duration = min(600, max(0, seconds ?? baseDurationSeconds))
        activeDurationSeconds = duration
        endsAt = date.addingTimeInterval(TimeInterval(duration))
        pausedRemainingSeconds = nil
    }

    mutating func pause(at date: Date = .now) {
        guard let endsAt, pausedRemainingSeconds == nil else { return }
        pausedRemainingSeconds = max(0, Int(ceil(endsAt.timeIntervalSince(date))))
        self.endsAt = nil
    }

    mutating func resume(at date: Date = .now) {
        guard let pausedRemainingSeconds else { return }
        endsAt = date.addingTimeInterval(TimeInterval(max(0, pausedRemainingSeconds)))
        self.pausedRemainingSeconds = nil
    }

    mutating func addFifteenSeconds(at date: Date = .now) {
        activeDurationSeconds = min(600, currentDurationSeconds + 15)
        if let pausedRemainingSeconds {
            self.pausedRemainingSeconds = min(600, pausedRemainingSeconds + 15)
        } else {
            let remaining = remainingSeconds(at: date)
            endsAt = date.addingTimeInterval(TimeInterval(min(600, remaining + 15)))
        }
    }

    mutating func skip(at date: Date = .now) {
        endsAt = date
        pausedRemainingSeconds = nil
    }

    mutating func setBaseDuration(_ seconds: Int) {
        baseDurationSeconds = min(600, max(15, seconds))
    }
}

struct WorkoutSession: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var templateID: UUID?
    var templateName: String
    var templateVersion: Int
    var localDate: String
    var startedAt: Date
    var finishedAt: Date?
    var pausedAt: Date?
    var pausedSeconds = 0.0
    var notes = ""
    var exercises: [WorkoutExercise]
    var restTimer: WorkoutRestTimer? = nil
    /// Captured at start so changing the active program never reassigns a draft.
    var programID: UUID? = nil
    var scheduledTemplateID: UUID? = nil
    var wasScheduledWorkout: Bool? = nil
    var deletedAt: Date? = nil
    /// Optional, session-scoped dismissals. A dismissed suggestion never mutates
    /// the plan or a set and remains dismissed after restoring the draft.
    var declinedProgressionExerciseIDs: [UUID]? = nil

    /// The first exercise with planned work remaining. Supersets progress by
    /// round, so every member's set N is completed before set N+1 begins.
    var currentExerciseID: UUID? {
        var visitedSupersets = Set<UUID>()
        for exercise in exercises {
            if let groupID = exercise.supersetID {
                guard visitedSupersets.insert(groupID).inserted else { continue }
                let members = exercises.filter { $0.supersetID == groupID }
                let rounds = members.map { $0.sets.count }.max() ?? 0
                for round in 0..<rounds {
                    if let next = members.first(where: { $0.sets.indices.contains(round) && !$0.sets[round].completed }) {
                        return next.id
                    }
                }
            } else if exercise.sets.contains(where: { !$0.completed }) {
                return exercise.id
            }
        }
        return exercises.last?.id
    }
}

struct WorkoutProgram: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var templateIDs: [UUID] = []
    var rotationIndex = 0

    func scheduledTemplate(in templates: [WorkoutTemplate]) -> WorkoutTemplate? {
        guard !templateIDs.isEmpty else { return nil }
        let index = ((rotationIndex % templateIDs.count) + templateIDs.count) % templateIDs.count
        guard templateIDs.indices.contains(index) else { return nil }
        let id = templateIDs[index]
        return templates.first { $0.id == id }
    }
}

struct TrainingState: Codable {
    var exercises: [ExerciseDefinition] = []
    var templates: [WorkoutTemplate] = []
    var completedSessions: [WorkoutSession] = []
    var activeSession: WorkoutSession?
    var rotationIndex = 0
    /// Nil on older installations; LogbookStore migrates the legacy single rotation lazily.
    var programs: [WorkoutProgram]? = nil
    var activeProgramID: UUID? = nil

    var availablePrograms: [WorkoutProgram] {
        if let programs, !programs.isEmpty { return programs }
        let legacyID = UUID(uuidString: "A989A0DF-8E57-4DEB-BB52-66B9BD039999") ?? UUID()
        return [WorkoutProgram(id: legacyID, name: "Program 1", templateIDs: templates.map(\.id), rotationIndex: rotationIndex)]
    }

    var activeProgram: WorkoutProgram? {
        let programs = availablePrograms
        return programs.first { $0.id == activeProgramID } ?? programs.first
    }

    var scheduledTemplate: WorkoutTemplate? {
        activeProgram?.scheduledTemplate(in: templates)
    }

    var visibleCompletedSessions: [WorkoutSession] {
        completedSessions.filter { $0.deletedAt == nil }
    }

    func recentlyDeletedSessions(asOf date: Date = .now) -> [WorkoutSession] {
        completedSessions.filter {
            guard let deletedAt = $0.deletedAt else { return false }
            let age = date.timeIntervalSince(deletedAt)
            return age >= 0 && age < 30 * 24 * 60 * 60
        }.sorted { ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast) }
    }

    var personalRecordEvents: [WorkoutPersonalRecord] {
        let sessions = visibleCompletedSessions.sorted {
            ($0.finishedAt ?? $0.startedAt) < ($1.finishedAt ?? $1.startedAt)
        }
        var bestByExercise: [String: Double] = [:]
        var events: [WorkoutPersonalRecord] = []
        for session in sessions {
            var sessionBest: [String: (weight: Double, reps: Int, estimated: Double)] = [:]
            for exercise in session.exercises {
                guard (exercise.trackingMode ?? .weightAndReps) == .weightAndReps else { continue }
                for set in exercise.sets where set.completed {
                    guard let weight = set.weightKg, weight > 0, set.reps > 0 else { continue }
                    let estimate = weight * (1 + Double(set.reps) / 30)
                    if estimate > (sessionBest[exercise.exerciseID]?.estimated ?? 0) {
                        sessionBest[exercise.exerciseID] = (weight, set.reps, estimate)
                    }
                }
            }
            for (exerciseID, performance) in sessionBest.sorted(by: { $0.key < $1.key }) {
                guard let previousBest = bestByExercise[exerciseID] else {
                    bestByExercise[exerciseID] = performance.estimated
                    continue
                }
                if performance.estimated > previousBest {
                    events.append(WorkoutPersonalRecord(
                        sessionID: session.id,
                        exerciseID: exerciseID,
                        exerciseName: session.exercises.first(where: { $0.exerciseID == exerciseID })?.name ?? exerciseID,
                        date: session.finishedAt ?? session.startedAt,
                        weightKg: performance.weight,
                        reps: performance.reps,
                        estimatedOneRepMaxKg: performance.estimated,
                        previousBestKg: previousBest
                    ))
                    bestByExercise[exerciseID] = performance.estimated
                }
            }
        }
        return events
    }
}

struct WorkoutPersonalRecord: Identifiable, Hashable {
    var id: String { "\(sessionID.uuidString)-\(exerciseID)" }
    var sessionID: UUID
    var exerciseID: String
    var exerciseName: String
    var date: Date
    var weightKg: Double
    var reps: Int
    var estimatedOneRepMaxKg: Double
    var previousBestKg: Double
}

struct NutritionTargets: Codable, Hashable {
    var calories: Double?
    var protein: Double?
    var carbohydrates: Double?
    var fat: Double?
}

struct NutritionTargetSnapshot: Codable, Identifiable, Hashable {
    var id: String { effectiveDate }
    var effectiveDate: String
    var targets: NutritionTargets
}

struct FoodDefinition: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var basisAmount: Double = 100
    var basisUnit = "g"
    var calories: Double
    var protein: Double
    var carbohydrates: Double
    var fat: Double
    var source = "Manual"
    /// Only populated when the provider supplies a verified gram amount.
    var verifiedServingGrams: Double? = nil
    var barcode: String? = nil
    var sourceURL: String? = nil
    var isPersonal: Bool? = nil

    func multiplier(for quantity: Double, unit: String) -> Double? {
        guard quantity.isFinite, quantity > 0, basisAmount.isFinite, basisAmount > 0 else { return nil }
        if unit.caseInsensitiveCompare(basisUnit) == .orderedSame { return quantity / basisAmount }
        guard basisUnit.caseInsensitiveCompare("g") == .orderedSame else { return nil }
        let grams: Double
        switch unit.lowercased() {
        case "g", "gram", "grams": grams = quantity
        case "oz", "ounce", "ounces": grams = quantity * 28.349523125
        case "serving", "servings":
            guard let verifiedServingGrams, verifiedServingGrams.isFinite, verifiedServingGrams > 0 else { return nil }
            grams = quantity * verifiedServingGrams
        default: return nil
        }
        return grams / basisAmount
    }
}

struct MealSlot: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
}

struct FoodLog: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var foodID: String
    var foodName: String
    var mealID: UUID
    var mealName: String
    var date: String
    var quantity: Double
    var unit: String
    var calories: Double
    var protein: Double
    var carbohydrates: Double
    var fat: Double
    var confirmedAt: Date
    var deletedAt: Date? = nil
}

struct FoodRecipeIngredient: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var foodID: String
    var foodName: String
    var amount: Double
    var unit: String
    var calories: Double
    var protein: Double
    var carbohydrates: Double
    var fat: Double
}

struct FoodRecipe: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var ingredients: [FoodRecipeIngredient]
    var yieldAmount: Double
    var yieldUnit: String
    var updatedAt: Date = .now
    var deletedAt: Date? = nil

    var total: NutritionTargets {
        NutritionTargets(
            calories: ingredients.reduce(0) { $0 + $1.calories },
            protein: ingredients.reduce(0) { $0 + $1.protein },
            carbohydrates: ingredients.reduce(0) { $0 + $1.carbohydrates },
            fat: ingredients.reduce(0) { $0 + $1.fat }
        )
    }
}

struct WaterLog: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var date: String
    var milliliters: Int
    var createdAt: Date = .now
    var deletedAt: Date? = nil
}

struct NutritionState: Codable {
    var targets = NutritionTargets(calories: nil, protein: nil, carbohydrates: nil, fat: nil)
    var foods: [FoodDefinition] = []
    var meals: [MealSlot] = [MealSlot(name: "Meal 1"), MealSlot(name: "Meal 2"), MealSlot(name: "Meal 3")]
    var logs: [FoodLog] = []
    var water: [WaterLog] = []
    /// Optional for backwards-compatible decoding of existing App Group files.
    var targetHistory: [NutritionTargetSnapshot]? = nil
    var favoriteFoodIDs: [String]? = nil
    var recipes: [FoodRecipe]? = nil
    var waterGoalMilliliters: Int? = nil
    var calorieTolerance: Double? = nil
}

struct SleepLog: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var wakeDate: String
    var bedtime: Date
    var wakeTime: Date
    var manualMinutes: Int?
    var durationMinutes: Int { manualMinutes ?? max(0, Int(wakeTime.timeIntervalSince(bedtime) / 60)) }
}

struct WeightLog: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var date: String
    var kilograms: Double
}

struct Supplement: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var name: String
    var schedule: String = "daily"
    var weekdays: [Int] = []
}

struct SupplementDose: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var supplementID: UUID
    var supplementName: String
    var date: String
    var taken = false
    var explicitlyMarked = false
}

struct CheckInState: Codable {
    var sleep: [SleepLog] = []
    var weights: [WeightLog] = []
    var supplements: [Supplement] = []
    var doses: [SupplementDose] = []
    var sleepGoalMinutes = 480
}

struct LogbookState: Codable {
    var schemaVersion = 1
    var home = HomeState()
    var training = TrainingState()
    var nutrition = NutritionState()
    var checkins = CheckInState()
    var notificationsEnabled = false
    var nutritionReminderTime: String? = nil
    var trainingReminderTime: String? = nil
    var lastModified = Date.now

    static var empty: LogbookState { LogbookState() }

    func nutritionTotals(on date: String) -> NutritionTargets {
        let day = nutrition.logs.filter { $0.date == date && $0.deletedAt == nil }
        return NutritionTargets(
            calories: day.reduce(0) { $0 + $1.calories },
            protein: day.reduce(0) { $0 + $1.protein },
            carbohydrates: day.reduce(0) { $0 + $1.carbohydrates },
            fat: day.reduce(0) { $0 + $1.fat }
        )
    }

    func nutritionTargets(on date: String) -> NutritionTargets {
        nutrition.targetHistory?
            .filter { $0.effectiveDate <= date }
            .max { $0.effectiveDate < $1.effectiveDate }?.targets ?? nutrition.targets
    }

    enum NutritionAdherence: Equatable {
        case unlogged
        case noTargets
        case belowGoal
        case aboveGoal
        case onTarget
    }

    func nutritionAdherence(on date: String, tolerance: Double? = nil) -> NutritionAdherence {
        let logs = nutrition.logs.filter { $0.date == date && $0.deletedAt == nil }
        guard !logs.isEmpty else { return .unlogged }
        let targets = nutritionTargets(on: date)
        guard let calorieGoal = targets.calories, calorieGoal > 0 else { return .noTargets }
        let totals = nutritionTotals(on: date)
        let toleranceFraction = min(0.5, max(0, tolerance ?? nutrition.calorieTolerance ?? 0.05))
        let calories = totals.calories ?? 0
        guard calories >= calorieGoal * (1 - toleranceFraction) else { return .belowGoal }
        guard calories <= calorieGoal * (1 + toleranceFraction) else { return .aboveGoal }
        if let proteinGoal = targets.protein, (totals.protein ?? 0) < proteinGoal { return .belowGoal }
        return .onTarget
    }
}

enum LogbookRoute: String, Hashable {
    case training, food, history, checkins, settings
}

enum FoodNavigationFocus: Equatable {
    case meal(UUID)
    case meals
    case addFood
    case water
    case adherence
    case targets
}

enum CheckInSection: String, Hashable {
    case sleep, weight, supplements
}

enum LocalDay {
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_CA_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func string(_ date: Date = .now) -> String { formatter.string(from: date) }
}
