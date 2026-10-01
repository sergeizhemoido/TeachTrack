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
    func testStudentContactsCanBePartialAndEdited() throws {
        let app = XCUIApplication()
        let id = String(UUID().uuidString.prefix(6))
        let firstName = "Contact\(id)"
        let lastName = "Student"
        let relative = "Relative\(id)"
        app.launch()
        app.tabBars.buttons["Students"].tap()
        tap("addRegularStudentButton", in: app)
        enter(firstName, in: "First Name", app: app)
        enter(lastName, in: "Last Name", app: app)
        enter("Initial note", in: "Notes", app: app)
        app.buttons["Save"].tap()
        app.staticTexts["\(lastName) \(firstName)"].tap()
        app.buttons["Contacts"].tap()
        XCTAssertTrue(app.staticTexts["Initial note"].waitForExistence(timeout: 5))

        XCTAssertFalse(app.buttons["Edit Student Contact"].exists)
        tap("addStudentContactButton", in: app)
        XCTAssertTrue(app.buttons["Student Contact"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Relative Contact"].exists)
        app.buttons["Student Contact"].tap()
        XCTAssertTrue(app.navigationBars["Student Contact"].waitForExistence(timeout: 5))
        enter("5551234567", in: "Phone", app: app)
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["5551234567"].waitForExistence(timeout: 5))
        app.staticTexts["5551234567"].swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertFalse(app.staticTexts["5551234567"].exists)

        tap("addStudentContactButton", in: app)
        app.buttons["Relative Contact"].tap()
        XCTAssertTrue(app.navigationBars["New Relative Contact"].waitForExistence(timeout: 5))
        enter(relative, in: "Relative / Contact Name", app: app)
        app.buttons["Save"].tap()
        app.staticTexts[relative].tap()
        app.buttons["Edit"].tap()
        enter("Emergency contact", in: "Notes", app: app)
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Emergency contact"].waitForExistence(timeout: 5))
        app.staticTexts["Emergency contact"].swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertFalse(app.staticTexts["Emergency contact"].exists)
        app.cells.containing(.staticText, identifier: relative).firstMatch.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.navigationBars["Contacts"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts[relative].exists)
    }

    @MainActor
    func testStudentAccountHistoryDateRange() throws {
        let app = XCUIApplication()
        let id = String(UUID().uuidString.prefix(6))
        let firstName = "History\(id)"
        app.launch()
        app.tabBars.buttons["Students"].tap()
        tap("addRegularStudentButton", in: app)
        enter(firstName, in: "First Name", app: app)
        enter("Student", in: "Last Name", app: app)
        app.buttons["Save"].tap()
        app.staticTexts["Student \(firstName)"].tap()
        app.buttons["Account and History"].tap()

        app.buttons["Add Receipt"].tap()
        app.buttons["Add Deposit"].tap()
        enter("12", in: "Amount", app: app)
        app.buttons["Save"].tap()
        XCTAssertEqual(app.staticTexts["accountDeposit"].label, "12")

        let rangeToggle = app.switches["accountHistoryDateRangeToggle"]
        XCTAssertTrue(rangeToggle.waitForExistence(timeout: 5))
        rangeToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertEqual(rangeToggle.value as? String, "1")
        XCTAssertTrue(app.descendants(matching: .any)["accountHistoryStartDatePicker"]
            .waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["accountHistoryEndDatePicker"].exists)
        XCTAssertEqual(app.staticTexts["accountDeposit"].label, "12")
    }

    @MainActor
    func testOrganizationDepositAndPaymentEntry() throws {
        let app = XCUIApplication()
        let name = "QA Payments \(UUID().uuidString.prefix(6))"
        app.launch()
        app.tabBars.buttons["Organizations"].tap()
        createOrganization(name, type: nil, in: app)
        tap("organizationRow-\(name)", in: app)
        app.buttons["Account and History"].tap()

        app.buttons["Add Receipt"].tap()
        app.buttons["Add Deposit"].tap()
        enter("20", in: "Amount", app: app)
        app.buttons["Save"].tap()
        XCTAssertEqual(app.staticTexts["accountDeposit"].label, "20")

        app.buttons["Add Receipt"].tap()
        app.buttons["Record Payment"].tap()
        enter("30", in: "Amount", app: app)
        app.buttons["Save"].tap()
        XCTAssertEqual(app.staticTexts["accountDeposit"].label, "50")
        XCTAssertEqual(app.staticTexts["accountUnpaid"].label, "0")
    }

    @MainActor
    func testOrganizationPerPresentStudentOption() throws {
        let app = XCUIApplication()
        let id = String(UUID().uuidString.prefix(6))
        let organizationName = "QA Count School \(id)"
        let groupName = "QA Count Group \(id)"
        app.launch()
        app.tabBars.buttons["Organizations"].tap()
        createOrganization(organizationName, type: nil, in: app)
        tap("organizationRow-\(organizationName)", in: app)
        tap("addGroupButton", in: app)
        enter(groupName, in: "Group Name", app: app)
        XCTAssertFalse(app.buttons["Save"].isEnabled)
        tap("compensationPicker", in: app)
        app.buttons["Organization: Per Present Student"].tap()
        enter("35", in: "organizationAttendanceRateField", app: app)
        app.buttons["Save"].tap()
        tap("groupRow-\(groupName)", in: app)
        XCTAssertTrue(app.staticTexts["Rate Per Present Student"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["35"].exists)
        app.buttons["Edit"].tap()
        XCTAssertTrue(app.navigationBars["Edit Group"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["compensationPicker"].exists)
    }

    @MainActor
    func testFinancialAndAttendanceReportsOpen() throws {
        let app = XCUIApplication()
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        app.tabBars.buttons["More"].tap()
        app.staticTexts["Reports"].tap()
        let rangeToggle = app.switches["reportDateRangeToggle"]
        XCTAssertTrue(rangeToggle.waitForExistence(timeout: 5))
        rangeToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertEqual(rangeToggle.value as? String, "1")

        let reportsList = app.collectionViews.firstMatch
        reportsList.swipeDown()
        reportsList.swipeDown()

        for (link, title) in [
            ("Lesson History", "Lesson History"),
            ("Payment and Charge History", "Transactions"),
            ("Attendance", "Attendance"),
            ("Debts", "Unpaid Balances")
        ] {
            let report = app.buttons[link]
            for _ in 0..<6 where !report.isHittable {
                reportsList.swipeUp()
            }
            XCTAssertTrue(report.isHittable, "Report is not visible: \(link)")
            report.tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 10))
            back(to: "Reports", app: app)
        }
    }

    @MainActor
    func testSettingsRequireConfirmationBeforeClearingDatabase() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["More"].tap()
        app.staticTexts["Settings"].tap()
        XCTAssertTrue(app.segmentedControls["databaseLocationPicker"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["iCloud"].exists)
        XCTAssertTrue(app.buttons["checkCloudConnectionButton"].exists)
        XCTAssertTrue(app.buttons["clearDatabaseButton"].waitForExistence(timeout: 10))
        app.buttons["clearDatabaseButton"].tap()
        XCTAssertTrue(app.buttons["Delete All Data"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(
            format: "label CONTAINS %@", "This deletes all organizations"
        )).firstMatch.exists)
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
        app.buttons["Each Student"].tap()
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
    func testOrganizationLessonBillingWithAttendance() throws {
        let app = XCUIApplication()
        let id = String(UUID().uuidString.prefix(6))
        let organizationName = "QA Fixed School \(id)"
        let groupName = "QA Fixed Group \(id)"
        let firstName = "Riley\(id)"
        app.launch()
        app.tabBars.buttons["Students"].tap()
        tap("addRegularStudentButton", in: app)
        enter(firstName, in: "First Name", app: app)
        enter("Student", in: "Last Name", app: app)
        app.buttons["Save"].tap()
        app.tabBars.buttons["Finance"].tap()
        let chargesBefore = financeCharges(in: app)
        app.tabBars.buttons["Organizations"].tap()
        createOrganization(organizationName, type: nil, in: app)
        tap("organizationRow-\(organizationName)", in: app)
        tap("addGroupButton", in: app)
        enter(groupName, in: "Group Name", app: app)
        XCTAssertFalse(app.buttons["Save"].isEnabled)
        tap("compensationPicker", in: app)
        app.buttons["Organization: Fixed Per Lesson"].tap()
        enter("50", in: "perLessonRateField", app: app)
        app.buttons["Save"].tap()
        tap("groupRow-\(groupName)", in: app)
        XCTAssertTrue(app.staticTexts["No Students"].exists)
        tap("groupAddMenu", in: app)
        XCTAssertTrue(app.buttons["Add Student"].exists)
        app.buttons["Add Student"].tap()
        tap("studentPicker", in: app)
        app.buttons["Student \(firstName)"].tap()
        app.buttons["Save"].tap()
        tap("groupAddMenu", in: app)
        app.buttons["Add Lesson"].tap()
        app.buttons["Save"].tap()
        tap("lessonRow", in: app)
        app.buttons["Attendance"].tap()
        app.buttons.matching(NSPredicate(
            format: "label BEGINSWITH %@", "Student \(firstName)"
        )).firstMatch.tap()
        app.buttons["Save"].tap()
        back(to: "Lesson", app: app)
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
