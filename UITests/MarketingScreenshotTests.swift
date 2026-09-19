import XCTest

final class MarketingScreenshotTests: XCTestCase {
    @MainActor func testEnglishKeywordScreenshots() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_GB"]
        app.launch()
        let demo = app.buttons["Explore with demo plans"]
        if demo.waitForExistence(timeout: 3) { demo.tap() }
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 15))
        app.buttons["Settings"].tap()
        let demoSwitch = app.switches["Explore demo plans"]
        XCTAssertTrue(demoSwitch.waitForExistence(timeout: 5))
        if demoSwitch.value as? String != "1" { demoSwitch.tap() }
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Your daily calendar planner"].waitForExistence(timeout: 5))
        capture(app, "01-calendar-planner")

        let conflict = app.buttons["Review conflict"]
        if !conflict.isHittable { app.swipeUp() }
        XCTAssertTrue(conflict.waitForExistence(timeout: 5))
        conflict.tap()
        XCTAssertTrue(app.navigationBars["Booking conflicts"].waitForExistence(timeout: 5))
        capture(app, "02-booking-conflicts")

        // iPad uses a top tab control rather than an XCUIElementTypeTabBar.
        app.buttons.matching(NSPredicate(format: "label == %@", "Timeline")).firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Calendar timeline"].waitForExistence(timeout: 5))
        capture(app, "03-calendar-timeline")
        app.buttons.matching(NSPredicate(format: "label == %@", "My trips")).firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Trip organizer"].waitForExistence(timeout: 5))
        capture(app, "04-trip-organizer")
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "en-GB-" + name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
