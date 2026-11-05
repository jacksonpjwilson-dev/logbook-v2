import XCTest

final class DailyHomeUITests: XCTestCase {
    private let approvedThemeIDs = [
        "modern-clean", "sunset-vibes", "ocean-breeze", "monochrome-pro",
        "soft-pastel", "premium-glass", "mountain-dawn", "coastal-minimal",
        "midnight-luxe", "cherry-blossom", "arctic-mountain", "slate-glass",
        "midnight-glass", "monochrome", "neon-gradient", "teal-coral"
    ]

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
        XCTAssertLessThan(calories.frame.height, nextWorkout.frame.height)
        XCTAssertEqual(habits.frame.width, checkIn.frame.width, accuracy: 2)
        XCTAssertEqual(habits.frame.minY, checkIn.frame.minY, accuracy: 2)
        XCTAssertLessThanOrEqual(calories.frame.maxY, nextWorkout.frame.minY)
        XCTAssertLessThanOrEqual(nextWorkout.frame.maxY, habits.frame.minY)
        XCTAssertLessThan(habits.frame.maxY, app.buttons["Training tab"].frame.minY)
        XCTAssertTrue(app.buttons["Training tab"].exists)
        XCTAssertTrue(app.buttons["Food tab"].exists)
        XCTAssertTrue(app.buttons["History tab"].exists)
        XCTAssertTrue(app.buttons["Sleep tab"].exists)
        XCTAssertTrue(app.buttons["Settings tab"].exists)

        attachScreenshot(of: app, named: "Home-Daily-Premium-Glass")
        capturePage("Training", in: app)
        capturePage("Food", in: app)
        capturePage("Progress & History", in: app)

        let dailyPage = app.buttons["Daily page"]
        XCTAssertTrue(dailyPage.waitForExistence(timeout: 5))
        dailyPage.tap()
        app.buttons["home-widget-kcal"].tap()
        XCTAssertTrue(app.navigationBars["Food"].waitForExistence(timeout: 5), "Calories widget should open Food")
    }

    func testCaptureProtectedThemeCandidates() throws {
        for themeID in approvedThemeIDs {
            let app = launchApp(themeID: themeID)
            XCTAssertTrue(app.buttons["home-widget-kcal"].waitForExistence(timeout: 20), "Home failed to render theme \(themeID)")
            attachScreenshot(of: app, named: "Theme-Candidate-\(themeID)")
            app.terminate()
        }
    }

    private func launchApp(themeID: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        if let themeID { app.launchArguments.append("--qa-theme=\(themeID)") }
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
