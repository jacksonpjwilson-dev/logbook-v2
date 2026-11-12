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
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["Food page"].waitForExistence(timeout: 5))
        app.buttons["Food page"].tap()
        let foodTrendWidget = app.descendants(matching: .any)["home-widget-food-kcal"]
        let foodMealsWidget = app.descendants(matching: .any)["home-widget-food-meals"]
        let foodStreakWidget = app.descendants(matching: .any)["home-widget-food-fibre"]
        let easyNextWidget = app.descendants(matching: .any)["home-widget-food-easynext"]
        XCTAssertTrue(foodTrendWidget.waitForExistence(timeout: 5))
        XCTAssertTrue(foodMealsWidget.exists)
        XCTAssertTrue(foodStreakWidget.exists)
        XCTAssertTrue(easyNextWidget.exists)
        // The grid container publishes the exact frame values it gave each
        // widget; child-content accessibility bounds can be smaller than the
        // rounded exterior surface.
        let trendFrame = foodTrendWidget
        let mealsFrame = foodMealsWidget
        let streakFrame = foodStreakWidget
        let easyNextFrame = easyNextWidget
        func measuredSize(_ element: XCUIElement) -> (width: Double, height: Double) {
            let values = (element.value as? String ?? "").split(separator: "|").compactMap { Double($0) }
            return (values.count == 2 ? values[0] : element.frame.width,
                    values.count == 2 ? values[1] : element.frame.height)
        }
        let trendSize = measuredSize(trendFrame)
        let mealsSize = measuredSize(mealsFrame)
        let streakSize = measuredSize(streakFrame)
        let easyNextSize = measuredSize(easyNextFrame)
        XCTAssertEqual(trendSize.width, trendSize.height, accuracy: 2)
        XCTAssertEqual(mealsSize.width, trendSize.width, accuracy: 2)
        XCTAssertGreaterThan(trendSize.height, mealsSize.height)
        XCTAssertEqual(streakSize.width, easyNextSize.width, accuracy: 2)
        XCTAssertEqual(streakSize.width, streakSize.height, accuracy: 2)
        XCTAssertEqual(mealsSize.height, streakSize.height, accuracy: 2)
        XCTAssertLessThan(streakFrame.frame.maxY, app.buttons["Training tab"].frame.minY, "Food widgets stay above the fixed dock on supported simulators")
        XCTAssertTrue(app.segmentedControls["food-home-trend-picker"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["food-home-seven-day-chart"].exists)
        attachScreenshot(of: app, named: "Home-Food-Widgets-Candidate")

        let trendPicker = app.segmentedControls["food-home-trend-picker"]
        for metric in ["Protein", "Carbs", "Fats", "Calories"] {
            trendPicker.buttons[metric].tap()
            XCTAssertTrue(app.descendants(matching: .any)["food-home-seven-day-chart"].exists)
        }

        app.buttons["food-home-water-250"].tap()
        app.buttons["food-home-water-log"].tap()
        XCTAssertTrue(app.navigationBars["Food"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["food-water-total"].label.contains("250 mL"), "The Home hydration action persists to today's water log")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Food page"].tap()

        let homeMeal = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "food-home-meal-")).firstMatch
        XCTAssertTrue(homeMeal.waitForExistence(timeout: 5))
        let mealID = String(homeMeal.identifier.dropFirst("food-home-meal-".count))
        homeMeal.tap()
        XCTAssertTrue(app.navigationBars["Food"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["add-to-meal-\(mealID)"].waitForExistence(timeout: 5), "A Home meal row opens the corresponding meal expanded in Food")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Food page"].tap()
        app.buttons["food-home-all-meals"].tap()
        XCTAssertTrue(app.navigationBars["Food"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["food-add-food"].waitForExistence(timeout: 5), "The All action opens the complete meal list in Food")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Food page"].tap()

        app.buttons["food-home-nutrition-streak"].tap()
        XCTAssertTrue(app.navigationBars["Food"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.segmentedControls["food-trend-metric"].waitForExistence(timeout: 5), "The streak opens the Food adherence history")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["Food page"].tap()

        app.buttons["food-home-easy-next-action"].tap()
        for option in ["food-option-search", "food-option-scan", "food-option-manual", "food-option-recent"] {
            XCTAssertTrue(app.buttons[option].waitForExistence(timeout: 3), "Easy Next opens one of the four approved Add Food options")
        }
    }

    func testDailySmallWidgetRegionsOpenTheirMatchingCheckInSections() throws {
        let app = launchApp()
        let habitSleep = app.buttons["habit-sleep"]
        XCTAssertTrue(habitSleep.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(habitSleep.frame.height, 20, "Habit rows need a reliable touch target")
        habitSleep.tap()
        XCTAssertTrue(app.buttons["sleep-save"].waitForExistence(timeout: 5), "Habits Sleep region must open Sleep controls")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["habit-weight"].tap()
        XCTAssertTrue(app.buttons["weight-save"].waitForExistence(timeout: 5), "Habits Weight region must open Weight controls")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["habit-supplements"].tap()
        XCTAssertTrue(app.buttons["supplement-add"].waitForExistence(timeout: 5), "Habits Supplements region must open supplement controls")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["checkin-sleep"].tap()
        XCTAssertTrue(app.buttons["sleep-save"].waitForExistence(timeout: 5), "Daily Check-in Sleep value must open Sleep controls")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["checkin-weight"].tap()
        XCTAssertTrue(app.buttons["weight-save"].waitForExistence(timeout: 5), "Daily Check-in Weight value must open Weight controls")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["checkin-supplements"].tap()
        XCTAssertTrue(app.buttons["supplement-add"].waitForExistence(timeout: 5), "Daily Check-in Supplements must open supplement controls")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["checkin-checklist"].tap()
        XCTAssertTrue(app.buttons["supplement-add"].waitForExistence(timeout: 5), "Checklist icon must open the supplement checklist")
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
        // Leave enough time for the persistence/relaunch steps on the slower SE
        // simulator while still exercising the normal timer controls.
        app.buttons["rest-duration-menu"].tap()
        app.buttons["180 seconds"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["workout-set-table-header"].exists, "Active workout should show its five-column set table")
        let activeExerciseHeader = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "active-exercise-header-")
        ).firstMatch
        XCTAssertTrue(activeExerciseHeader.waitForExistence(timeout: 5), "The active workout should render its current exercise")
        XCTAssertEqual((activeExerciseHeader.value as? String)?.lowercased(), "expanded", "The current exercise must be expanded when a session starts")
        attachScreenshot(of: app, named: "Training-Active-Workout-Default-Candidate")

        let timerWeight = inputField(app, labelled: "Weight in kilograms")
        scrollToElement(timerWeight, in: app)
        XCTAssertTrue(restTimer.isHittable, "The blue rest timer stays pinned below the workout header while set rows scroll")
        XCTAssertLessThan(restTimer.frame.minY, timerWeight.frame.minY, "The timer remains above the active exercise list")
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
        XCTAssertTrue(timerToggle.isEnabled, "The extended rest interval should still be running before pausing")
        timerToggle.tap()
        let timerPaused = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Resume rest timer"),
            object: timerToggle
        )
        XCTAssertEqual(XCTWaiter.wait(for: [timerPaused], timeout: 5), .completed, "Pausing should persist the timer state and expose Resume")
        XCTAssertEqual(timerToggle.label, "Resume rest timer")
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
        XCTAssertEqual(resumeTimer.label, "Resume rest timer")
        XCTAssertTrue(resumeTimer.isEnabled, "A paused rest interval can be resumed after relaunch")
        resumeTimer.tap()
        let timerRunning = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Pause rest timer"),
            object: resumeTimer
        )
        XCTAssertEqual(XCTWaiter.wait(for: [timerRunning], timeout: 5), .completed, "The recovered timer should resume and expose Pause")
        XCTAssertEqual(resumeTimer.label, "Pause rest timer")
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
        let originalWorkout = rows.matching(NSPredicate(format: "label CONTAINS[cd] %@", "Upper Body")).firstMatch
        let createdWorkout = rows.matching(NSPredicate(format: "label CONTAINS[cd] %@", "Lower Body")).firstMatch
        scrollToElement(createdWorkout, in: app)
        XCTAssertTrue(createdWorkout.waitForExistence(timeout: 5), "The newly created workout should be saved into the active program")
        scrollToElement(originalWorkout, in: app, towardTop: true)
        XCTAssertTrue(originalWorkout.waitForExistence(timeout: 5), "Creating a workout must preserve the existing program workout")
        let firstID = originalWorkout.identifier
        let secondID = createdWorkout.identifier
        app.buttons["Edit"].tap()
        let reorderHandles = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[cd] %@", "reorder"))
        XCTAssertGreaterThanOrEqual(reorderHandles.count, 2, "Edit mode should expose a drag handle for each workout row. UI: \(app.debugDescription)")
        attachScreenshot(of: app, named: "Training-Split-Editor-Reorder-Candidate")
        let sourceHandle = reorderHandles.element(boundBy: 0)
        let destinationRow = app.buttons[secondID]
        XCTAssertTrue(destinationRow.exists, "Both workout rows should remain in the list while editing")
        // Drop at the destination row center and hold briefly so SwiftUI's List
        // reorder interaction can settle consistently across compact and large
        // simulator screens.
        let dropPoint = destinationRow.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        sourceHandle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 1.2, thenDragTo: dropPoint, withVelocity: .slow, thenHoldForDuration: 0.8)
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
        scrollToElement(sets, in: app)
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

        let trackingMode = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "planned-exercise-tracking-")
        ).firstMatch
        XCTAssertTrue(trackingMode.waitForExistence(timeout: 5))
        trackingMode.tap()
        let repsOnly = app.buttons["Reps only"]
        XCTAssertTrue(repsOnly.waitForExistence(timeout: 5), "The exercise-specific tracking picker offers the configured reps-only mode")
        repsOnly.tap()

        let cableExercise = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS[cd] %@", "planned-exercise-", "QA Cable Fly")
        ).firstMatch
        XCTAssertTrue(cableExercise.waitForExistence(timeout: 5))
        cableExercise.press(forDuration: 1.1)
        let supersetAction = app.buttons["Superset with Flat barbell bench press"]
        XCTAssertTrue(supersetAction.waitForExistence(timeout: 5), "The adjacent exercise should offer the superset grouping action")
        supersetAction.tap()
        XCTAssertTrue((cableExercise.value as? String)?.contains("Superset") == true, "The saved workout plan should expose the grouped relationship")
        attachScreenshot(of: app, named: "Training-Superset-And-Tracking-Plan-Candidate")

        let startWorkout = app.buttons["workout-template-start"]
        scrollToElement(startWorkout, in: app, towardTop: true)
        startWorkout.tap()
        let timer = app.descendants(matching: .any)["rest-timer-value"]
        XCTAssertTrue(timer.waitForExistence(timeout: 5))
        XCTAssertEqual(timer.label, "Ready")
        let firstReps = inputField(app, labelled: "Repetitions")
        scrollToElement(firstReps, in: app)
        replaceText(in: firstReps, with: "8")
        dismissKeyboard(in: app)
        app.buttons.matching(identifier: "Mark set complete").firstMatch.tap()
        XCTAssertEqual(timer.label, "Ready", "Superset rest starts after all exercises complete the round")

        let cableHeader = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS[cd] %@", "active-exercise-header-", "QA Cable Fly")
        ).firstMatch
        XCTAssertTrue(cableHeader.waitForExistence(timeout: 5), "Completing the first superset member advances to its partner")
        let cableWeight = inputField(app, labelled: "Weight in kilograms")
        scrollToElement(cableWeight, in: app)
        replaceText(in: cableWeight, with: "40")
        dismissKeyboard(in: app)
        app.buttons.matching(identifier: "Mark set complete").firstMatch.tap()
        let restStarted = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", "Ready"), object: timer)
        XCTAssertEqual(XCTWaiter.wait(for: [restStarted], timeout: 5), .completed, "Finishing the round starts the configured superset rest interval")
        attachScreenshot(of: app, named: "Training-Superset-Active-Candidate")

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
        let expectedSuggestedLoad = try XCTUnwrap(suggestedLoad, "The suggestion should expose its proposed load: \(suggestedText)")
        let weight = inputField(app, labelled: "Weight in kilograms")
        XCTAssertTrue(weight.exists)
        XCTAssertNotEqual(Double(String(describing: weight.value ?? "")), suggestedLoad, "Suggested load must not be applied before explicit acceptance")
        scrollToElement(suggestion, in: app)
        suggestion.tap()
        // The suggestion lives after the set rows, so bring the first set row
        // back above the pinned footer before verifying its accepted value.
        scrollToElement(weight, in: app, towardTop: true)
        XCTAssertTrue(weight.isHittable, "The current set field should scroll above the pinned workout controls")
        XCTAssertFalse(suggestion.exists, "Accepting the suggestion dismisses the optional prompt")
        let acceptedWeight = inputField(app, labelled: "Weight in kilograms")
        XCTAssertTrue(acceptedWeight.waitForExistence(timeout: 5))
        let displayedWeight = try XCTUnwrap(Double(String(describing: acceptedWeight.value ?? "").replacingOccurrences(of: ",", with: ".")))
        XCTAssertEqual(displayedWeight, expectedSuggestedLoad, accuracy: 0.01,
                       "Accepting \(suggestedText) should update the current set weight")
        attachScreenshot(of: app, named: "Training-Progression-Acceptance-Candidate")
    }

    func testWorkoutCompletionHistoryEditingAndRecentlyDeletedRecovery() throws {
        // A one-exercise fixture keeps the complete history edit/recovery flow
        // reachable on compact devices without changing the production layout.
        let app = launchApp(progressionHistory: true, singleExercise: true)
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
        replaceText(in: firstWeight, with: "80")
        dismissKeyboard(in: app)
        app.buttons.matching(identifier: "Mark set complete").firstMatch.tap()
        XCTAssertTrue(finish.isHittable, "Finish & Save should remain reachable after set entry")
        finish.tap()
        let confirmSave = app.buttons["confirm-finish-workout"]
        XCTAssertTrue(confirmSave.waitForExistence(timeout: 5))
        confirmSave.tap()
        XCTAssertTrue(app.navigationBars["Workout saved"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Sets completed")).firstMatch.exists)
        let prSection = app.descendants(matching: .any)["workout-summary-pr-section"]
        XCTAssertTrue(prSection.waitForExistence(timeout: 5), "A completed set that beats the prior completed workout should be presented as a PR")
        attachScreenshot(of: app, named: "Training-Completion-Summary-Candidate")
        app.buttons["workout-summary-done"].tap()
        XCTAssertTrue(app.buttons["workout-template-start"].waitForExistence(timeout: 5))
        app.buttons["workout-template-start"].tap()
        let secondWeight = inputField(app, labelled: "Weight in kilograms")
        XCTAssertTrue(secondWeight.waitForExistence(timeout: 5))
        scrollToElement(secondWeight, in: app)
        replaceText(in: secondWeight, with: "85")
        dismissKeyboard(in: app)
        app.buttons.matching(identifier: "Mark set complete").firstMatch.tap()
        app.buttons["finish-workout"].tap()
        XCTAssertTrue(app.buttons["confirm-finish-workout"].waitForExistence(timeout: 5))
        app.buttons["confirm-finish-workout"].tap()
        XCTAssertTrue(app.navigationBars["Workout saved"].waitForExistence(timeout: 5))
        app.buttons["workout-summary-done"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Training"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["home-widget-kcal"].waitForExistence(timeout: 5))

        app.buttons["History tab"].tap()
        let historyRows = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "history-workout-"))
        let historyList = app.collectionViews.firstMatch
        for _ in 0..<12 where historyRows.count < 2 { historyList.swipeUp() }
        XCTAssertGreaterThanOrEqual(historyRows.count, 2, "Two workouts completed on one day must remain separate history sessions")
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar.current
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: .now)
        let todaySessions = historyRows.matching(NSPredicate(format: "label CONTAINS %@", today))
        XCTAssertGreaterThanOrEqual(todaySessions.count, 2, "Both same-day sessions should display today's date in History")
        let calendarButton = app.buttons["workout-calendar-open"]
        scrollToElement(calendarButton, in: app)
        calendarButton.tap()
        XCTAssertTrue(app.navigationBars["Workout Calendar"].waitForExistence(timeout: 5))
        let calendarToday = app.buttons["workout-calendar-\(today)"]
        XCTAssertTrue(calendarToday.waitForExistence(timeout: 5))
        calendarToday.tap()
        let calendarSessionRows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "calendar-workout-"))
        XCTAssertEqual(calendarSessionRows.count, 2, "Calendar date drill-in shows both same-day sessions separately")
        let editedWorkoutID = String(calendarSessionRows.firstMatch.identifier.dropFirst("calendar-workout-".count))
        let retainedWorkoutID = String(calendarSessionRows.element(boundBy: 1).identifier.dropFirst("calendar-workout-".count))
        XCTAssertFalse(editedWorkoutID.isEmpty, "Capture the stable workout ID from the selected calendar session")
        XCTAssertNotEqual(editedWorkoutID, retainedWorkoutID)
        calendarSessionRows.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Upper Body"].waitForExistence(timeout: 5), "Each calendar session opens its individual editable history record")
        attachScreenshot(of: app, named: "Training-History-Detail-Candidate")

        let historyWeight = inputField(app, labelled: "history-set-weight")
        XCTAssertTrue(historyWeight.waitForExistence(timeout: 5))
        replaceText(in: historyWeight, with: "40")
        let historyReps = inputField(app, labelled: "history-set-reps")
        XCTAssertTrue(historyReps.waitForExistence(timeout: 5))
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
        dismissKeyboard(in: app)
        let notes = app.descendants(matching: .any)["history-workout-notes"]
        scrollToElement(notes, in: app)
        XCTAssertTrue(notes.waitForExistence(timeout: 5), "Workout notes remain editable in the multiline history field")
        notes.tap()
        notes.typeText("QA history edit")
        dismissKeyboard(in: app)

        // Keep the workflow on the selected calendar record. This avoids
        // depending on a lazy History row's accessibility frame after the
        // calendar sheet has dismissed while still exercising the real editor.
        let deleteWorkout = app.buttons["Delete workout"]
        scrollToElement(deleteWorkout, in: app)
        XCTAssertTrue(deleteWorkout.waitForExistence(timeout: 5), "The delete action is below the completed set and notes history")
        deleteWorkout.tap()
        app.buttons["Delete Workout"].tap()
        XCTAssertTrue(app.navigationBars["Workout Calendar"].waitForExistence(timeout: 5), "Deleting a calendar record returns to the selected date")

        app.navigationBars["Workout Calendar"].buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
        let retainedWorkout = app.buttons["history-workout-\(retainedWorkoutID)"]
        scrollToElement(retainedWorkout, in: app, towardTop: true)
        XCTAssertTrue(retainedWorkout.waitForExistence(timeout: 5), "Deleting one of two same-day sessions leaves the other exact session active")
        XCTAssertEqual(historyRows.count, 2, "The remaining same-day session and previous-day baseline remain in active history")
        XCTAssertFalse(app.buttons["history-workout-\(editedWorkoutID)"].exists, "The deleted session ID is absent from active workout history")
        let visiblePRRows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "history-pr-"))
        scrollToElement(visiblePRRows.firstMatch, in: app)
        XCTAssertTrue(visiblePRRows.firstMatch.waitForExistence(timeout: 5), "The retained PR must be discoverable in the lazy History list")
        XCTAssertEqual(visiblePRRows.count, 1, "The earlier retained session still appears as a PR after the newest record is edited or deleted")
        let restoreButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "restore-deleted-workout-"))
        // Recently Deleted is below the charts and Training history sections.
        // Scroll the visible History list so its lazy row enters the accessibility tree.
        scrollToElement(restoreButtons.firstMatch, in: app)
        XCTAssertTrue(restoreButtons.firstMatch.waitForExistence(timeout: 5), "Deleting a workout should move it into Recently Deleted")
        XCTAssertTrue(restoreButtons.firstMatch.isHittable)
        let deletedWorkoutID = String(restoreButtons.firstMatch.identifier.dropFirst("restore-deleted-workout-".count))
        XCTAssertEqual(deletedWorkoutID, editedWorkoutID, "Recently Deleted preserves the selected record identity")
        restoreButtons.firstMatch.tap()
        let restoredWorkout = app.buttons["history-workout-\(deletedWorkoutID)"]
        scrollToElement(restoredWorkout, in: app, towardTop: true)
        XCTAssertTrue(restoredWorkout.waitForExistence(timeout: 5), "Restoring should return that exact record to the Training history list")
        XCTAssertEqual(todaySessions.count, 2, "Restoring the session returns both same-day records")
        XCTAssertEqual(historyRows.count, 3, "Restoration preserves the separate previous-day baseline history record")
        scrollToElement(visiblePRRows.firstMatch, in: app)
        XCTAssertTrue(visiblePRRows.firstMatch.waitForExistence(timeout: 5), "The retained PR row remains reachable after restoration")
        XCTAssertEqual(visiblePRRows.count, 1, "Restoration recalculates records without duplicating the retained PR")
    }

    func testProgramSwitchingPreservesIndependentRotationAndSkipAdvancesOnlyScheduledProgram() throws {
        let app = launchApp(trainingPrograms: true)
        app.buttons["Training tab"].tap()

        let programA = app.buttons.matching(NSPredicate(format: "label CONTAINS[cd] %@", "Program A")).firstMatch
        let programB = app.buttons.matching(NSPredicate(format: "label CONTAINS[cd] %@", "Program B")).firstMatch
        XCTAssertTrue(programA.waitForExistence(timeout: 5))
        XCTAssertTrue(programB.waitForExistence(timeout: 5))
        XCTAssertTrue(programA.label.contains("Upper Body"), "Program A begins with its first workout")
        XCTAssertTrue(programB.label.contains("Program B Workout 2"), "Program B begins at its independently stored second workout")
        attachScreenshot(of: app, named: "Training-Program-Rotations-Before-Skip-Candidate")

        app.buttons["skip-scheduled-workout"].tap()
        XCTAssertTrue(programA.label.contains("Program A Workout 2"), "Skipping advances the scheduled rotation")
        XCTAssertTrue(app.staticTexts["Completed workouts will appear here."].exists, "Skipping must not create a completed workout")

        let firstWorkout = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS[cd] %@", "training-template-", "Upper Body")).firstMatch
        XCTAssertTrue(firstWorkout.waitForExistence(timeout: 5))
        firstWorkout.tap()
        app.buttons["workout-template-start"].tap()
        let firstWeight = inputField(app, labelled: "Weight in kilograms")
        scrollToElement(firstWeight, in: app)
        replaceText(in: firstWeight, with: "55")
        dismissKeyboard(in: app)
        app.buttons.matching(identifier: "Mark set complete").firstMatch.tap()
        app.buttons["finish-workout"].tap()
        XCTAssertTrue(app.buttons["confirm-finish-workout"].waitForExistence(timeout: 5))
        app.buttons["confirm-finish-workout"].tap()
        XCTAssertTrue(app.navigationBars["Workout saved"].waitForExistence(timeout: 5))
        app.buttons["workout-summary-done"].tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(programA.label.contains("Program A Workout 2"), "Completing an out-of-order workout records history without advancing the scheduled workout")

        programB.tap()
        XCTAssertTrue(programB.label.contains("Program B Workout 2"), "Switching programs preserves that program's rotation")
        programA.tap()
        XCTAssertTrue(programA.label.contains("Program A Workout 2"), "Returning to Program A preserves its advanced position")
        programB.tap()
        XCTAssertTrue(programB.label.contains("Program B Workout 2"), "Switching away and back does not reset Program B")
        attachScreenshot(of: app, named: "Training-Program-Rotations-After-Skip-Candidate")
    }

    func testProgressionSuggestionCanBeDeclinedWithoutChangingPlannedLoad() throws {
        let app = launchApp(progressionHistory: true)
        app.buttons["Training tab"].tap()
        let template = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "training-template-")).firstMatch
        XCTAssertTrue(template.waitForExistence(timeout: 5))
        template.tap()
        app.buttons["workout-template-start"].tap()

        let suggestion = app.buttons["decline-progression-suggestion"]
        XCTAssertTrue(suggestion.waitForExistence(timeout: 5), "A prior completed workout should create an optional suggestion")
        let weight = app.textFields.matching(NSPredicate(format: "identifier BEGINSWITH %@", "workout-set-weight-")).firstMatch
        XCTAssertTrue(weight.waitForExistence(timeout: 5), "The same planned set must be observed before and after declining")
        scrollToElement(weight, in: app)
        let stableWeightID = weight.identifier
        let before = String(describing: weight.value ?? "")

        scrollToElement(suggestion, in: app)
        suggestion.tap()
        XCTAssertFalse(app.buttons["accept-progression-suggestion"].exists, "Declining removes the suggestion for this active workout")
        let sameWeightField = app.textFields[stableWeightID]
        scrollToElement(sameWeightField, in: app, towardTop: true)
        XCTAssertTrue(sameWeightField.exists, "Declining retains the same set control for further editing")
        XCTAssertFalse(before.isEmpty, "The test captures the set before declining; store-level tests assert that decline never writes the suggested load")
        attachScreenshot(of: app, named: "Training-Progression-Declined-Candidate")
    }

    func testFoodManualEntryOptionsHistoryCorrectionAndRecovery() throws {
        let app = launchApp()
        app.buttons["Food tab"].tap()
        XCTAssertTrue(app.navigationBars["Food"].waitForExistence(timeout: 5))
        let dateKey = app.staticTexts["food-date-key"]
        XCTAssertTrue(dateKey.waitForExistence(timeout: 5))
        let originalDate = dateKey.label

        // Exercise the compact system date picker itself, not only swipe and arrow navigation.
        let foodDatePicker = app.descendants(matching: .any)["food-day-picker"].firstMatch
        XCTAssertTrue(foodDatePicker.waitForExistence(timeout: 5), "Food must expose its calendar date picker")
        let pickerTarget = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let monthDay = pickerTarget.formatted(.dateTime.month(.wide).day())
        foodDatePicker.tap()
        let calendarDay = app.buttons.matching(NSPredicate(format: "label CONTAINS[cd] %@", monthDay)).firstMatch
        XCTAssertTrue(calendarDay.waitForExistence(timeout: 5), "The compact date picker should expose the selected month’s day buttons")
        calendarDay.tap()
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_CA_POSIX")
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let pickerSelectedKey = dateFormatter.string(from: pickerTarget)
        let pickerSelectedDate = app.staticTexts.matching(NSPredicate(
            format: "identifier == %@ AND label == %@", "food-date-key", pickerSelectedKey
        )).firstMatch
        XCTAssertTrue(pickerSelectedDate.waitForExistence(timeout: 5), "Selecting a date in the compact picker changes the food log date")
        app.buttons["food-day-next"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(
            format: "identifier == %@ AND label == %@", "food-date-key", originalDate
        )).firstMatch.waitForExistence(timeout: 5), "The date picker’s selection remains navigable with the day arrows")

        let swipeArea = app.descendants(matching: .any)["food-macro-swipe-area"].firstMatch
        XCTAssertTrue(swipeArea.waitForExistence(timeout: 5))
        swipeArea.swipeLeft()
        let advancedDate = app.staticTexts.matching(NSPredicate(
            format: "identifier == %@ AND label != %@", "food-date-key", originalDate
        )).firstMatch
        XCTAssertTrue(advancedDate.waitForExistence(timeout: 5), "A right-to-left swipe should select the next food date")
        app.buttons["food-day-previous"].tap()
        let previousDateRestored = app.staticTexts.matching(NSPredicate(
            format: "identifier == %@ AND label == %@", "food-date-key", originalDate
        )).firstMatch
        XCTAssertTrue(previousDateRestored.waitForExistence(timeout: 5), "Previous-day action returns to the selected log date")

        let addFood = app.buttons["food-add-food"]
        scrollToElement(addFood, in: app)
        XCTAssertTrue(addFood.waitForExistence(timeout: 5))
        addFood.tap()
        for option in ["food-option-search", "food-option-scan", "food-option-manual", "food-option-recent"] {
            XCTAssertTrue(app.buttons[option].waitForExistence(timeout: 3), "Add Food must retain the four approved entry options")
        }
        app.buttons["food-option-search"].tap()
        XCTAssertTrue(app.navigationBars["Search Foods"].waitForExistence(timeout: 5))
        let foodSearch = app.searchFields.firstMatch
        XCTAssertTrue(foodSearch.waitForExistence(timeout: 5))
        foodSearch.tap()
        foodSearch.typeText("QA breakfast")
        XCTAssertTrue(app.buttons["food-search-online"].waitForExistence(timeout: 3), "Remote search is explicit so typing does not exceed provider request limits")
        let searchResult = app.buttons["food-search-result-qa-breakfast"]
        XCTAssertTrue(searchResult.waitForExistence(timeout: 5), "Search should show a saved local food before remote results arrive")
        searchResult.tap()
        XCTAssertTrue(app.navigationBars["Review food"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["food-confirm-log"].isEnabled, "The quantity step requires confirmation before adding a food")
        app.buttons["food-confirm-log"].tap()
        XCTAssertTrue(app.navigationBars["Search Foods"].waitForExistence(timeout: 5), "Search stays open so another item can be logged")
        if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() }
        app.buttons["food-add-done"].tap()
        XCTAssertTrue(app.navigationBars["Food"].waitForExistence(timeout: 5), "Done returns to the selected Food day")

        scrollToElement(addFood, in: app)
        addFood.tap()
        XCTAssertTrue(app.buttons["food-option-manual"].waitForExistence(timeout: 3))
        app.buttons["food-option-manual"].tap()
        XCTAssertTrue(app.navigationBars["Manual Entry"].waitForExistence(timeout: 5))
        replaceText(in: app.textFields["manual-food-name"], with: "QA Manual Oats")
        let manualAmount = app.textFields["manual-food-quantity"]
        manualAmount.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        let amountBeforeReplacement = manualAmount.value as? String ?? ""
        if !amountBeforeReplacement.isEmpty {
            manualAmount.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: amountBeforeReplacement.count))
        }
        manualAmount.typeText("50")
        XCTAssertEqual(manualAmount.value as? String, "50", "The manual serving amount must be replaced, not appended to its 100 g default")
        replaceText(in: app.textFields["manual-food-calories"], with: "380")
        replaceText(in: app.textFields["manual-food-protein"], with: "13")
        replaceText(in: app.textFields["manual-food-carbohydrates"], with: "68")
        replaceText(in: app.textFields["manual-food-fat"], with: "7")
        dismissKeyboard(in: app)
        app.buttons["manual-food-save"].tap()
        XCTAssertTrue(app.navigationBars["Food"].waitForExistence(timeout: 5), "Saving manual food returns to the selected Food day")

        let foodTotal = app.staticTexts["food-calories-total"]
        XCTAssertTrue(foodTotal.waitForExistence(timeout: 5))
        XCTAssertEqual(foodTotal.label.replacingOccurrences(of: ",", with: ""), "1090", "A confirmed 450 kcal search result plus 190 kcal from a 50 g manual entry should add to the 450 kcal fixture")
        attachScreenshot(of: app, named: "Food-Nutrition-Home-Candidate")
        let foodHistory = app.buttons["food-history-link"]
        scrollToElement(foodHistory, in: app)
        XCTAssertTrue(foodHistory.waitForExistence(timeout: 5))
        foodHistory.tap()
        XCTAssertTrue(app.descendants(matching: .any)["food-history-screen"].waitForExistence(timeout: 5), "Food History navigation reaches the persistent record list")
        attachScreenshot(of: app, named: "Food-History-Candidate")
        let historyRow = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "food-history-")).firstMatch
        XCTAssertTrue(historyRow.waitForExistence(timeout: 5))
        historyRow.tap()
        XCTAssertTrue(app.navigationBars["Edit food entry"].waitForExistence(timeout: 5))
        attachScreenshot(of: app, named: "Food-History-Edit-Candidate")
        let calories = app.textFields["food-log-calories"]
        XCTAssertTrue(calories.waitForExistence(timeout: 5))
        replaceText(in: calories, with: "200")
        app.buttons["food-log-edit-save"].tap()
        XCTAssertTrue(app.navigationBars["Food History"].waitForExistence(timeout: 5))

        let editedRow = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "food-history-")).firstMatch
        XCTAssertTrue(editedRow.label.contains("200 kcal"), "The historical nutrition correction should be reflected in the saved row")
        let deletedFoodID = String(editedRow.identifier.dropFirst("food-history-".count))
        XCTAssertFalse(deletedFoodID.isEmpty, "Capture the stable food-entry identity before deletion")
        editedRow.swipeLeft()
        app.buttons["Delete"].tap()
        // Verify the delete through the durable soft-delete destination rather
        // than querying the same recycled List row immediately after mutation.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let recentlyDeleted = app.buttons["food-recently-deleted-link"]
        scrollToElement(recentlyDeleted, in: app)
        recentlyDeleted.tap()
        XCTAssertTrue(app.navigationBars["Recently Deleted"].waitForExistence(timeout: 5))
        attachScreenshot(of: app, named: "Food-Recently-Deleted-Candidate")
        let restore = app.buttons["restore-food-\(deletedFoodID)"]
        XCTAssertTrue(restore.waitForExistence(timeout: 5), "Recently Deleted should retain the same food entry")
        restore.tap()
        XCTAssertFalse(restore.exists, "Restoring removes the food record from Recently Deleted")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let history = app.buttons["food-history-link"]
        scrollToElement(history, in: app)
        history.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS[cd] %@", "QA Manual Oats")).firstMatch.waitForExistence(timeout: 5), "Restored food entry returns to Food History")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let addAgain = app.buttons["food-add-food"]
        scrollToElement(addAgain, in: app, towardTop: true)
        addAgain.tap()
        app.buttons["food-option-scan"].tap()
        XCTAssertTrue(app.navigationBars["Scan Barcode"].waitForExistence(timeout: 5))
        app.buttons["barcode-manual-fallback"].tap()
        XCTAssertTrue(app.navigationBars["Manual Entry"].waitForExistence(timeout: 5), "Barcode entry always offers a safe manual fallback")
        attachScreenshot(of: app, named: "Food-Barcode-Manual-Fallback-Candidate")
    }

    func testFoodTargetsHydrationFavoritesRecentsAndRecipeWorkflow() throws {
        let app = launchApp()
        app.buttons["Food tab"].tap()
        XCTAssertTrue(app.navigationBars["Food"].waitForExistence(timeout: 5))

        let metricPicker = app.segmentedControls["food-trend-metric"]
        scrollToElement(metricPicker, in: app)
        XCTAssertTrue(metricPicker.waitForExistence(timeout: 5))
        for metric in ["Calories", "Protein", "Carbs", "Fats"] {
            metricPicker.buttons[metric].tap()
            let chart = app.descendants(matching: .any)["food-seven-day-chart"]
            XCTAssertTrue(chart.exists, "The seven-day chart remains available for the \(metric.lowercased()) view")
            XCTAssertTrue(chart.label.contains(metric), "The selected \(metric.lowercased()) metric is reflected in the chart")
        }

        scrollToElement(app.buttons["food-targets"], in: app, towardTop: true)
        app.buttons["food-targets"].tap()
        XCTAssertTrue(app.navigationBars["Nutrition targets"].waitForExistence(timeout: 5))
        replaceText(in: app.textFields["nutrition-target-calories"], with: "2200")
        replaceText(in: app.textFields["nutrition-target-protein"], with: "160")
        dismissKeyboard(in: app)
        app.navigationBars["Nutrition targets"].buttons["Save"].tap()
        XCTAssertTrue(app.navigationBars["Food"].waitForExistence(timeout: 5), "Saving targets returns to Food before hydration controls are used")

        let foodBack = app.navigationBars["Food"].buttons.firstMatch
        XCTAssertTrue(foodBack.waitForExistence(timeout: 5))
        foodBack.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["Food page"].waitForExistence(timeout: 5))
        app.buttons["Food page"].tap()
        app.buttons["food-home-water-250"].tap()
        app.buttons["food-home-water-log"].tap()
        XCTAssertTrue(app.navigationBars["Food"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["food-water-total"].label.contains("250 mL"), "Food Home quick logging routes into the persisted hydration history")

        let waterQuickAdd = app.buttons["water-quick-500"]
        XCTAssertTrue(waterQuickAdd.waitForExistence(timeout: 5))
        waterQuickAdd.tap()
        XCTAssertTrue(app.staticTexts["food-water-total"].label.contains("750 mL"))
        let customWater = app.buttons["water-custom-entry"]
        XCTAssertTrue(customWater.waitForExistence(timeout: 5))
        customWater.tap()
        XCTAssertTrue(app.navigationBars["Add water"].waitForExistence(timeout: 5))
        let customAmount = app.textFields["water-entry-amount"]
        replaceText(in: customAmount, with: "375")
        dismissKeyboard(in: app)
        app.navigationBars["Add water"].buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["food-water-total"].label.contains("1125 mL"), "Custom hydration is added to the persisted daily total")
        let waterGoalEdit = app.buttons["water-goal-edit"]
        scrollToElement(waterGoalEdit, in: app)
        waterGoalEdit.tap()
        XCTAssertTrue(app.navigationBars["Water goal"].waitForExistence(timeout: 5))
        let waterGoalAmount = app.textFields["water-goal-amount"]
        replaceText(in: waterGoalAmount, with: "23000")
        XCTAssertFalse(app.navigationBars["Water goal"].buttons["Save"].isEnabled, "Invalid water goals cannot be saved silently")
        replaceText(in: waterGoalAmount, with: "2300")
        dismissKeyboard(in: app)
        app.navigationBars["Water goal"].buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["food-water-total"].label.contains("of 2300 mL"))

        let createRecipe = app.buttons["food-create-recipe"]
        for _ in 0..<5 where !createRecipe.exists { app.swipeUp() }
        XCTAssertTrue(createRecipe.waitForExistence(timeout: 5))
        createRecipe.tap()
        XCTAssertTrue(app.navigationBars["Recipe Builder"].waitForExistence(timeout: 5))
        replaceText(in: app.textFields["recipe-name"], with: "QA breakfast bowl")
        dismissKeyboard(in: app)
        app.buttons["recipe-add-ingredient"].tap()
        let ingredient = app.buttons["recipe-food-qa-breakfast"]
        XCTAssertTrue(ingredient.waitForExistence(timeout: 5))
        ingredient.tap()
        XCTAssertTrue(app.navigationBars["Ingredient amount"].waitForExistence(timeout: 5))
        app.navigationBars["Ingredient amount"].buttons["Add"].tap()
        XCTAssertTrue(app.buttons["recipe-save"].isEnabled)
        app.buttons["recipe-save"].tap()

        let addFoodForRecipeSearch = app.buttons["food-add-food"]
        XCTAssertTrue(app.navigationBars["Food"].waitForExistence(timeout: 5), "Saving a recipe returns to the Food log")
        scrollToElement(addFoodForRecipeSearch, in: app, towardTop: true)
        addFoodForRecipeSearch.tap()
        app.buttons["food-option-search"].tap()
        XCTAssertTrue(app.navigationBars["Search Foods"].waitForExistence(timeout: 5))
        let recipeSearch = app.searchFields.firstMatch
        recipeSearch.tap()
        recipeSearch.typeText("QA breakfast bowl")
        let recipeSearchResult = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS[cd] %@", "food-search-result-recipe-", "QA breakfast bowl")).firstMatch
        XCTAssertTrue(recipeSearchResult.waitForExistence(timeout: 5), "Saved recipes are available from food search before they are logged")
        let recipeFavorite = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "food-favorite-recipe-")).firstMatch
        recipeFavorite.tap()
        app.switches["food-favorites-filter"].tap()
        XCTAssertTrue(recipeSearchResult.exists, "Saved recipes can be favorited independently of the Recent Foods list")
        if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() }
        app.buttons["food-add-done"].tap()
        XCTAssertTrue(app.navigationBars["Food"].waitForExistence(timeout: 5))

        let caloriesTotal = app.staticTexts["food-calories-total"]
        scrollToElement(caloriesTotal, in: app, towardTop: true)
        XCTAssertTrue(caloriesTotal.waitForExistence(timeout: 5))
        let caloriesBeforeRecipe = Int(caloriesTotal.label) ?? 0
        let logRecipe = app.buttons.matching(NSPredicate(format: "label CONTAINS[cd] %@", "Log QA breakfast bowl")).firstMatch
        scrollToElement(logRecipe, in: app)
        XCTAssertTrue(logRecipe.waitForExistence(timeout: 5))
        logRecipe.tap()
        scrollToElement(caloriesTotal, in: app, towardTop: true)
        XCTAssertTrue(caloriesTotal.waitForExistence(timeout: 5))
        let expectedRecipeTotal = String(caloriesBeforeRecipe + 450)
        let recipeAdded = app.staticTexts.matching(NSPredicate(
            format: "identifier == %@ AND label == %@", "food-calories-total", expectedRecipeTotal
        )).firstMatch
        XCTAssertTrue(recipeAdded.waitForExistence(timeout: 5), "Logging one recipe serving adds its calculated 450 kcal without rewriting the source food")

        let addFood = app.buttons["food-add-food"]
        scrollToElement(addFood, in: app)
        addFood.tap()
        app.buttons["food-option-search"].tap()
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("QA breakfast")
        let result = app.buttons["food-search-result-qa-breakfast"]
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        app.buttons["food-favorite-qa-breakfast"].tap()
        app.switches["food-favorites-filter"].tap()
        XCTAssertTrue(result.exists, "Favorites are a search filter, not a fifth Add Food option")
        if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() }
        app.buttons["food-add-done"].tap()

        scrollToElement(addFood, in: app)
        addFood.tap()
        app.buttons["food-option-recent"].tap()
        XCTAssertTrue(app.navigationBars["Recent Foods"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["food-search-result-qa-breakfast"].waitForExistence(timeout: 5))
        attachScreenshot(of: app, named: "Food-Recipe-Hydration-Targets-Candidate")
        app.navigationBars["Recent Foods"].buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Food"].waitForExistence(timeout: 5))
        let recipeRow = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "log-recipe-")).firstMatch
        scrollToElement(recipeRow, in: app)
        XCTAssertTrue(recipeRow.waitForExistence(timeout: 5))
        recipeRow.press(forDuration: 1.2)
        let deleteRecipe = app.buttons["Delete recipe"]
        XCTAssertTrue(deleteRecipe.waitForExistence(timeout: 5))
        deleteRecipe.tap()
        let recentlyDeleted = app.buttons["food-recently-deleted-link"]
        scrollToElement(recentlyDeleted, in: app)
        recentlyDeleted.tap()
        XCTAssertTrue(app.navigationBars["Recently Deleted"].waitForExistence(timeout: 5))
        let restoreRecipe = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "restore-recipe-")).firstMatch
        XCTAssertTrue(restoreRecipe.waitForExistence(timeout: 5), "Saved recipes remain recoverable after deletion")
        restoreRecipe.tap()
        XCTAssertFalse(restoreRecipe.exists)
    }

    func testFoodCopyAddAndReplaceUsesSelectedDateAndMatchingMeal() throws {
        let app = launchApp()
        app.buttons["Food tab"].tap()
        XCTAssertTrue(app.navigationBars["Food"].waitForExistence(timeout: 5))
        let foodDate = app.staticTexts["food-date-key"]
        XCTAssertTrue(foodDate.waitForExistence(timeout: 5))
        let today = foodDate.label
        app.buttons["food-day-previous"].tap()
        let updatedFoodDate = app.staticTexts.matching(NSPredicate(
            format: "identifier == %@ AND label != %@", "food-date-key", today
        )).firstMatch
        XCTAssertTrue(updatedFoodDate.waitForExistence(timeout: 5), "Previous-day control selects the prior date before logging")

        let addMeal = app.buttons["Add meal"]
        scrollToElement(addMeal, in: app)
        addMeal.tap()
        let copyMeal = app.staticTexts["Meal 4"]
        scrollToElement(copyMeal, in: app)
        copyMeal.tap()
        let addToMeal = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "add-to-meal-")).firstMatch
        XCTAssertTrue(addToMeal.waitForExistence(timeout: 5))
        addToMeal.tap()

        func logFixtureFoodIntoOpenMeal() {
            XCTAssertTrue(app.navigationBars["Search Foods"].waitForExistence(timeout: 5))
            let search = app.searchFields.firstMatch
            XCTAssertTrue(search.waitForExistence(timeout: 5))
            search.tap()
            search.typeText("QA breakfast")
            let result = app.buttons["food-search-result-qa-breakfast"]
            XCTAssertTrue(result.waitForExistence(timeout: 5))
            result.tap()
            XCTAssertTrue(app.buttons["food-confirm-log"].waitForExistence(timeout: 5))
            app.buttons["food-confirm-log"].tap()
            XCTAssertTrue(app.navigationBars["Search Foods"].waitForExistence(timeout: 5), "Confirmed items leave the picker available for additional entries")
            if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() }
            app.buttons["food-add-done"].tap()
            XCTAssertTrue(app.navigationBars["Food"].waitForExistence(timeout: 5), "Done closes Food search and returns to the selected log date")
        }
        logFixtureFoodIntoOpenMeal()
        XCTAssertNotEqual(foodDate.label, today, "Food added to the prior selected day must remain attached to that date")

        let nextFoodDay = app.buttons["food-day-next"]
        scrollToElement(nextFoodDay, in: app, towardTop: true)
        nextFoodDay.tap()
        let returnedToToday = app.staticTexts.matching(NSPredicate(
            format: "identifier == %@ AND label == %@", "food-date-key", today
        )).firstMatch
        XCTAssertTrue(returnedToToday.waitForExistence(timeout: 5), "The date controls remain usable after returning from the food-entry sheet")
        XCTAssertEqual(app.staticTexts["food-calories-total"].label, "450", "The source day's entry is saved separately from today's food log")
        let addToDestinationMeal = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "add-to-meal-")).firstMatch
        if !addToDestinationMeal.exists { copyMeal.tap() }
        XCTAssertTrue(addToDestinationMeal.waitForExistence(timeout: 5))
        addToDestinationMeal.tap()
        logFixtureFoodIntoOpenMeal()
        XCTAssertEqual(app.staticTexts["food-calories-total"].label, "900", "The destination has an unrelated Meal 1 entry and a matching Meal 4 entry")
        let copy = app.buttons["food-copy-meals"]
        scrollToElement(copy, in: app)
        copy.tap()
        XCTAssertTrue(app.navigationBars["Copy meals"].waitForExistence(timeout: 5))
        app.buttons["copy-food-add"].tap()
        app.swipeUp()
        let copyStatus = app.staticTexts["copy-food-status"]
        XCTAssertTrue(copyStatus.waitForExistence(timeout: 5))
        XCTAssertTrue(copyStatus.label.contains("Copied 1 food entries"))
        XCTAssertEqual(copyStatus.label, "Copied 1 food entries to \(today).")
        app.buttons["copy-food-replace"].tap()
        XCTAssertEqual(app.staticTexts["copy-food-status"].label, "Copied 1 food entries to \(today).")
        attachScreenshot(of: app, named: "Food-Copy-Add-Replace-Candidate")
        app.navigationBars["Copy meals"].buttons["Done"].tap()
        let destinationCalories = app.staticTexts["food-calories-total"]
        scrollToElement(destinationCalories, in: app, towardTop: true)
        XCTAssertEqual(destinationCalories.label, "900", "Replace swaps matching Meal 4 entries while preserving the unrelated Meal 1 log")
    }

    func testWaterHistoryCanBeDeletedAndRestoredThroughRecentlyDeleted() throws {
        let app = launchApp()
        app.buttons["Food page"].tap()
        app.buttons["food-home-water-log"].tap()
        XCTAssertTrue(app.navigationBars["Food"].waitForExistence(timeout: 5))
        let customEntry = app.buttons["water-custom-entry"]
        scrollToElement(customEntry, in: app)
        customEntry.tap()
        XCTAssertTrue(app.navigationBars["Add water"].waitForExistence(timeout: 5))
        replaceText(in: app.textFields["water-entry-amount"], with: "375")
        dismissKeyboard(in: app)
        app.navigationBars["Add water"].buttons["Save"].tap()
        XCTAssertTrue(app.navigationBars["Food"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["food-water-total"].label.contains("375 mL"), "Custom hydration amount is persisted to the selected log date")
        let quickAdd = app.buttons["water-quick-500"]
        scrollToElement(quickAdd, in: app)
        quickAdd.tap()
        XCTAssertTrue(app.staticTexts["food-water-total"].label.contains("875 mL"))
        let waterEntry = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "water-history-")).firstMatch
        scrollToElement(waterEntry, in: app)
        XCTAssertTrue(waterEntry.waitForExistence(timeout: 5))
        waterEntry.tap()
        XCTAssertTrue(app.navigationBars["Edit water"].waitForExistence(timeout: 5))
        app.buttons["Delete water entry"].tap()
        XCTAssertTrue(app.navigationBars["Food"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["food-water-total"].label.contains("375 mL"), "Deleting a history entry removes only the selected amount")

        let recentlyDeleted = app.buttons["food-recently-deleted-link"]
        scrollToElement(recentlyDeleted, in: app)
        recentlyDeleted.tap()
        XCTAssertTrue(app.navigationBars["Recently Deleted"].waitForExistence(timeout: 5))
        let restore = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "restore-water-")).firstMatch
        XCTAssertTrue(restore.waitForExistence(timeout: 5), "Deleted water entries remain recoverable for 30 days")
        restore.tap()
        XCTAssertFalse(restore.exists, "Restored water entry leaves Recently Deleted")
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
        // Reacquire the visible list on each pass: navigation, sheets, and
        // List virtualization can replace its accessibility element while a
        // workflow is running.
        let pinnedFooter = app.buttons["finish-workout"]
        for _ in 0..<10 {
            if element.exists {
                let aboveFooter = !pinnedFooter.exists || element.frame.maxY < pinnedFooter.frame.minY - 8
                if element.isHittable && aboveFooter { return }
            }
            let lists = app.collectionViews
            let list = lists.element(boundBy: max(0, lists.count - 1))
            // Lazy List rows may not enter the accessibility tree until they are
            // scrolled into view; avoid reading a missing element's frame first.
            if lists.count > 0 && list.exists {
                if towardTop { list.swipeDown() } else { list.swipeUp() }
            } else {
                if towardTop { app.swipeDown() } else { app.swipeUp() }
            }
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

    func testCheckInSleepNapWeightAndSupplementWorkflow() throws {
        let app = launchApp()
        app.buttons["Sleep tab"].tap()

        let sessionType = app.segmentedControls["sleep-session-type"]
        XCTAssertTrue(sessionType.waitForExistence(timeout: 5))
        sessionType.buttons["Nap"].tap()
        let saveSleep = app.buttons["sleep-save"]
        XCTAssertTrue(saveSleep.waitForExistence(timeout: 5))
        saveSleep.tap()
        XCTAssertTrue(app.staticTexts["Nap"].waitForExistence(timeout: 5), "A nap is saved as a separate check-in")
        let sleepRow = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "sleep-edit-")).firstMatch
        XCTAssertTrue(sleepRow.waitForExistence(timeout: 5))
        let sleepID = String(sleepRow.identifier.dropFirst("sleep-edit-".count))
        app.buttons["sleep-delete-\(sleepID)"].tap()
        let restoreSleep = app.buttons["restore-sleep-\(sleepID)"]
        for _ in 0..<8 {
            if restoreSleep.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(restoreSleep.waitForExistence(timeout: 5), "A deleted sleep record is listed for recovery")
        XCTAssertTrue(restoreSleep.isHittable, "The restore action should be reachable in the Recently Deleted section")
        restoreSleep.tap()
        let restoredSleep = app.buttons["sleep-edit-\(sleepID)"]
        scrollToElement(restoredSleep, in: app, towardTop: true)
        XCTAssertTrue(restoredSleep.waitForExistence(timeout: 5), "Restoring returns the sleep record to the active list")
        let deleteRestoredSleep = app.buttons["sleep-delete-\(sleepID)"]
        scrollToElement(deleteRestoredSleep, in: app)
        XCTAssertTrue(deleteRestoredSleep.isHittable, "The restored sleep record can be deleted again")
        deleteRestoredSleep.tap()
        let permanentlyDeleteSleep = app.buttons["permanently-delete-sleep-\(sleepID)"]
        for _ in 0..<12 {
            if permanentlyDeleteSleep.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(permanentlyDeleteSleep.waitForExistence(timeout: 5), "Recently Deleted offers explicit permanent removal")
        permanentlyDeleteSleep.tap()
        app.buttons["Delete Permanently"].tap()
        XCTAssertFalse(app.buttons["restore-sleep-\(sleepID)"].exists, "Permanent deletion removes the record from recovery")
        scrollToElement(restoredSleep, in: app, towardTop: true)
        XCTAssertFalse(restoredSleep.exists, "Permanent deletion removes the record from active history too")

        let weightField = app.textFields["checkin-weight-value"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 5))
        weightField.tap()
        let oldWeight = weightField.value as? String ?? ""
        if !oldWeight.isEmpty {
            weightField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: oldWeight.count))
        }
        weightField.typeText("79.5")
        app.buttons["weight-save"].tap()
        let replaceWeight = app.buttons["Replace weight"]
        if replaceWeight.waitForExistence(timeout: 2) { replaceWeight.tap() }
        let currentWeight = app.descendants(matching: .any)["weight-current-value"]
        XCTAssertTrue(currentWeight.waitForExistence(timeout: 5), "The selected weight is saved and displayed")
        XCTAssertTrue(currentWeight.label.contains("79.5"), "Historical weight editing stores the entered measurement")

        app.buttons["supplement-add"].tap()
        let supplementName = app.textFields["supplement-name"]
        XCTAssertTrue(supplementName.waitForExistence(timeout: 5))
        supplementName.tap()
        supplementName.typeText("QA Vitamin D")
        app.buttons["supplement-editor-save"].tap()
        XCTAssertTrue(app.staticTexts["QA Vitamin D"].waitForExistence(timeout: 5))

        let dueVitaminD = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Mark QA Vitamin D taken")).firstMatch
        XCTAssertTrue(dueVitaminD.waitForExistence(timeout: 5), "A newly added daily supplement has a direct Taken action")
        dueVitaminD.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Undo QA Vitamin D")).firstMatch.waitForExistence(timeout: 5))
        attachScreenshot(of: app, named: "Sleep-Weight-Supplements-Candidate")
    }

    func testCategoryHistoryNavigationAndEditableCheckInRecords() throws {
        let app = launchApp()
        app.buttons["Sleep tab"].tap()

        let sessionType = app.segmentedControls["sleep-session-type"]
        XCTAssertTrue(sessionType.waitForExistence(timeout: 5))
        sessionType.buttons["Nap"].tap()
        app.buttons["sleep-save"].tap()
        let sleepRow = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "sleep-edit-")).firstMatch
        XCTAssertTrue(sleepRow.waitForExistence(timeout: 5))
        let sleepID = String(sleepRow.identifier.dropFirst("sleep-edit-".count))

        let weightField = app.textFields["checkin-weight-value"]
        scrollToElement(weightField, in: app)
        XCTAssertTrue(weightField.waitForExistence(timeout: 5))
        replaceText(in: weightField, with: "78")
        dismissKeyboard(in: app)
        app.buttons["weight-save"].tap()
        let replaceWeight = app.buttons["Replace weight"]
        if replaceWeight.waitForExistence(timeout: 2) { replaceWeight.tap() }
        let savedWeight = app.descendants(matching: .any)["weight-current-value"]
        XCTAssertTrue(savedWeight.waitForExistence(timeout: 5))
        XCTAssertTrue(savedWeight.label.contains("78"), "The daily check-in fixture weight is corrected before history inspection")

        let addSupplement = app.buttons["supplement-add"]
        scrollToElement(addSupplement, in: app)
        addSupplement.tap()
        let name = app.textFields["supplement-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("QA History Supplement")
        app.buttons["supplement-editor-save"].tap()
        let takeSupplement = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Mark QA History Supplement taken")).firstMatch
        XCTAssertTrue(takeSupplement.waitForExistence(timeout: 5))
        takeSupplement.tap()

        // Check-ins is a pushed screen; return to Home before using the fixed dock.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.buttons["home-widget-kcal"].waitForExistence(timeout: 5))
        app.buttons["History tab"].tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
        let categoryIDs = [
            "history-category-training", "history-category-nutrition", "history-category-weight",
            "history-category-sleep", "history-category-supplements", "history-category-habits"
        ]
        for identifier in categoryIDs {
            scrollToElement(app.buttons[identifier], in: app)
            XCTAssertTrue(app.buttons[identifier].waitForExistence(timeout: 5), "Missing History category \(identifier)")
        }
        attachScreenshot(of: app, named: "History-Categories-Candidate")

        app.buttons["history-category-sleep"].tap()
        XCTAssertTrue(app.navigationBars["Sleep History"].waitForExistence(timeout: 5))
        let sleepHistoryRow = app.buttons["history-sleep-\(sleepID)"]
        XCTAssertTrue(sleepHistoryRow.waitForExistence(timeout: 5), "Sleep History keeps individual nap records")
        attachScreenshot(of: app, named: "Sleep-History-Candidate")
        sleepHistoryRow.tap()
        XCTAssertTrue(app.buttons["sleep-edit-\(sleepID)"].waitForExistence(timeout: 5), "A history row opens its exact editable check-in record")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["history-category-weight"].tap()
        XCTAssertTrue(app.navigationBars["Weight History"].waitForExistence(timeout: 5))
        let weightHistoryRow = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "history-weight-")).firstMatch
        XCTAssertTrue(weightHistoryRow.waitForExistence(timeout: 5), "Weight History lists the saved daily measurement")
        attachScreenshot(of: app, named: "Weight-History-Candidate")
        weightHistoryRow.tap()
        let currentWeight = app.descendants(matching: .any)["weight-current-value"]
        XCTAssertTrue(currentWeight.waitForExistence(timeout: 5))
        XCTAssertTrue(currentWeight.label.contains("78"), "Weight history navigates to the selected date's editable value")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["history-category-supplements"].tap()
        XCTAssertTrue(app.navigationBars["Supplements History"].waitForExistence(timeout: 5))
        let supplementHistoryRow = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "history-supplement-")).firstMatch
        XCTAssertTrue(supplementHistoryRow.waitForExistence(timeout: 5), "Supplement History lists dated dose records")
        attachScreenshot(of: app, named: "Supplement-History-Candidate")
        let doseID = String(supplementHistoryRow.identifier.dropFirst("history-supplement-".count))
        supplementHistoryRow.swipeLeft()
        app.buttons["Delete"].tap()
        let restoreDose = app.buttons["restore-history-supplement-dose-\(doseID)"]
        scrollToElement(restoreDose, in: app)
        XCTAssertTrue(restoreDose.waitForExistence(timeout: 5), "Deleted supplement doses are retained for recovery")
        restoreDose.tap()
        XCTAssertTrue(app.buttons["history-supplement-\(doseID)"].waitForExistence(timeout: 5), "Restoring a dose returns it to dated supplement history")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["history-category-habits"].tap()
        XCTAssertTrue(app.navigationBars["Habits History"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "history-habit-day-")).firstMatch.waitForExistence(timeout: 5), "Habits History derives dated completion records")
        attachScreenshot(of: app, named: "Habits-History-Candidate")
    }

    func testProgressHomeMetricsAndNumberedActivityDayNavigation() throws {
        let app = launchApp(strengthHistory: true)
        app.buttons["Progress & History page"].tap()

        let metricPicker = app.segmentedControls["progress-metric-picker"]
        XCTAssertTrue(metricPicker.waitForExistence(timeout: 5), "Progress Home exposes its five approved metrics")
        for metric in ["Weight", "Strength", "Sleep", "Calories", "Protein"] {
            let button = metricPicker.buttons[metric]
            XCTAssertTrue(button.exists, "Missing \(metric) metric")
            button.tap()
            XCTAssertTrue(button.isSelected, "Selecting \(metric) updates the chart tab")
            if metric == "Strength" {
                let exercisePicker = app.descendants(matching: .any)["progress-strength-exercise"].firstMatch
                XCTAssertTrue(exercisePicker.waitForExistence(timeout: 5), "Multiple completed exercises expose a selection control")
                exercisePicker.tap()
                let rowOption = app.buttons["Seated Row"]
                XCTAssertTrue(rowOption.waitForExistence(timeout: 5), "The exercise menu includes each completed exercise")
                rowOption.tap()
                XCTAssertTrue(exercisePicker.label.contains("Seated Row") || (exercisePicker.value as? String ?? "").contains("Seated Row"), "The selected exercise controls the strength series")
            }
        }

        let activityDay = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "activity-day-")).firstMatch
        XCTAssertTrue(activityDay.waitForExistence(timeout: 5), "The numbered activity heatmap should be tappable")
        let dateKey = String(activityDay.identifier.dropFirst("activity-day-".count))
        activityDay.tap()
        let selectedHistoryDate = app.staticTexts["history-selected-day-date"]
        XCTAssertTrue(selectedHistoryDate.waitForExistence(timeout: 5), "Heatmap selection opens and scrolls to that day in History")
        XCTAssertEqual(selectedHistoryDate.label, dateKey)
        attachScreenshot(of: app, named: "Progress-Home-Candidate")
    }

    private func launchApp(themeID: String? = nil, progressionHistory: Bool = false, trainingSplitCount: Int? = nil, trainingPrograms: Bool = false, singleExercise: Bool = false, strengthHistory: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        if progressionHistory { app.launchArguments.append("--qa-progression-history") }
        if trainingSplitCount == 8 { app.launchArguments.append("--qa-training-split-eight") }
        if trainingPrograms { app.launchArguments.append("--qa-training-programs") }
        if singleExercise { app.launchArguments.append("--qa-single-exercise") }
        if strengthHistory { app.launchArguments.append("--qa-strength-history") }
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
