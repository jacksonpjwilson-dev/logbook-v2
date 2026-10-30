import Foundation
import SwiftUI

enum LogbookTheme: String, CaseIterable, Codable, Identifiable, Equatable {
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
        case .macros, .protein, .meals, .quickLog, .fibre, .easyNext: "fork.knife"
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
    var theme: LogbookTheme = .premiumGlass
    var pages: [HomePage] = HomeState.defaultPages
    var undoPages: [HomePage]? = nil
    var hapticsEnabled = false
    var preferredWeightUnit = "kg"
    var dailyCalorieGoal: Double?
    var dailyProteinGoal: Double?

    static var defaultPages: [HomePage] {
        [
            HomePage(name: "Daily", widgets: [
                HomeWidget(kind: .calories, size: .medium, row: 0, column: 0),
                HomeWidget(kind: .nextWorkout, size: .medium, row: 1, column: 0),
                HomeWidget(kind: .trainingStreak, size: .small, row: 2, column: 0, variant: "Habits Streak"),
                HomeWidget(kind: .vitals, size: .small, row: 2, column: 1, variant: "Daily Check-in")
            ]),
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
}

struct ExerciseDefinition: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var group: String
    var secondary: [String] = []
    var equipment: String
    var description: String = ""
    var isCustom = false
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
}

struct TrainingState: Codable {
    var exercises: [ExerciseDefinition] = []
    var templates: [WorkoutTemplate] = []
    var completedSessions: [WorkoutSession] = []
    var activeSession: WorkoutSession?
    var rotationIndex = 0
}

struct NutritionTargets: Codable, Hashable {
    var calories: Double?
    var protein: Double?
    var carbohydrates: Double?
    var fat: Double?
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
}

struct WaterLog: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var date: String
    var milliliters: Int
    var createdAt: Date = .now
}

struct NutritionState: Codable {
    var targets = NutritionTargets(calories: nil, protein: nil, carbohydrates: nil, fat: nil)
    var foods: [FoodDefinition] = []
    var meals: [MealSlot] = [MealSlot(name: "Meal 1"), MealSlot(name: "Meal 2"), MealSlot(name: "Meal 3")]
    var logs: [FoodLog] = []
    var water: [WaterLog] = []
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
        let day = nutrition.logs.filter { $0.date == date }
        return NutritionTargets(
            calories: day.reduce(0) { $0 + $1.calories },
            protein: day.reduce(0) { $0 + $1.protein },
            carbohydrates: day.reduce(0) { $0 + $1.carbohydrates },
            fat: day.reduce(0) { $0 + $1.fat }
        )
    }
}

enum LogbookRoute: String, Hashable {
    case training, food, history, checkins, settings
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
