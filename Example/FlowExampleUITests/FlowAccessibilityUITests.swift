import XCTest

final class FlowAccessibilityUITests: XCTestCase {
    @MainActor
    func testCappedRoutesWithoutSeparatorsHideTruncatedControls() {
        for option in ["--cap-only", "--no-separators"] {
            let app = XCUIApplication()
            app.launchArguments = ["--flow-accessibility-fixture", option]
            app.launch()
            XCTAssertTrue(app.buttons["item-0"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons["item-1"].exists)
            app.buttons["expand"].click()
            XCTAssertTrue(app.buttons["item-2"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons["item-3"].exists)
            app.terminate()
        }
    }

    @MainActor
    func testTruncationHidesControlsFromAccessibilityAndHitTesting() {
        let app = XCUIApplication()
        app.launchArguments = ["--flow-accessibility-fixture"]
        app.launch()
        XCTAssertTrue(app.buttons["item-0"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["overflow"].exists)
        XCTAssertTrue(app.buttons["item-0"].isHittable)
        XCTAssertTrue(app.buttons["overflow"].isHittable)
        XCTAssertFalse(app.buttons["item-1"].exists, "Truncated controls must not remain in the accessibility tree")
        XCTAssertFalse(app.buttons["item-2"].exists)
        XCTAssertFalse(app.buttons["item-3"].exists)
        XCTAssertEqual(app.staticTexts.matching(identifier: "separator").count, 1, "Only the visible separator before overflow is exposed")

        app.buttons["expand"].click()
        XCTAssertTrue(app.buttons["item-1"].isEnabled)
        XCTAssertTrue(app.buttons["item-2"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["item-2"].isHittable)
        XCTAssertFalse(app.buttons["item-3"].exists, "Caller-supplied accessibilityHidden must remain effective")
        XCTAssertFalse(app.buttons["overflow"].exists)
        XCTAssertEqual(app.staticTexts.matching(identifier: "separator").count, 0)
        app.buttons["item-2"].click()
        XCTAssertEqual(app.staticTexts["last-activation"].value as? String, "2")
        app.buttons["collapse"].click()
        XCTAssertFalse(app.buttons["item-2"].exists)
    }

    @MainActor
    func testTruncatedControlsRejectKeyboardFocusUntilRevealed() {
        let app = XCUIApplication()
        app.launchArguments = ["--flow-accessibility-fixture"]
        app.launch()
        XCTAssertTrue(app.buttons["start-focus"].waitForExistence(timeout: 5))
        app.buttons["start-focus"].click()
        app.typeKey(.space, modifierFlags: [])
        XCTAssertEqual(app.staticTexts["last-activation"].value as? String, "0", "Positive control: keyboard activation reaches the first item")
        app.buttons["focus-second"].click()
        app.typeKey(.space, modifierFlags: [])
        XCTAssertEqual(app.staticTexts["last-activation"].value as? String, "0", "A truncated button cannot receive keyboard activation")
        app.buttons["expand"].click()
        XCTAssertTrue(app.buttons["item-1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["item-1"].isEnabled)
        app.buttons["start-focus"].click()
        app.buttons["focus-second"].click()
        app.typeKey(.space, modifierFlags: [])
        XCTAssertEqual(app.staticTexts["last-activation"].value as? String, "1", "A revealed control accepts focus and keyboard activation again")
    }
}
