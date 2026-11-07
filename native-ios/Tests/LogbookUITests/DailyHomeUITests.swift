import XCTest

final class DailyHomeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDailyHomeLayoutAndCaptureAllHomePages() throws {
        let app = launchApp()
        let calories = app.buttons["home-widget-kcal"]
        let nextWorkout = app.descendants(matching: .any)["home-widget-next"]
        let habits = app.otherElements["home-widget-streak"]
        let checkIn = app.otherElements["home-widget-vitals"]

        XCTAssertTrue(calories.waitForExistence(timeout: 20), "Daily nutrition widget did not appear")
        XCTAssertTrue(nextWorkout.exists)
        XCTAssertTrue(habits.exists)
        XCTAssertTrue(checkIn.exists)
        XCTAssertTrue(calories.label.localizedCaseInsensitiveContains("Calories and macros remaining"))
        XCTAssertTrue(nextWorkout.label.contains("Upper Body"))
        XCTAssertTrue(nextWorkout.label.contains("4 exercises"))
        XCTAssertTrue(nextWorkout.label.contains("minutes"))
        XCTAssertTrue(app.buttons["start-next-workout"].exists)
        XCTAssertEqual(app.buttons["start-next-workout"].label, "Start workout")
        XCTAssertTrue(app.buttons["view-next-workout"].exists)
        let checkInTitle = app.staticTexts["DAILY CHECK-IN"]
        XCTAssertTrue(checkInTitle.exists)
        XCTAssertLessThan(checkInTitle.frame.height, 13, "The check-in heading should stay on one line in its fixed square cell")
        XCTAssertTrue(app.buttons["habit-sleep"].exists)
        XCTAssertTrue(app.buttons["habit-weight"].exists)
        XCTAssertTrue(app.buttons["habit-supplements"].exists)
        XCTAssertTrue(app.buttons["checkin-sleep"].exists)
        XCTAssertTrue(app.buttons["checkin-weight"].exists)
        XCTAssertTrue(app.buttons["checkin-supplements"].exists)

        let measuredMediumSize = (nextWorkout.value as? String ?? "").split(separator: "|").compactMap { Double($0) }
        XCTAssertEqual(measuredMediumSize.count, 2, "Next Workout should expose its measured outer widget dimensions")
        let mediumWidth = measuredMediumSize.count == 2 ? measuredMediumSize[0] : nextWorkout.frame.width
        let mediumHeight = measuredMediumSize.count == 2 ? measuredMediumSize[1] : nextWorkout.frame.height
        XCTAssertEqual(calories.frame.width, mediumWidth, accuracy: 2)
        XCTAssertGreaterThan(calories.frame.height, mediumHeight)
        XCTAssertEqual(habits.frame.width, checkIn.frame.width, accuracy: 2)
        XCTAssertEqual(habits.frame.width, habits.frame.height, accuracy: 2, "Small widgets must occupy square cells")
        XCTAssertEqual(calories.frame.width, calories.frame.height, accuracy: 2, "Large widgets must be square")
        XCTAssertEqual(mediumHeight, habits.frame.height, accuracy: 2, "Medium widget must be two cells wide and one cell tall")
        XCTAssertEqual(mediumWidth, habits.frame.width * 2 + 9, accuracy: 3, "Medium width must span two cells and one grid gap")
        XCTAssertEqual(habits.frame.minY, checkIn.frame.minY, accuracy: 2)
        XCTAssertLessThanOrEqual(calories.frame.maxY, nextWorkout.frame.minY)
        XCTAssertLessThanOrEqual(nextWorkout.frame.minY + mediumHeight, habits.frame.minY)
        XCTAssertLessThan(habits.frame.maxY, app.buttons["Training tab"].frame.minY)
        XCTAssertTrue(app.buttons["Training tab"].exists)
        XCTAssertTrue(app.buttons["Food tab"].exists)
        XCTAssertTrue(app.buttons["History tab"].exists)
        XCTAssertTrue(app.buttons["Sleep tab"].exists)
        XCTAssertTrue(app.buttons["Settings tab"].exists)

        let pageNames = ["Daily page", "Training page", "Food page", "Progress & History page"]
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label IN %@", pageNames)).count, 4)

        let dockFrame = app.buttons["Training tab"].frame
        let measurement = "Default Daily widget frames (points): large=\(calories.frame), mediumElement=\(nextWorkout.frame), mediumMeasuredSize=\(measuredMediumSize), small-left=\(habits.frame), small-right=\(checkIn.frame), dock=\(dockFrame)"
        print("GRID_MEASUREMENT: \(measurement)")
        add(XCTAttachment(string: measurement))

        attachScreenshot(of: app, named: "Home-Daily-Default-Candidate")
        capturePage("Training", in: app)
        capturePage("Food", in: app)
        capturePage("Progress & History", in: app)

        let dailyPage = app.buttons["Daily page"]
        XCTAssertTrue(dailyPage.waitForExistence(timeout: 5))
        dailyPage.tap()
        app.buttons["home-widget-kcal"].tap()
        XCTAssertTrue(app.navigationBars["Food"].waitForExistence(timeout: 5), "Calories widget should open Food")
    }

    func testDailySmallWidgetRegionsOpenTheirMatchingCheckInSections() throws {
        let app = launchApp()
        let habitSleep = app.buttons["habit-sleep"]
        XCTAssertTrue(habitSleep.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(habitSleep.frame.height, 20, "Habit rows need a reliable touch target")
        habitSleep.tap()
        XCTAssertTrue(app.buttons["Save sleep"].waitForExistence(timeout: 5), "Habits Sleep region must open Sleep controls")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["habit-weight"].tap()
        XCTAssertTrue(app.buttons["Save today’s weight"].waitForExistence(timeout: 5), "Habits Weight region must open Weight controls")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["habit-supplements"].tap()
        XCTAssertTrue(app.buttons["Add supplement"].waitForExistence(timeout: 5), "Habits Supplements region must open supplement controls")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["checkin-sleep"].tap()
        XCTAssertTrue(app.buttons["Save sleep"].waitForExistence(timeout: 5), "Daily Check-in Sleep value must open Sleep controls")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["checkin-weight"].tap()
        XCTAssertTrue(app.buttons["Save today’s weight"].waitForExistence(timeout: 5), "Daily Check-in Weight value must open Weight controls")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["checkin-supplements"].tap()
        XCTAssertTrue(app.buttons["Add supplement"].waitForExistence(timeout: 5), "Daily Check-in Supplements must open supplement controls")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["checkin-checklist"].tap()
        XCTAssertTrue(app.buttons["Add supplement"].waitForExistence(timeout: 5), "Checklist icon must open the supplement checklist")
    }

    func testNextWorkoutStartActionCreatesAnActiveWorkout() throws {
        let app = launchApp()
        app.buttons["view-next-workout"].tap()
        XCTAssertTrue(app.buttons["New workout"].waitForExistence(timeout: 5), "View Workout must open the Training screen")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["start-next-workout"].tap()
        XCTAssertTrue(app.navigationBars["Training"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Upper Body"].waitForExistence(timeout: 5), "Start Workout must create and open the scheduled program")
        XCTAssertTrue(app.descendants(matching: .any)["training-active-session"].waitForExistence(timeout: 5), "Start Workout must create an active session")
        let restTimer = app.descendants(matching: .any)["rest-timer-value"]
        XCTAssertTrue(restTimer.waitForExistence(timeout: 5), "Starting Workout opens the active session with its rest card")
        XCTAssertEqual(restTimer.label, "Ready", "A new workout starts in the Ready timer state")
        XCTAssertTrue(app.buttons["rest-duration-menu"].exists, "Default rest duration should be adjustable")
        XCTAssertTrue(app.descendants(matching: .any)["workout-set-table-header"].exists, "Active workout should show its five-column set table")
        attachScreenshot(of: app, named: "Training-Active-Workout-Default-Candidate")

        let addTime = app.buttons["rest-add-15"]
        XCTAssertTrue(addTime.isHittable, "The timer extension control should be interactive")
        addTime.tap()
        let timerStarted = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label != %@", "Ready"),
            object: restTimer
        )
        XCTAssertEqual(XCTWaiter.wait(for: [timerStarted], timeout: 5), .completed, "The visible timer should update before testing recovery")
        // The first +15 starts the timer from Ready. Keep the recovery window long
        // enough that slower simulator launches cannot consume the whole interval.
        for _ in 0..<8 {
            addTime.tap()
        }
        XCTAssertNotEqual(restTimer.label, "Ready", "The timer should still be active before termination")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["home-widget-kcal"].waitForExistence(timeout: 10), "The app should reopen to Home after termination")
        app.buttons["Training tab"].tap()

        let resumeWorkout = app.buttons["training-active-session"]
        XCTAssertTrue(resumeWorkout.waitForExistence(timeout: 5), "A terminated app should retain a non-intrusive Resume Workout entry")
        resumeWorkout.tap()
        let recoveredTimer = app.descendants(matching: .any)["rest-timer-value"]
        XCTAssertTrue(recoveredTimer.waitForExistence(timeout: 5), "The saved in-progress session resumes from Training")
        XCTAssertNotEqual(recoveredTimer.label, "Ready", "The running rest timer must recover after app termination")
    }

    func testDefaultTrainingHomeShowsSplitTilesAndNavigableWorkoutCalendar() throws {
        let app = launchApp()
        app.buttons["Training page"].tap()

        let firstWorkout = app.buttons["training-split-workout-1"]
        XCTAssertTrue(firstWorkout.waitForExistence(timeout: 5), "The split widget must show a tappable numbered workout tile")
        XCTAssertLessThanOrEqual(firstWorkout.frame.height, 40, "A split item must stay a compact tile instead of stretching into a nested card")
        XCTAssertTrue(firstWorkout.label.contains("Upper Body"))
        XCTAssertTrue(firstWorkout.label.localizedCaseInsensitiveContains("next scheduled"))
        XCTAssertTrue(firstWorkout.label.localizedCaseInsensitiveContains("last completed"))
        XCTAssertTrue(app.buttons["training-split-full"].exists, "The complete split remains available from the fixed-size widget")
        let monthLabel = app.staticTexts["training-calendar-month-label"]
        XCTAssertTrue(monthLabel.exists)
        let currentMonth = monthLabel.label
        app.buttons["training-calendar-next"].tap()
        XCTAssertNotEqual(monthLabel.label, currentMonth, "The in-widget calendar month control must change the displayed month")
        app.buttons["training-calendar-previous"].tap()
        XCTAssertEqual(monthLabel.label, currentMonth)

        attachScreenshot(of: app, named: "Home-Training-Default-Interactive-Candidate")
        let calendarDay = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "training-calendar-day-")).firstMatch
        XCTAssertTrue(calendarDay.waitForExistence(timeout: 5), "The compact calendar must expose tappable dates")
        calendarDay.tap()
        XCTAssertTrue(app.navigationBars["Workout Calendar"].waitForExistence(timeout: 5), "Selecting a date opens the full calendar and its session history")
        app.buttons["Done"].tap()
        firstWorkout.tap()
        XCTAssertTrue(app.buttons["Start Upper Body"].waitForExistence(timeout: 5), "Tapping a split tile opens its workout details without changing the scheduled workout")
    }

    func testWorkoutSplitEditorSupportsReorderingExerciseSearchAndCustomExercises() throws {
        let app = launchApp()
        app.buttons["Training tab"].tap()

        let newWorkout = app.buttons["New workout"]
        XCTAssertTrue(newWorkout.waitForExistence(timeout: 5))
        newWorkout.tap()
        let name = app.textFields["Workout name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        replaceText(in: name, with: "Lower Body")
        app.buttons["Create"].tap()

        let rows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "training-template-"))
        XCTAssertEqual(rows.count, 2, "The UI should show both saved workouts in the active program")
        let firstID = rows.element(boundBy: 0).identifier
        let secondID = rows.element(boundBy: 1).identifier
        app.buttons["Edit"].tap()
        rows.element(boundBy: 0).press(forDuration: 1.0, thenDragTo: rows.element(boundBy: 1))
        XCTAssertEqual(rows.element(boundBy: 0).identifier, secondID, "Dragging a workout row should update the saved split order")
        XCTAssertNotEqual(rows.element(boundBy: 0).identifier, firstID)
        app.buttons["Done"].tap()

        rows.firstMatch.tap()
        XCTAssertTrue(app.buttons["workout-template-add-exercise"].waitForExistence(timeout: 5))
        app.buttons["workout-template-add-exercise"].tap()
        XCTAssertTrue(app.navigationBars["Choose exercise"].waitForExistence(timeout: 5))
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Bench Press")
        let result = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "exercise-picker-result-")).firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5), "Search should find the built-in Bench Press exercise")
        result.tap()
        XCTAssertTrue(app.staticTexts["Bench Press"].waitForExistence(timeout: 5), "Selecting a search result should persist it in the workout plan")

        app.buttons["workout-template-add-exercise"].tap()
        app.buttons["exercise-picker-create-custom"].tap()
        XCTAssertTrue(app.navigationBars["Custom exercise"].waitForExistence(timeout: 5))
        let customName = app.textFields["custom-exercise-name"]
        replaceText(in: customName, with: "QA Cable Fly")
        let customMuscle = app.textFields["custom-exercise-muscle"]
        replaceText(in: customMuscle, with: "Chest")
        let customEquipment = app.textFields["custom-exercise-equipment"]
        replaceText(in: customEquipment, with: "Cable")
        app.buttons["custom-exercise-save"].tap()
        XCTAssertTrue(app.staticTexts["QA Cable Fly"].waitForExistence(timeout: 5), "A custom exercise should return to the persisted workout plan")
        attachScreenshot(of: app, named: "Training-Split-Editor-Candidate")
    }

    func testProgressionSuggestionRequiresAndAppliesExplicitAcceptance() throws {
        let app = launchApp(progressionHistory: true)
        app.buttons["Training tab"].tap()
        let template = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "training-template-")).firstMatch
        XCTAssertTrue(template.waitForExistence(timeout: 5))
        template.tap()
        XCTAssertTrue(app.buttons["workout-template-start"].waitForExistence(timeout: 5))
        app.buttons["workout-template-start"].tap()

        let suggestion = app.buttons["accept-progression-suggestion"]
        XCTAssertTrue(suggestion.waitForExistence(timeout: 5), "A matching prior completed set should produce an optional suggestion")
        let weight = app.textFields["Weight in kilograms"].firstMatch
        XCTAssertTrue(weight.exists)
        XCTAssertNotEqual(weight.value as? String, "62.5", "Suggested load must not be applied before explicit acceptance")
        suggestion.tap()
        let accepted = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "62.5"), object: weight)
        XCTAssertEqual(XCTWaiter.wait(for: [accepted], timeout: 5), .completed, "Accepting the suggestion should update the session set weights")
        attachScreenshot(of: app, named: "Training-Progression-Acceptance-Candidate")
    }

    func testWorkoutCompletionHistoryEditingAndRecentlyDeletedRecovery() throws {
        let app = launchApp()
        app.buttons["Training tab"].tap()
        let template = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "training-template-")).firstMatch
        XCTAssertTrue(template.waitForExistence(timeout: 5))
        template.tap()
        XCTAssertTrue(app.buttons["workout-template-start"].waitForExistence(timeout: 5))
        app.buttons["workout-template-start"].tap()

        let finish = app.buttons["finish-workout"]
        XCTAssertTrue(finish.waitForExistence(timeout: 5))
        finish.tap()
        let confirmSave = app.buttons.matching(NSPredicate(format: "label == %@", "Finish & Save")).lastMatch
        XCTAssertTrue(confirmSave.waitForExistence(timeout: 5), "Unfinished planned sets should require explicit save confirmation")
        confirmSave.tap()
        XCTAssertTrue(app.navigationBars["Workout saved"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Sets completed")).firstMatch.exists)
        attachScreenshot(of: app, named: "Training-Completion-Summary-Candidate")
        app.buttons["workout-summary-done"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Training"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["home-widget-kcal"].waitForExistence(timeout: 5))

        app.buttons["History tab"].tap()
        let historyRows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "history-workout-"))
        XCTAssertTrue(historyRows.firstMatch.waitForExistence(timeout: 5), "A saved workout should appear in History")
        for _ in 0..<5 where !historyRows.firstMatch.isHittable { app.swipeUp() }
        XCTAssertTrue(historyRows.firstMatch.isHittable)
        historyRows.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Upper Body"].waitForExistence(timeout: 5))
        attachScreenshot(of: app, named: "Training-History-Detail-Candidate")

        let historyWeight = app.textFields["history-set-weight"].firstMatch
        XCTAssertTrue(historyWeight.waitForExistence(timeout: 5))
        replaceText(in: historyWeight, with: "40")
        let historyReps = app.textFields["history-set-reps"].firstMatch
        replaceText(in: historyReps, with: "8")
        app.buttons["history-set-complete"].firstMatch.tap()
        XCTAssertTrue(app.buttons["history-set-complete"].label.localizedCaseInsensitiveContains("incomplete"), "Historical set completion should update immediately")
        let notes = app.textFields["history-workout-notes"]
        XCTAssertTrue(notes.exists)
        notes.tap()
        notes.typeText("QA history edit")
        app.buttons["Delete workout"].tap()
        app.buttons["Delete Workout"].tap()

        let restoreButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "restore-deleted-workout-"))
        XCTAssertTrue(restoreButtons.firstMatch.waitForExistence(timeout: 5), "Deleting a workout should move it into Recently Deleted")
        for _ in 0..<6 where !restoreButtons.firstMatch.isHittable { app.swipeUp() }
        XCTAssertTrue(restoreButtons.firstMatch.isHittable)
        restoreButtons.firstMatch.tap()
        XCTAssertTrue(historyRows.firstMatch.waitForExistence(timeout: 5), "Restoring should return the record to the Training history list")
    }

    private func replaceText(in field: XCUIElement, with value: String) {
        field.tap()
        let current = field.value as? String ?? ""
        if !current.isEmpty {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        field.typeText(value)
    }

    private func launchApp(themeID: String? = nil, progressionHistory: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        if progressionHistory { app.launchArguments.append("--qa-progression-history") }
        app.launchArguments.append("--qa-storage-id=\(UUID().uuidString)")
        app.launchArguments.append("--qa-theme=\(themeID ?? "default")")
        app.launch()
        XCTAssertTrue(app.buttons["home-widget-kcal"].waitForExistence(timeout: 20))
        return app
    }

    private func capturePage(_ pageName: String, in app: XCUIApplication) {
        let pageButton = app.buttons["\(pageName) page"]
        XCTAssertTrue(pageButton.waitForExistence(timeout: 5), "Missing Home page \(pageName)")
        pageButton.tap()
        XCTAssertTrue(app.staticTexts[pageName].waitForExistence(timeout: 5), "Page \(pageName) did not become visible")
        attachScreenshot(of: app, named: "Home-\(pageName.replacingOccurrences(of: " ", with: "-"))")
    }

    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
