import XCTest

final class DailyHomeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDailyHomeLayoutAndCaptureAllHomePages() throws {
        let app = launchApp()
        let calories = app.buttons["home-widget-kcal"]
        let nextWorkout = app.buttons["home-widget-next"]
        let habits = app.buttons["home-widget-streak"]
        let checkIn = app.buttons["home-widget-vitals"]

        XCTAssertTrue(calories.waitForExistence(timeout: 20), "Daily nutrition widget did not appear")
        XCTAssertTrue(nextWorkout.exists)
        XCTAssertTrue(habits.exists)
        XCTAssertTrue(checkIn.exists)
        XCTAssertTrue(calories.label.contains("Calories & Protein Remaining"))
        XCTAssertTrue(nextWorkout.label.contains("Workout 1 of 1"))

        XCTAssertEqual(calories.frame.width, nextWorkout.frame.width, accuracy: 2)
        XCTAssertGreaterThan(calories.frame.height, nextWorkout.frame.height)
        XCTAssertEqual(habits.frame.width, checkIn.frame.width, accuracy: 2)
        XCTAssertEqual(habits.frame.width, habits.frame.height, accuracy: 2, "Small widgets must occupy square cells")
        XCTAssertEqual(calories.frame.width, calories.frame.height, accuracy: 2, "Large widgets must be square")
        XCTAssertEqual(nextWorkout.frame.height, habits.frame.height, accuracy: 2, "Medium widget must be two cells wide and one cell tall")
        XCTAssertEqual(nextWorkout.frame.width, habits.frame.width * 2 + 9, accuracy: 3, "Medium width must span two cells and one grid gap")
        XCTAssertEqual(habits.frame.minY, checkIn.frame.minY, accuracy: 2)
        XCTAssertLessThanOrEqual(calories.frame.maxY, nextWorkout.frame.minY)
        XCTAssertLessThanOrEqual(nextWorkout.frame.maxY, habits.frame.minY)
        XCTAssertLessThan(habits.frame.maxY, app.buttons["Training tab"].frame.minY)
        XCTAssertTrue(app.buttons["Training tab"].exists)
        XCTAssertTrue(app.buttons["Food tab"].exists)
        XCTAssertTrue(app.buttons["History tab"].exists)
        XCTAssertTrue(app.buttons["Sleep tab"].exists)
        XCTAssertTrue(app.buttons["Settings tab"].exists)

        let pageNames = ["Daily page", "Training page", "Food page", "Progress & History page"]
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label IN %@", pageNames)).count, 4)

        let dockFrame = app.buttons["Training tab"].frame
        let measurement = "Default Daily widget frames (points): large=\(calories.frame), medium=\(nextWorkout.frame), small-left=\(habits.frame), small-right=\(checkIn.frame), dock=\(dockFrame)"
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

    private func launchApp(themeID: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
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
