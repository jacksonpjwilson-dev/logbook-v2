import ActivityKit
import Foundation

struct WorkoutActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var completedSets: Int
        var plannedSets: Int
        var activeClockStart: Date
        var isPaused: Bool
        var lastUpdated: Date
    }

    var workoutID: String
    var workoutName: String
}
