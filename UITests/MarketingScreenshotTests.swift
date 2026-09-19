import XCTest

final class MarketingScreenshotTests: XCTestCase {
    @MainActor func testEnglishKeywordScreenshots() {
        captureScreens(language: "en", region: "en_GB", labels: ["Explore with demo plans", "Settings", "Explore demo plans", "Done", "Your daily calendar planner", "Review conflict", "Booking conflicts", "Timeline", "Calendar timeline", "My trips", "Trip organizer"])
    }
    @MainActor func testFrenchKeywordScreenshots() {
        captureScreens(language: "fr", region: "fr_FR", labels: ["Découvrir avec des exemples", "Réglages", "Explorer les exemples", "Terminé", "Votre calendrier au quotidien", "Examiner le conflit", "Conflits de réservation", "Chronologie", "Chronologie du calendrier", "Mes voyages", "Organisation des voyages"])
    }
    @MainActor func testSpanishKeywordScreenshots() {
        captureScreens(language: "es", region: "es_ES", labels: ["Explorar con planes de ejemplo", "Ajustes", "Explorar planes de ejemplo", "Listo", "Tu calendario diario", "Revisar conflicto", "Conflictos entre reservas", "Cronología", "Cronología del calendario", "Mis viajes", "Organizador de viajes"])
    }
    @MainActor func testGermanKeywordScreenshots() {
        captureScreens(language: "de", region: "de_DE", labels: ["Mit Beispielplänen erkunden", "Einstellungen", "Beispielpläne ansehen", "Fertig", "Dein täglicher Kalenderplaner", "Konflikt prüfen", "Buchungskonflikte", "Zeitübersicht", "Kalenderübersicht", "Meine Reisen", "Reiseplaner"])
    }
    @MainActor private func captureScreens(language: String, region: String, labels: [String]) {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(\(language))", "-AppleLocale", region]
        app.launch()
        let demo = app.buttons[labels[0]]
        if demo.waitForExistence(timeout: 3) { demo.tap() }
        XCTAssertTrue(app.buttons[labels[1]].waitForExistence(timeout: 15))
        app.buttons[labels[1]].tap()
        let demoSwitch = app.switches[labels[2]]
        XCTAssertTrue(demoSwitch.waitForExistence(timeout: 5))
        if demoSwitch.value as? String != "1" { demoSwitch.tap() }
        app.buttons[labels[3]].tap()
        XCTAssertTrue(app.staticTexts[labels[4]].waitForExistence(timeout: 5))
        capture(app, language + "-01-calendar-planner")

        let conflict = app.buttons[labels[5]]
        if !conflict.isHittable { app.swipeUp() }
        XCTAssertTrue(conflict.waitForExistence(timeout: 5))
        conflict.tap()
        XCTAssertTrue(app.navigationBars[labels[6]].waitForExistence(timeout: 5))
        capture(app, language + "-02-booking-conflicts")

        // iPad uses a top tab control rather than an XCUIElementTypeTabBar.
        app.buttons.matching(NSPredicate(format: "label == %@", labels[7])).firstMatch.tap()
        XCTAssertTrue(app.navigationBars[labels[8]].waitForExistence(timeout: 5))
        capture(app, language + "-03-calendar-timeline")
        app.buttons.matching(NSPredicate(format: "label == %@", labels[9])).firstMatch.tap()
        XCTAssertTrue(app.navigationBars[labels[10]].waitForExistence(timeout: 5))
        capture(app, language + "-04-trip-organizer")
        if language == "en" { captureEnglishDetailScreens(app) }
    }

    @MainActor private func captureEnglishDetailScreens(_ app: XCUIApplication) {
        let manchester = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Manchester")).firstMatch
        XCTAssertTrue(manchester.waitForExistence(timeout: 5))
        manchester.tap()
        XCTAssertTrue(app.navigationBars["Manchester, for the evening"].waitForExistence(timeout: 5))
        capture(app, "en-05-trip-check")
        app.navigationBars.buttons.firstMatch.tap()

        app.buttons.matching(NSPredicate(format: "label == %@", "Ask")).firstMatch.tap()
        // The eyebrow renders with an uppercase text style in the accessibility tree.
        XCTAssertTrue(app.staticTexts["ASK PLANBRIDGE"].waitForExistence(timeout: 5))
        capture(app, "en-06-private-questions")
        app.buttons.matching(NSPredicate(format: "label == %@", "Today")).firstMatch.tap()
        // Each tab retains its own navigation path, so Today may return to the
        // conflict detail captured earlier. Pop that path before opening Home settings.
        let back = app.buttons["Back"]
        if back.waitForExistence(timeout: 2) { back.tap() }
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 5))
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Your settings"].waitForExistence(timeout: 5))
        capture(app, "en-07-privacy-controls")

        app.buttons["Calendars & imports"].tap()
        XCTAssertTrue(app.navigationBars["Connections"].waitForExistence(timeout: 5))
        capture(app, "en-08-calendar-connections")
        app.buttons["Import an ICS or structured JSON file"].tap()
        XCTAssertTrue(app.navigationBars["Review an import"].waitForExistence(timeout: 5))
        capture(app, "en-09-review-imports")
        app.buttons["Cancel"].tap()
        app.navigationBars.buttons.firstMatch.tap()

        app.buttons["Explore PlanBridge Pro"].tap()
        XCTAssertTrue(app.staticTexts["PlanBridge Pro"].waitForExistence(timeout: 5))
        _ = app.buttons["com.planbridge.ai.pro.monthly"].waitForExistence(timeout: 30)
        capture(app, "en-10-planbridge-pro")
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
