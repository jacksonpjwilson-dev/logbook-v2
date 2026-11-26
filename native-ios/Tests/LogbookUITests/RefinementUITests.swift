import XCTest

final class RefinementUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testEveryThemeKeepsSharedDailyWidgetsAndSelectionPersists() throws {
        let titles = ["Default", "Modern Clean", "Sunset Vibes", "Ocean Breeze", "Monochrome Pro", "Soft Pastel", "Premium Glass", "Mountain Dawn", "Coastal Minimal", "Midnight Luxe", "Cherry Blossom", "Arctic Mountain", "Slate Glass", "Midnight Glass", "Monochrome", "Neon Gradient", "Teal & Coral"]
        let ids = ["default", "modern-clean", "sunset-vibes", "ocean-breeze", "monochrome-pro", "soft-pastel", "premium-glass", "mountain-dawn", "coastal-minimal", "midnight-luxe", "cherry-blossom", "arctic-mountain", "slate-glass", "midnight-glass", "monochrome", "neon-gradient", "teal-coral"]
        for empty in [false, true] {
            let app = launch(empty: empty)
            for (index, id) in ids.enumerated() {
                app.buttons["Settings tab"].tap()
                app.buttons["settings-theme"].tap()
                let preview = app.buttons["theme-preview-\(id)"]
                for _ in 0..<12 {
                    if preview.exists && preview.isHittable { break }
                    app.scrollViews.firstMatch.swipeUp()
                }
                XCTAssertTrue(preview.waitForExistence(timeout: 3), id)
                XCTAssertTrue(preview.isHittable, id)
                preview.tap()
                XCTAssertTrue(app.staticTexts[titles[index]].waitForExistence(timeout: 3), "Selected theme must match the preview")
                app.terminate()
                app.launch()
                XCTAssertTrue(app.buttons["home-widget-kcal"].waitForExistence(timeout: 15), id)
                XCTAssertTrue(app.otherElements["home-widget-streak"].exists, id)
                XCTAssertTrue(app.otherElements["home-widget-vitals"].exists, id)
                for page in ["Daily", "Training", "Food", "Progress & History"] {
                    app.buttons["\(page) page"].tap()
                    let screenshot = XCTAttachment(screenshot: app.screenshot())
                    screenshot.name = "\(id)-\(empty ? "empty" : "populated")-\(page)"
                    screenshot.lifetime = .keepAlways
                    add(screenshot)
                }
                app.buttons["Daily page"].tap()
                app.buttons["Settings tab"].tap()
                XCTAssertTrue(app.staticTexts[titles[index]].waitForExistence(timeout: 3), "Theme survives relaunch")
                app.navigationBars["Settings"].buttons.firstMatch.tap()
            }
        }
    }

    func testFreshSetupResumesAndOpensDashboard() throws {
        let app = launch(empty: true, setup: true)
        XCTAssertTrue(app.navigationBars["Welcome"].waitForExistence(timeout: 8))
        app.buttons["setup-continue"].tap()
        XCTAssertTrue(app.staticTexts["Accounts are coming later"].exists)
        app.buttons["setup-continue"].tap()
        app.textFields["Preferred name"].tap()
        app.textFields["Preferred name"].typeText("Synthetic athlete")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.navigationBars["About you"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.textFields["Preferred name"].value as? String, "Synthetic athlete")
        for _ in 0..<6 { app.buttons["setup-continue"].tap() }
        XCTAssertTrue(app.navigationBars["Ready to begin"].waitForExistence(timeout: 3))
        app.buttons["setup-continue"].tap()
        XCTAssertTrue(app.buttons["home-widget-kcal"].waitForExistence(timeout: 8))
    }

    func testLaunchVideoCompletesAndRevealsHome() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--qa-launch-video", "--qa-empty-home", "--qa-storage-id=\(UUID().uuidString)"]
        app.launch()
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Launch-video"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        XCTAssertTrue(app.buttons["home-widget-kcal"].waitForExistence(timeout: 12), "Playback completion or its timeout must reveal Home")
    }

    private func launch(empty: Bool, setup: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--qa-storage-id=\(UUID().uuidString)"]
        if empty { app.launchArguments.append("--qa-empty-home") }
        if setup { app.launchArguments.append("--qa-show-setup") }
        app.launch()
        return app
    }
}
