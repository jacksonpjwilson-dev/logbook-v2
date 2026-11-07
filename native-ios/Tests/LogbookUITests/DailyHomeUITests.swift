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
        let activeExerciseHeader = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "active-exercise-header-")
        ).firstMatch
        XCTAssertTrue(activeExerciseHeader.waitForExistence(timeout: 5), "The active workout should render its current exercise")
        XCTAssertEqual((activeExerciseHeader.value as? String)?.lowercased(), "expanded", "The current exercise must be expanded when a session starts")
        attachScreenshot(of: app, named: "Training-Active-Workout-Default-Candidate")

        let timerWeight = inputField(app, labelled: "Weight in kilograms")
        scrollToElement(timerWeight, in: app)
        replaceText(in: timerWeight, with: "40")
        dismissKeyboard(in: app)
        attachScreenshot(of: app, named: "Training-Active-Workout-Set-Entry-Candidate")
        let completeFirstSet = app.buttons.matching(identifier: "Mark set complete").firstMatch
        XCTAssertTrue(completeFirstSet.waitForExistence(timeout: 5), "A planned set should be available to start its configured rest timer")
        completeFirstSet.tap()
        let timerStarted = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label != %@", "Ready"),
            object: restTimer
        )
        XCTAssertEqual(XCTWaiter.wait(for: [timerStarted], timeout: 5), .completed, "Completing a set should start its configured rest interval")
        let addTime = app.buttons["rest-add-15"]
        scrollToElement(addTime, in: app, towardTop: true)
        XCTAssertTrue(addTime.isHittable, "The timer extension control should be interactive")
        // The test fixture starts a 90-second exercise rest; extend it to 210 seconds
        // so simulator relaunch latency cannot turn this recovery test into a timer-expiry test.
        for _ in 0..<8 {
            addTime.tap()
        }
        XCTAssertNotEqual(restTimer.label, "Ready", "The timer should still be active before pausing")
        let timerToggle = app.buttons["rest-toggle"]
        XCTAssertTrue(timerToggle.waitForExistence(timeout: 5), "The rest timer needs one stable pause/resume control")
        timerToggle.tap()
        let timerPaused = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "Paused"),
            object: timerToggle
        )
        XCTAssertEqual(XCTWaiter.wait(for: [timerPaused], timeout: 5), .completed, "Pausing should preserve the timer and expose its paused state")
        let pausedRemaining = restTimer.label
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["home-widget-kcal"].waitForExistence(timeout: 10), "The app should reopen to Home after termination")
        app.buttons["Training tab"].tap()

        let resumeWorkout = app.buttons["training-active-session"]
        XCTAssertTrue(resumeWorkout.waitForExistence(timeout: 5), "A terminated app should retain a non-intrusive Resume Workout entry")
        resumeWorkout.tap()
        let recoveredTimer = app.descendants(matching: .any)["rest-timer-value"]
        XCTAssertTrue(recoveredTimer.waitForExistence(timeout: 5), "The saved in-progress session resumes from Training")
        XCTAssertEqual(recoveredTimer.label, pausedRemaining, "The paused remaining time must survive app termination")
        let resumeTimer = app.buttons["rest-toggle"]
        XCTAssertTrue(resumeTimer.waitForExistence(timeout: 5), "The recovered timer should preserve its paused state")
        XCTAssertEqual(resumeTimer.value as? String, "Paused")
        resumeTimer.tap()
        let timerRunning = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "Running"),
            object: resumeTimer
        )
        XCTAssertEqual(XCTWaiter.wait(for: [timerRunning], timeout: 5), .completed, "The recovered timer should resume into its running state")
        XCTAssertNotEqual(recoveredTimer.label, "Ready", "The recovered timer should continue running after resume")
    }

    func testDefaultTrainingHomeShowsSplitTilesAndNavigableWorkoutCalendar() throws {
        // This isolated fixture contains eight real synthetic plan records so the
        // screenshot exercises every tile in the approved 2-column × 4-row grid.
        let app = launchApp(trainingSplitCount: 8)
        app.buttons["Training page"].tap()

        let allSplitTiles = (1...8).map { app.buttons["training-split-workout-\($0)"] }
        for tile in allSplitTiles {
            XCTAssertTrue(tile.waitForExistence(timeout: 5), "All eight synthetic workout tiles should render in the full split candidate")
        }
        let firstWorkout = app.buttons["training-split-workout-1"]
        XCTAssertTrue(firstWorkout.waitForExistence(timeout: 5), "The split widget must show a tappable numbered workout tile")
        XCTAssertGreaterThanOrEqual(firstWorkout.frame.height, 27, "Split rows should use the available four-row grid height")
        XCTAssertLessThanOrEqual(firstWorkout.frame.height, 100, "A split item must stay a compact tile instead of stretching into a nested card")
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
        let reorderHandles = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[cd] %@", "reorder"))
        XCTAssertGreaterThanOrEqual(reorderHandles.count, 2, "Edit mode should expose a drag handle for each workout row. UI: \(app.debugDescription)")
        let sourceHandle = reorderHandles.element(boundBy: 0)
        let destinationHandle = reorderHandles.element(boundBy: 1)
        sourceHandle.press(forDuration: 1.2, thenDragTo: destinationHandle)
        let reordered = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "identifier == %@", secondID),
            object: rows.element(boundBy: 0)
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [reordered], timeout: 5),
            .completed,
            "Dragging a workout handle should update the saved split order"
        )
        XCTAssertNotEqual(rows.element(boundBy: 0).identifier, firstID)
        app.buttons["Done"].tap()

        rows.firstMatch.tap()
        XCTAssertTrue(app.buttons["workout-template-add-exercise"].waitForExistence(timeout: 5))
        app.buttons["workout-template-add-exercise"].tap()
        XCTAssertTrue(app.navigationBars["Choose exercise"].waitForExistence(timeout: 5))
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("bench")
        XCTAssertTrue((search.value as? String)?.localizedCaseInsensitiveContains("bench") == true,
                      "The exercise search query should be accepted by the real picker")
        let result = app.descendants(matching: .any)["exercise-picker-result-builtin-2"]
        XCTAssertTrue(result.waitForExistence(timeout: 5),
                      "Search should expose the catalog's Flat barbell bench press exercise. UI: \(app.debugDescription)")
        result.tap()
        XCTAssertTrue(app.staticTexts["Flat barbell bench press"].waitForExistence(timeout: 5), "Selecting a search result should persist it in the workout plan")

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

        // Open the selected catalog exercise through its stable disclosure row.
        let exerciseRow = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS[cd] %@", "planned-exercise-", "Flat barbell bench press")
        ).firstMatch
        XCTAssertTrue(exerciseRow.waitForExistence(timeout: 5), "The selected exercise has an identifiable disclosure row")
        if (exerciseRow.value as? String)?.lowercased() != "expanded" { exerciseRow.tap() }
        let sets = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "planned-exercise-sets-")
        ).firstMatch
        XCTAssertTrue(sets.waitForExistence(timeout: 5), "The selected exercise exposes its planned set configuration")
        let increaseSets = sets.buttons["Increment"]
        if increaseSets.exists { increaseSets.tap() }
        else { sets.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap() }
        XCTAssertTrue(app.staticTexts["Sets · 4"].waitForExistence(timeout: 5), "Set-count customization should update the saved plan")

        let reps = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "planned-exercise-reps-")
        ).firstMatch
        XCTAssertTrue(reps.waitForExistence(timeout: 5))
        let increaseReps = reps.buttons["Increment"]
        if increaseReps.exists { increaseReps.tap() }
        else { reps.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap() }
        XCTAssertTrue(app.staticTexts["Reps · 9"].waitForExistence(timeout: 5), "Rep-count customization should update the saved plan")

        let rest = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "planned-exercise-rest-")
        ).firstMatch
        XCTAssertTrue(rest.waitForExistence(timeout: 5))
        let increaseRest = rest.buttons["Increment"]
        if increaseRest.exists { increaseRest.tap() }
        else { rest.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap() }
        XCTAssertTrue(app.staticTexts["Rest · 105s"].waitForExistence(timeout: 5), "Exercise-specific rest configuration should be retained")

        attachScreenshot(of: app, named: "Training-Split-Editor-Candidate")
    }

    func testProgressionSuggestionRequiresAndAppliesExplicitAcceptance() throws {
        let app = launchApp()
        app.buttons["Training tab"].tap()
        let template = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "training-template-")).firstMatch
        XCTAssertTrue(template.waitForExistence(timeout: 5))
        template.tap()
        XCTAssertTrue(app.buttons["workout-template-start"].waitForExistence(timeout: 5))
        app.buttons["workout-template-start"].tap()

        // Create a real prior workout through the UI so the next session exercises the
        // same history lookup used in normal use, rather than depending on hidden seed data.
        let firstSetWeight = inputField(app, labelled: "Weight in kilograms")
        XCTAssertTrue(firstSetWeight.waitForExistence(timeout: 5))
        scrollToElement(firstSetWeight, in: app)
        replaceText(in: firstSetWeight, with: "60")
        dismissKeyboard(in: app)
        app.buttons.matching(identifier: "Mark set complete").firstMatch.tap()
        let finish = app.buttons["finish-workout"]
        XCTAssertTrue(finish.waitForExistence(timeout: 5))
        finish.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let confirm = app.buttons["confirm-finish-workout"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "Saving a partially completed workout requires an explicit confirmation")
        confirm.tap()
        XCTAssertTrue(app.navigationBars["Workout saved"].waitForExistence(timeout: 5))
        app.buttons["workout-summary-done"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        let nextTemplate = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "training-template-")).firstMatch
        XCTAssertTrue(nextTemplate.waitForExistence(timeout: 5))
        nextTemplate.tap()
        app.buttons["workout-template-start"].tap()

        let suggestion = app.buttons["accept-progression-suggestion"]
        XCTAssertTrue(suggestion.waitForExistence(timeout: 5), "The newly saved completed set should produce an optional next-session suggestion")
        let suggestedText = suggestion.label
        let suggestedLoad: Double? = {
            guard let raw = suggestedText.components(separatedBy: "·").last else { return nil }
            return Double(raw.replacingOccurrences(of: "kg", with: "").trimmingCharacters(in: .whitespaces))
        }()
        XCTAssertNotNil(suggestedLoad, "The suggestion should expose its proposed load: \(suggestedText)")
        let weight = inputField(app, labelled: "Weight in kilograms")
        XCTAssertTrue(weight.exists)
        XCTAssertNotEqual(Double(String(describing: weight.value ?? "")), suggestedLoad, "Suggested load must not be applied before explicit acceptance")
        scrollToElement(suggestion, in: app)
        suggestion.tap()
        // The suggestion lives after the set rows, so bring the first set row
        // back above the pinned footer before verifying its accepted value.
        scrollToElement(weight, in: app, towardTop: true)
        XCTAssertTrue(weight.isHittable, "The current set field should scroll above the pinned workout controls")
        let accepted = XCTNSPredicateExpectation(predicate: NSPredicate { object, _ in
            guard let field = object as? XCUIElement, let target = suggestedLoad else { return false }
            let value = String(describing: field.value ?? "")
            if let number = field.value as? NSNumber { return abs(number.doubleValue - target) < 0.01 }
            return Double(value.replacingOccurrences(of: ",", with: ".")).map { abs($0 - target) < 0.01 } ?? false
        }, object: weight)
        XCTAssertEqual(XCTWaiter.wait(for: [accepted], timeout: 5), .completed,
                       "Accepting \(suggestedText) should update the current set weight; current value: \(weight.value ?? "nil")")
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
        let firstWeight = app.textFields["Weight in kilograms"].firstMatch
        scrollToElement(firstWeight, in: app)
        replaceText(in: firstWeight, with: "40")
        dismissKeyboard(in: app)
        app.buttons.matching(identifier: "Mark set complete").firstMatch.tap()
        XCTAssertTrue(finish.isHittable, "Finish & Save should remain reachable after set entry")
        finish.tap()
        let confirmSave = app.buttons["confirm-finish-workout"]
        XCTAssertTrue(confirmSave.waitForExistence(timeout: 5))
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
        let historyRows = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "history-workout-"))
        let historyList = app.collectionViews.firstMatch
        for _ in 0..<12 where !historyRows.firstMatch.exists { historyList.swipeUp() }
        XCTAssertTrue(historyRows.firstMatch.waitForExistence(timeout: 5), "A saved workout should appear in History after scrolling past the charts")
        for _ in 0..<5 where !historyRows.firstMatch.isHittable { historyList.swipeUp() }
        XCTAssertTrue(historyRows.firstMatch.isHittable)
        historyRows.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Upper Body"].waitForExistence(timeout: 5))
        attachScreenshot(of: app, named: "Training-History-Detail-Candidate")

        let historyWeight = inputField(app, labelled: "history-set-weight")
        XCTAssertTrue(historyWeight.waitForExistence(timeout: 5))
        replaceText(in: historyWeight, with: "40")
        let historyReps = inputField(app, labelled: "history-set-reps")
        replaceText(in: historyReps, with: "8")
        let completionToggles = app.buttons.matching(identifier: "history-set-complete")
        completionToggles.firstMatch.tap()
        let historicalCompletionUpdated = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Mark set complete"),
            object: completionToggles.firstMatch
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [historicalCompletionUpdated], timeout: 5),
            .completed,
            "Historical set completion should update after the store publishes its edit"
        )
        let notes = app.descendants(matching: .any)["history-workout-notes"]
        XCTAssertTrue(notes.waitForExistence(timeout: 5), "Workout notes remain editable in the multiline history field")
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

    private func inputField(_ app: XCUIApplication, labelled label: String) -> XCUIElement {
        let stablePrefix: String
        switch label {
        case "Weight in kilograms": stablePrefix = "workout-set-weight-"
        case "Repetitions": stablePrefix = "workout-set-reps-"
        case "history-set-weight": stablePrefix = "history-set-weight"
        case "history-set-reps": stablePrefix = "history-set-reps"
        default: stablePrefix = label
        }
        let matching = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier == %@ OR identifier BEGINSWITH %@ OR label CONTAINS[cd] %@", label, stablePrefix, label)
        )
        return matching.firstMatch
    }

    private func scrollToElement(_ element: XCUIElement, in app: XCUIApplication, towardTop: Bool = false) {
        let list = app.collectionViews.firstMatch
        let pinnedFooter = app.buttons["finish-workout"]
        for _ in 0..<10 {
            if element.exists {
                let aboveFooter = !pinnedFooter.exists || element.frame.maxY < pinnedFooter.frame.minY - 8
                if element.isHittable && aboveFooter { return }
            }
            // Lazy List rows may not enter the accessibility tree until they are
            // scrolled into view; avoid reading a missing element's frame first.
            if towardTop { list.swipeDown() } else { list.swipeUp() }
        }
    }

    private func dismissKeyboard(in app: XCUIApplication) {
        let done = app.buttons["keyboard-done"]
        if done.waitForExistence(timeout: 1) { done.tap() }
        else if app.keyboards.buttons["Done"].exists { app.keyboards.buttons["Done"].tap() }
    }

    private func replaceText(in field: XCUIElement, with value: String) {
        field.tap()
        let current = field.value as? String ?? ""
        if !current.isEmpty {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        field.typeText(value)
    }

    private func launchApp(themeID: String? = nil, progressionHistory: Bool = false, trainingSplitCount: Int? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        if progressionHistory { app.launchArguments.append("--qa-progression-history") }
        if trainingSplitCount == 8 { app.launchArguments.append("--qa-training-split-eight") }
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
