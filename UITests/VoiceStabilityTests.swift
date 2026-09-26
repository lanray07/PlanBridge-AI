import XCTest

final class VoiceStabilityTests: XCTestCase {
    @MainActor func testMicrophoneStartDoesNotCrashOnIPad() {
        continueAfterFailure = false
        let app = XCUIApplication()

        addUIInterruptionMonitor(withDescription: "Speech and microphone permissions") { alert in
            for title in ["Allow", "OK", "Continue"] where alert.buttons[title].exists {
                alert.buttons[title].tap()
                return true
            }
            return false
        }

        app.launch()
        let demo = app.buttons["Explore with demo plans"]
        if demo.waitForExistence(timeout: 5) { demo.tap() }

        let ask = app.buttons.matching(NSPredicate(format: "label == %@", "Ask")).firstMatch
        XCTAssertTrue(ask.waitForExistence(timeout: 15))
        ask.tap()

        let microphone = app.buttons["Ask using on-device voice"]
        XCTAssertTrue(microphone.waitForExistence(timeout: 5))
        microphone.tap()

        // Interruption monitors are invoked by another interaction with the app.
        app.tap()
        let deadline = Date().addingTimeInterval(8)
        while Date() < deadline, app.state == .runningForeground {
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        XCTAssertEqual(app.state, .runningForeground, "Tapping the microphone must not terminate the app")
        XCTAssertTrue(
            app.buttons["Stop listening"].exists ||
            app.buttons["Ask using on-device voice"].exists,
            "The Ask screen should remain interactive after microphone startup"
        )
    }
}
