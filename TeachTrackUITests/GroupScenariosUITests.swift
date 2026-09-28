import XCTest

final class GroupScenariosUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testPrivateStudentCreation() throws {
        let app = XCUIApplication()
        let id = String(UUID().uuidString.prefix(6))
        let organizationName = "QA Private Check \(id)"
        let studentName = "Piper\(id) Private"
        app.launch()
        app.tabBars.buttons["Organizations"].tap()
        createOrganization(organizationName, type: "Private Client", in: app)
        tap("organizationRow-\(organizationName)", in: app)
        tap("addPrivateStudentButton", in: app)
        enter("Piper\(id)", in: "First Name", app: app)
        enter("Private", in: "Last Name", app: app)
        enter("60", in: "Lesson Price", app: app)
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts[studentName].waitForExistence(timeout: 10))
        tap("groupRow-\(studentName)", in: app)
        XCTAssertTrue(app.navigationBars[studentName].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["groupAddMenu"].exists)
    }

    @MainActor
    func testRegularEnrollmentFiltersPrivateStudents() throws {
        let app = XCUIApplication()
        let id = String(UUID().uuidString.prefix(6))
        let privateOrganization = "QA Private Filter \(id)"
        let regularOrganization = "QA Regular School \(id)"
        let groupName = "QA Per Student \(id)"
        let privateStudent = "Filter Piper\(id)"
        let regularStudent = "Riley Regular\(id)"
        app.launch()
        app.tabBars.buttons["Organizations"].tap()
        createOrganization(privateOrganization, type: "Private Client", in: app)
        tap("organizationRow-\(privateOrganization)", in: app)
        tap("addPrivateStudentButton", in: app)
        enter("Piper\(id)", in: "First Name", app: app)
        enter("Filter", in: "Last Name", app: app)
        enter("60", in: "Lesson Price", app: app)
        app.buttons["Save"].tap()
        back(to: "Organizations", app: app)

        app.tabBars.buttons["Students"].tap()
        tap("addRegularStudentButton", in: app)
        enter("Regular\(id)", in: "First Name", app: app)
        enter("Riley", in: "Last Name", app: app)
        app.buttons["Save"].tap()

        app.tabBars.buttons["Organizations"].tap()
        createOrganization(regularOrganization, type: nil, in: app)
        tap("organizationRow-\(regularOrganization)", in: app)
        tap("addGroupButton", in: app)
        enter(groupName, in: "Group Name", app: app)
        XCTAssertFalse(app.buttons["Save"].isEnabled)
        tap("compensationPicker", in: app)
        app.buttons["Per Student"].tap()
        enter("25", in: "perStudentRateField", app: app)
        app.buttons["Save"].tap()
        tap("groupRow-\(groupName)", in: app)
        tap("groupAddMenu", in: app)
        app.buttons["Add Student"].tap()
        tap("studentPicker", in: app)
        XCTAssertTrue(app.buttons[regularStudent].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons[privateStudent].exists)
        app.buttons[regularStudent].tap()
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts[regularStudent].waitForExistence(timeout: 10))
    }

    @MainActor
    func testFixedLessonBillingWithoutEnrollment() throws {
        let app = XCUIApplication()
        let id = String(UUID().uuidString.prefix(6))
        let organizationName = "QA Fixed School \(id)"
        let groupName = "QA Fixed Group \(id)"
        app.launch()
        app.tabBars.buttons["Finance"].tap()
        let chargesBefore = financeCharges(in: app)
        app.tabBars.buttons["Organizations"].tap()
        createOrganization(organizationName, type: nil, in: app)
        tap("organizationRow-\(organizationName)", in: app)
        tap("addGroupButton", in: app)
        enter(groupName, in: "Group Name", app: app)
        XCTAssertFalse(app.buttons["Save"].isEnabled)
        tap("compensationPicker", in: app)
        app.buttons["Fixed Per Lesson"].tap()
        enter("50", in: "perLessonRateField", app: app)
        app.buttons["Save"].tap()
        tap("groupRow-\(groupName)", in: app)
        XCTAssertFalse(app.staticTexts["No Students"].exists)
        tap("groupAddMenu", in: app)
        XCTAssertFalse(app.buttons["Add Student"].exists)
        app.buttons["Add Lesson"].tap()
        app.buttons["Save"].tap()
        tap("lessonRow", in: app)
        XCTAssertFalse(app.buttons["Attendance"].exists)
        app.buttons["Edit"].tap()
        tap("lessonStatusPicker", in: app)
        app.buttons["completed"].tap()
        app.buttons["Save"].tap()
        app.tabBars.buttons["Finance"].tap()
        XCTAssertEqual(financeCharges(in: app), chargesBefore + 50)
        app.tabBars.buttons["Organizations"].tap()
        app.buttons["Edit"].tap()
        tap("lessonStatusPicker", in: app)
        app.buttons["cancelled"].tap()
        app.buttons["Save"].tap()
        app.tabBars.buttons["Finance"].tap()
        XCTAssertEqual(financeCharges(in: app), chargesBefore)
    }

    @MainActor
    private func createOrganization(
        _ name: String,
        type: String?,
        in app: XCUIApplication
    ) {
        tap("addOrganizationButton", in: app)
        enter(name, in: "Name", app: app)
        if let type {
            tap("organizationTypePicker", in: app)
            app.buttons[type].tap()
        }
        app.buttons["Save"].tap()
    }

    @MainActor
    private func enter(
        _ value: String,
        in identifier: String,
        app: XCUIApplication
    ) {
        let field = app.textFields[identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 10), "Missing field: \(identifier)")
        field.tap()
        field.typeText(value)
    }

    @MainActor
    private func tap(_ identifier: String, in app: XCUIApplication) {
        let element = app.descendants(matching: .any)
            .matching(identifier: identifier).firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: 10), "Missing: \(identifier)")
        element.tap()
    }

    @MainActor
    private func back(to title: String, app: XCUIApplication) {
        let button = app.navigationBars.buttons[title]
        XCTAssertTrue(button.waitForExistence(timeout: 10), "Missing back: \(title)")
        button.tap()
    }

    @MainActor
    private func financeCharges(in app: XCUIApplication) -> Decimal {
        let amount = app.staticTexts["financeTotalCharges"]
        XCTAssertTrue(amount.waitForExistence(timeout: 10))
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        guard let value = formatter.number(from: amount.label) else {
            XCTFail("Invalid charge amount: \(amount.label)")
            return 0
        }
        return value.decimalValue
    }
}
