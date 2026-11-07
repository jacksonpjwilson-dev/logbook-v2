import XCTest
@testable import Logbook

@MainActor
final class TrainingPhaseTwoTests: XCTestCase {
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
        XCTAssertEqual(store.state.training.scheduledTemplate?.id, ids[2])
        store.deleteTemplate(ids[1])
        XCTAssertEqual(store.state.training.scheduledTemplate?.id, ids[2])
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
        XCTAssertEqual(Set(merged.exercises.compactMap(\.supersetID)).count, 1)
        store.startWorkout(merged)
        let active = try XCTUnwrap(store.state.training.activeSession)
        for exercise in active.exercises.dropLast() {
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
        store.appendExercise(ExerciseDefinition(id: "recovery-test", name: "Bench Press", group: "Chest", equipment: "Barbell"), toTemplate: templateID)
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

        XCTAssertEqual(reopened.finishWorkout(confirmIncomplete: true), -1)
        XCTAssertEqual(reopened.state.training.activeProgram?.id, otherProgramID)
        XCTAssertEqual(reopened.state.training.programs?.first(where: { $0.id == originProgramID })?.rotationIndex, 1)
    }

    private func temporaryRepository() -> LogbookRepository {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("LogbookTrainingPhase2-\(UUID().uuidString)", isDirectory: true)
        return LogbookRepository(url: directory.appendingPathComponent("state.json"))
    }
}
