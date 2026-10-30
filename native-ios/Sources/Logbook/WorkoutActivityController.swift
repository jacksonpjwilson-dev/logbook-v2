import ActivityKit
import Foundation

@MainActor
final class WorkoutActivityController {
    static let shared = WorkoutActivityController()
    private var activity: Activity<WorkoutActivityAttributes>?

    func start(session: WorkoutSession) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        if let existing = Activity<WorkoutActivityAttributes>.activities.first(where: { $0.attributes.workoutID == session.id.uuidString }) {
            activity = existing
            update(session: session)
            return
        }
        let sets = session.exercises.flatMap(\.sets)
        let attributes = WorkoutActivityAttributes(workoutID: session.id.uuidString, workoutName: session.templateName)
        let state = WorkoutActivityAttributes.ContentState(
            completedSets: sets.filter(\.completed).count,
            plannedSets: sets.count,
            activeClockStart: session.startedAt.addingTimeInterval(session.pausedSeconds),
            isPaused: session.pausedAt != nil,
            lastUpdated: .now
        )
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: Date.now.addingTimeInterval(15 * 60)),
                pushType: nil
            )
        } catch {
            activity = nil
        }
    }

    func update(session: WorkoutSession) {
        guard let current = activity ?? Activity<WorkoutActivityAttributes>.activities.first(where: { $0.attributes.workoutID == session.id.uuidString }) else { return }
        let sets = session.exercises.flatMap(\.sets)
        let state = WorkoutActivityAttributes.ContentState(
            completedSets: sets.filter(\.completed).count,
            plannedSets: sets.count,
            activeClockStart: session.startedAt.addingTimeInterval(session.pausedSeconds),
            isPaused: session.pausedAt != nil,
            lastUpdated: .now
        )
        Task { await current.update(ActivityContent(state: state, staleDate: Date.now.addingTimeInterval(15 * 60))) }
    }

    func finish(session: WorkoutSession) {
        guard let current = activity ?? Activity<WorkoutActivityAttributes>.activities.first(where: { $0.attributes.workoutID == session.id.uuidString }) else { return }
        let sets = session.exercises.flatMap(\.sets)
        let state = WorkoutActivityAttributes.ContentState(
            completedSets: sets.filter(\.completed).count,
            plannedSets: sets.count,
            activeClockStart: session.startedAt.addingTimeInterval(session.pausedSeconds),
            isPaused: false,
            lastUpdated: .now
        )
        Task { await current.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .after(Date.now.addingTimeInterval(60))) }
        activity = nil
    }

    func cancel() {
        guard let current = activity else { return }
        Task { await current.end(nil, dismissalPolicy: .immediate) }
        activity = nil
    }
}
