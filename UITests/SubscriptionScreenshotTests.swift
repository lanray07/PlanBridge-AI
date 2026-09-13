import XCTest

final class SubscriptionScreenshotTests: XCTestCase {
    @MainActor func testCapturePaywall() throws {
        let app = XCUIApplication()
        app.launch()
        let demo = app.buttons["Explore with demo plans"]
        if demo.waitForExistence(timeout: 10) { demo.tap() }
        let settings = app.buttons["Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 15))
        settings.tap()
        let pro = app.buttons["Explore PlanBridge Pro"]
        XCTAssertTrue(pro.waitForExistence(timeout: 10))
        pro.tap()
        XCTAssertTrue(app.staticTexts["Unlimited checks of supplied trip bookings"].waitForExistence(timeout: 10))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "subscription-review"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.swipeUp()
        let details = XCTAttachment(screenshot: app.screenshot())
        details.name = "subscription-review-details"
        details.lifetime = .keepAlways
        add(details)
    }
}
