import XCTest
import StoreKitTest

final class SubscriptionScreenshotTests: XCTestCase {
    @MainActor private func openPaywall(_ app: XCUIApplication) {
        app.launch()
        let demo = app.buttons["Explore with demo plans"]
        if demo.waitForExistence(timeout: 3) { demo.tap() }
        let settings = app.buttons["Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 15))
        settings.tap()
        let pro = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "PlanBridge Pro")).firstMatch
        let explore = app.buttons["Explore PlanBridge Pro"]
        if explore.waitForExistence(timeout: 3) { explore.tap() }
        else { XCTAssertTrue(pro.waitForExistence(timeout: 10)); pro.tap() }
    }
    @MainActor func testPurchasesRestoreAndCapture() throws {
        let session = try SKTestSession(configurationFileNamed: "PlanBridge")
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
        defer { session.clearTransactions() }
        let app = XCUIApplication()
        for productID in ["com.planbridge.ai.pro.monthly", "com.planbridge.ai.pro.annual"] {
            session.clearTransactions()
            app.terminate()
            openPaywall(app)
            let purchase = app.buttons[productID]
            XCTAssertTrue(purchase.waitForExistence(timeout: 20))
            XCTAssertTrue(purchase.isEnabled)
            if productID.hasSuffix("monthly") {
                app.swipeUp()
                let screenshot = XCTAttachment(screenshot: app.screenshot())
                screenshot.name = "subscription-review-priced"
                screenshot.lifetime = .keepAlways
                add(screenshot)
            }
            if !purchase.isHittable { app.swipeUp() }
            purchase.tap()
            XCTAssertTrue(app.staticTexts["Your Pro subscription is active"].waitForExistence(timeout: 20))
            XCTAssertTrue(session.allTransactions().contains { $0.productIdentifier == productID })
            // Restart to recover the entitlement from StoreKit rather than cached UI state.
            app.terminate()
            openPaywall(app)
            XCTAssertTrue(app.staticTexts["Your Pro subscription is active"].waitForExistence(timeout: 20))
            app.swipeUp()
            app.buttons["Restore purchases"].tap()
            XCTAssertTrue(app.staticTexts["Purchases restored."].waitForExistence(timeout: 20))
        }
        session.clearTransactions()
        app.terminate()
        openPaywall(app)
        XCTAssertTrue(app.buttons["com.planbridge.ai.pro.monthly"].waitForExistence(timeout: 20))
        app.swipeUp()
        app.buttons["Restore purchases"].tap()
        XCTAssertTrue(app.staticTexts["No active PlanBridge Pro subscription was found."].waitForExistence(timeout: 20))
        XCTAssertFalse(app.staticTexts["Your Pro subscription is active"].exists)
    }
}
