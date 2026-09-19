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
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
