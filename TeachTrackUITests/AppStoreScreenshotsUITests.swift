import XCTest

/// Run on the 6.9-inch iPhone and 13-inch iPad simulators.
/// The launch argument creates an isolated in-memory database with fictional data.
final class AppStoreScreenshotsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCaptureSevenScreens() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-AppStoreDemoData")
        app.launch()

        XCTAssertTrue(app.staticTexts["Cedar Grove School"].waitForExistence(timeout: 20))
        capture("01-organizations", in: app)

        open("Students", in: app)
        XCTAssertTrue(app.staticTexts["Morgan Ava"].waitForExistence(timeout: 10))
        capture("02-students", in: app)

        open("Calendar", in: app)
        XCTAssertTrue(app.staticTexts["No Lessons"].exists ||
                      app.staticTexts["Choir Workshop"].exists ||
                      app.staticTexts["Piano Foundations"].exists)
        capture("03-calendar", in: app)

        open("Finance", in: app)
        XCTAssertTrue(app.navigationBars["Finance"].waitForExistence(timeout: 10))
        capture("04-finance", in: app)

        open("Reports", in: app)
        let debts = app.buttons["Debts"]
        XCTAssertTrue(debts.waitForExistence(timeout: 10))
        debts.tap()
        XCTAssertTrue(app.navigationBars["Unpaid Balances"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["See what is still due"].exists)
        XCTAssertTrue(app.staticTexts["Cedar Grove School"].exists ||
                      app.staticTexts["Morgan Ava"].exists ||
                      app.staticTexts["Rivera Noah"].exists)
        capture("05-unpaid-balances", in: app)

        returnToReports(from: "Unpaid Balances", in: app)
        app.buttons["Lesson History"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Lesson History"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Every lesson, in one place"].exists)
        capture("06-lesson-history", in: app)

        returnToReports(from: "Lesson History", in: app)
        app.buttons["Payment and Charge History"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Transactions"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Follow every payment"].exists)
        capture("07-payment-history", in: app)
    }

    @MainActor
    private func open(_ tab: String, in app: XCUIApplication) {
        if app.buttons[tab].firstMatch.exists {
            app.buttons[tab].firstMatch.tap()
        } else {
            app.buttons["More"].firstMatch.tap()
            app.staticTexts[tab].firstMatch.tap()
        }
    }

    @MainActor
    private func returnToReports(from title: String, in app: XCUIApplication) {
        let back = app.navigationBars[title].buttons.firstMatch
        XCTAssertTrue(back.exists)
        back.tap()
        XCTAssertTrue(app.buttons["Lesson History"].firstMatch.waitForExistence(timeout: 10))
    }

    @MainActor
    private func capture(_ name: String, in app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
