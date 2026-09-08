import XCTest

/// Exercises the real shell and gallery with native operations stubbed out.
final class GalleryInteractionTests: XCTestCase {
    private let app = XCUIApplication(bundleIdentifier: "local.eagle.island-gallery-preview")

    override func setUp() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    private func open(_ arguments: [String] = []) {
        app.launchArguments = arguments
        app.launch()
        let gallery = app.buttons["Open Island Gallery"]
        XCTAssertTrue(gallery.waitForExistence(timeout: 10))
        gallery.tap()
        XCTAssertTrue(app.buttons["island-apply"].waitForExistence(timeout: 10))
    }

    private func checkActionAboveTabs() {
        let action = app.buttons["island-apply"]
        let tab = app.buttons["Personalizar"]
        XCTAssertTrue(action.isHittable, app.debugDescription)
        XCTAssertTrue(tab.exists)
        XCTAssertLessThanOrEqual(action.frame.maxY, tab.frame.minY)
        XCTAssertGreaterThanOrEqual(action.frame.height, 44)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testPrepareAfterScrolling() {
        open(["--needs-access", "--collection"])
        app.swipeUp()
        checkActionAboveTabs()
        app.buttons["island-apply"].tap()
        XCTAssertTrue(app.staticTexts["Access setup placeholder — isolated preview app"].waitForExistence(timeout: 5))
    }

    func testApplyAfterScrolling() {
        open(["--collection"])
        app.swipeUp()
        checkActionAboveTabs()
        app.buttons["island-apply"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.alerts.staticTexts["Preview only: no native operation was performed."].exists)
    }

    func testReapplyAndRemove() {
        open(["--active"])
        checkActionAboveTabs()
        app.buttons["island-apply"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
        app.alerts.buttons["Listo"].tap()
        XCTAssertTrue(app.buttons["island-remove"].isHittable)
        app.buttons["island-remove"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
    }

    func testLargeTextLightAppearance() {
        open(["--needs-access", "--large-text", "--light"])
        checkActionAboveTabs()
        app.buttons["island-apply"].tap()
        XCTAssertTrue(app.staticTexts["Access setup placeholder — isolated preview app"].waitForExistence(timeout: 5))
    }

    func testLandscape() {
        open(["--needs-access"])
        XCUIDevice.shared.orientation = .landscapeLeft
        checkActionAboveTabs()
        app.buttons["island-apply"].tap()
        XCTAssertTrue(app.staticTexts["Access setup placeholder — isolated preview app"].waitForExistence(timeout: 5))
    }

    func testSearchAndTabReturn() {
        open(["--needs-access", "--collection"])
        let search = app.textFields["island-search"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("zzzz-no-result")
        // Clearing an empty result restores the selected theme and its action.
        app.buttons["Borrar búsqueda"].tap()
        app.swipeDown()
        app.buttons["Acceso"].tap()
        app.buttons["Personalizar"].tap()
        checkActionAboveTabs()
        app.buttons["island-apply"].tap()
        XCTAssertTrue(app.staticTexts["Access setup placeholder — isolated preview app"].waitForExistence(timeout: 5))
    }
}
