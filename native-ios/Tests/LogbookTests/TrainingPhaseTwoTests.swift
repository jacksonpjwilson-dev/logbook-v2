import XCTest
@testable import Logbook

@MainActor
final class TrainingPhaseTwoTests: XCTestCase {
    func testReorderingSplitPreservesScheduledWorkoutThenAdvancesInNewOrder() throws {
        let store = LogbookStore(repository: temporaryRepository())
        let programID = try XCTUnwrap(store.state.training.activeProgram?.id)
        let ids = try ["A", "B", "C", "D"].map { try XCTUnwrap(store.addTemplate(name: $0)) }
        XCTAssertTrue(store.skipScheduledWorkout())
        XCTAssertTrue(store.skipScheduledWorkout())
        XCTAssertEqual(store.state.training.scheduledTemplate?.id, ids[2])

        store.reorderProgramTemplates(programID: programID, orderedIDs: [ids[3], ids[0], ids[1], ids[2]])
        XCTAssertEqual(store.state.training.scheduledTemplate?.id, ids[2], "Reordering must not silently replace the scheduled workout")
        let scheduled = try XCTUnwrap(store.state.training.templates.first { $0.id == ids[2] })
        store.startWorkout(scheduled)
        XCTAssertEqual(store.finishWorkout(confirmIncomplete: true), -1)
        XCTAssertEqual(store.state.training.scheduledTemplate?.id, ids[3], "The reordered successor follows the completed scheduled workout")
    }

    func testSessionOnlyReplacementStopsAfterExerciseStartsAndKeepsTemplateSnapshot() throws {
        let store = LogbookStore(repository: temporaryRepository())
        let templateID = try XCTUnwrap(store.addTemplate(name: "Replacement"))
        let original = ExerciseDefinition(id: "original", name: "Bench Press", group: "Chest", equipment: "Barbell")
        let replacement = ExerciseDefinition(id: "replacement", name: "Chest Press", group: "Chest", equipment: "Machine")
        store.appendExercise(original, toTemplate: templateID)
        let template = try XCTUnwrap(store.state.training.templates.first { $0.id == templateID })
        store.startWorkout(template)
        let sessionExercise = try XCTUnwrap(store.state.training.activeSession?.exercises.first)

        XCTAssertTrue(store.replaceUnstartedActiveExercise(sessionExercise.id, with: replacement))
        XCTAssertEqual(store.state.training.activeSession?.exercises.first?.exerciseID, replacement.id)
        XCTAssertEqual(store.state.training.templates.first { $0.id == templateID }?.exercises.first?.exerciseID, original.id, "Replacing in a session must not edit the saved template")

        let updated = try XCTUnwrap(store.state.training.activeSession?.exercises.first)
        store.updateSet(exerciseID: updated.id, setID: updated.sets[0].id, weightKg: 40, reps: 8)
        XCTAssertFalse(store.replaceUnstartedActiveExercise(updated.id, with: original), "Replacement must be disabled after the exercise has started")
    }

    func testMovingOrDeletingEarlierWorkoutKeepsScheduledItemStable() throws {
        let store = LogbookStore(repository: temporaryRepository())
        let originID = try XCTUnwrap(store.state.training.activeProgram?.id)
        let ids = try ["A", "B", "C", "D"].map { try XCTUnwrap(store.addTemplate(name: $0)) }
        XCTAssertTrue(store.skipScheduledWorkout())
        XCTAssertTrue(store.skipScheduledWorkout())
        XCTAssertEqual(store.state.training.scheduledTemplate?.id, ids[2])

        let otherID = try XCTUnwrap(store.addProgram(name: "Other", activate: false))
        store.moveTemplate(ids[0], toProgram: otherID, at: 0)
        store.setActiveProgram(originID)
        XCTAssertEqual(store.state.training.scheduledTemplate?.id, ids[2], "Moving a preceding template must preserve the scheduled workout")

        store.deleteTemplate(ids[1])
        XCTAssertEqual(store.state.training.scheduledTemplate?.id, ids[2], "Deleting a preceding template must preserve the scheduled workout")
        XCTAssertEqual(store.state.training.rotationIndex, 0)
    }

    func testMergingSupersetGroupsKeepsAllMembersInRotation() throws {
        let store = LogbookStore(repository: temporaryRepository())
        let templateID = try XCTUnwrap(store.addTemplate(name: "Superset merge"))
        let items = (0..<4).map { index in
            ExerciseDefinition(id: "merge-\(index)", name: "Exercise \(index)", group: "Test", equipment: "Barbell")
        }
        for item in items { store.appendExercise(item, toTemplate: templateID) }
        let template = try XCTUnwrap(store.state.training.templates.first { $0.id == templateID })
        let ids = template.exercises.map(\.id)

        store.setSuperset(templateID: templateID, exerciseIDs: Array(ids[0...1]))
        store.setSuperset(templateID: templateID, exerciseIDs: Array(ids[2...3]))
        store.setSuperset(templateID: templateID, exerciseIDs: [ids[1], ids[2]])

        let merged = try XCTUnwrap(store.state.training.templates.first { $0.id == templateID })
        let groupIDs = Set(merged.exercises.compactMap(\.supersetID))
        XCTAssertEqual(groupIDs.count, 1)
        XCTAssertTrue(merged.exercises.allSatisfy { $0.supersetID != nil })

        store.startWorkout(merged)
        let active = try XCTUnwrap(store.state.training.activeSession)
        for index in 0..<3 {
            let exercise = active.exercises[index]
            store.updateSet(exerciseID: exercise.id, setID: exercise.sets[0].id, weightKg: 20, reps: 8)
            XCTAssertTrue(store.toggleSet(exerciseID: exercise.id, setID: exercise.sets[0].id))
            XCTAssertNil(store.state.training.activeSession?.restTimer?.endsAt)
        }
        let last = try XCTUnwrap(store.state.training.activeSession?.exercises.last)
        store.updateSet(exerciseID: last.id, setID: last.sets[0].id, weightKg: 20, reps: 8)
        XCTAssertTrue(store.toggleSet(exerciseID: last.id, setID: last.sets[0].id))
        XCTAssertNotNil(store.state.training.activeSession?.restTimer?.endsAt)
    }

    func testUnfinishedWorkoutRecoversWithOriginProgramAfterProgramSwitch() throws {
        let repository = temporaryRepository()
        let store = LogbookStore(repository: repository)
        let originProgramID = try XCTUnwrap(store.state.training.activeProgram?.id)
        let templateID = try XCTUnwrap(store.addTemplate(name: "Recoverable workout"))
        _ = try XCTUnwrap(store.addTemplate(name: "Next workout"))
        let exercise = ExerciseDefinition(id: "recovery-test", name: "Bench Press", group: "Chest", equipment: "Barbell")
        store.appendExercise(exercise, toTemplate: templateID)
        let template = try XCTUnwrap(store.state.training.templates.first { $0.id == templateID })
        store.startWorkout(template)
        let session = try XCTUnwrap(store.state.training.activeSession)
        let activeExercise = try XCTUnwrap(session.exercises.first)
        store.updateSet(exerciseID: activeExercise.id, setID: activeExercise.sets[0].id, weightKg: 60, reps: 8)
        store.updateWorkoutNotes("Keep form steady")

        let otherProgramID = try XCTUnwrap(store.addProgram(name: "Other program", activate: false))
        store.setActiveProgram(otherProgramID)
        let reopened = LogbookStore(repository: repository)
        let recovered = try XCTUnwrap(reopened.state.training.activeSession)
        XCTAssertEqual(recovered.id, session.id)
        XCTAssertEqual(recovered.programID, originProgramID)
        XCTAssertEqual(recovered.notes, "Keep form steady")
        XCTAssertEqual(recovered.exercises.first?.sets.first?.weightKg, 60)

        let saved = reopened.finishWorkout(confirmIncomplete: true)
        XCTAssertEqual(saved, -1)
        XCTAssertEqual(reopened.state.training.activeProgram?.id, otherProgramID)
        XCTAssertEqual(reopened.state.training.programs?.first(where: { $0.id == originProgramID })?.rotationIndex, 1)
    }

    func testRecentlyDeletedWorkoutCannotBeRestoredBeforeItsDeletionTime() throws {
        let repository = temporaryRepository()
        let session = WorkoutSession(templateName: "Timestamp guard", templateVersion: 1, localDate: "2026-11-01", startedAt: Date(timeIntervalSince1970: 1_800_000_000), finishedAt: Date(timeIntervalSince1970: 1_800_000_060), exercises: [])
        var initial = LogbookState.empty
        initial.training.completedSessions = [session]
        try repository.save(initial)
        let store = LogbookStore(repository: repository)
        let deletionDate = Date(timeIntervalSince1970: 1_800_100_000)
        store.deleteCompletedWorkout(session.id, at: deletionDate)

        XCTAssertFalse(store.restoreDeletedWorkout(session.id, at: deletionDate.addingTimeInterval(-1)))
        XCTAssertTrue(store.state.training.recentlyDeletedSessions(asOf: deletionDate.addingTimeInterval(-1)).isEmpty)
    }

    func testMultipleWorkoutsOnOneDayKeepSeparateEditableHistoryAfterReopen() throws {
        let repository = temporaryRepository()
        let store = LogbookStore(repository: repository)
        let firstID = try XCTUnwrap(store.addTemplate(name: "Morning Strength"))
        let secondID = try XCTUnwrap(store.addTemplate(name: "Evening Accessories"))
        let exercise = ExerciseDefinition(id: "same-day-bench", name: "Bench Press", group: "Chest", equipment: "Barbell")
        store.appendExercise(exercise, toTemplate: firstID)
        store.appendExercise(exercise, toTemplate: secondID)

        func complete(_ templateID: UUID, weightKg: Double, notes: String) throws -> WorkoutSession {
            let template = try XCTUnwrap(store.state.training.templates.first { $0.id == templateID })
            store.startWorkout(template)
            let active = try XCTUnwrap(store.state.training.activeSession)
            let activeExercise = try XCTUnwrap(active.exercises.first)
            for set in activeExercise.sets {
                store.updateSet(exerciseID: activeExercise.id, setID: set.id, weightKg: weightKg, reps: 6)
                XCTAssertTrue(store.toggleSet(exerciseID: activeExercise.id, setID: set.id))
            }
            store.updateWorkoutNotes(notes)
            store.updateExerciseNotes("Keep the setup consistent", exerciseID: activeExercise.id)
            XCTAssertEqual(store.finishWorkout(confirmIncomplete: false), -1)
            return try XCTUnwrap(store.state.training.completedSessions.first { $0.id == active.id })
        }

        let morning = try complete(firstID, weightKg: 60, notes: "Morning session")
        let evening = try complete(secondID, weightKg: 65, notes: "Evening session")
        XCTAssertNotEqual(morning.id, evening.id)
        XCTAssertEqual(morning.localDate, evening.localDate, "Two sessions on one calendar date stay as separate records")

        let morningExercise = try XCTUnwrap(morning.exercises.first)
        let morningSet = try XCTUnwrap(morningExercise.sets.first)
        store.updateCompletedWorkoutSet(sessionID: morning.id, exerciseID: morningExercise.id, setID: morningSet.id, weightKg: 62.5, reps: 6, completed: true)
        store.updateCompletedWorkoutNotes(sessionID: morning.id, notes: "Edited morning note")
        store.updateCompletedExerciseNotes(sessionID: evening.id, exerciseID: try XCTUnwrap(evening.exercises.first?.id), notes: "Edited evening exercise note")

        let reopened = LogbookStore(repository: repository)
        let sameDay = reopened.state.training.visibleCompletedSessions.filter { $0.localDate == morning.localDate }
        XCTAssertEqual(sameDay.count, 2)
        let reopenedMorning = try XCTUnwrap(sameDay.first { $0.id == morning.id })
        let reopenedEvening = try XCTUnwrap(sameDay.first { $0.id == evening.id })
        XCTAssertEqual(reopenedMorning.notes, "Edited morning note")
        XCTAssertEqual(reopenedMorning.exercises.first?.sets.first?.weightKg, 62.5)
        XCTAssertEqual(reopenedMorning.exercises.first?.notes, "Keep the setup consistent")
        XCTAssertEqual(reopenedEvening.notes, "Evening session")
        XCTAssertEqual(reopenedEvening.exercises.first?.notes, "Edited evening exercise note")
    }

    private func temporaryRepository() -> LogbookRepository {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("LogbookTrainingPhase2-\(UUID().uuidString)", isDirectory: true)
        return LogbookRepository(url: directory.appendingPathComponent("state.json"))
    }
}
