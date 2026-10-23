import Foundation
import SwiftData
import Testing
@testable import TeachTrack

struct TeachTrackTests {
    private final class WorkbookFixtureMarker: NSObject { }

    @Test
    func numbersWorkbookImportsStandardCompressedWorkbook() throws {
        let url = try #require(Bundle(for: WorkbookFixtureMarker.self)
            .url(forResource: "NumbersEdited", withExtension: "xlsx"))
        let snapshot = try NumbersWorkbookBackup.read(Data(contentsOf: url))
        #expect(snapshot.students.first?.firstName == "Мария")
        #expect(snapshot.organizations.first?.name == "Музыкальная школа № 5")
        #expect(snapshot.transactions.first?.amount == 15.25)
    }

    @Test @MainActor
    func appStoreDemoDataCoversSchedulesLessonsAndBalances() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(
            for: Organization.self, Group.self, Student.self, Contact.self,
            Enrollment.self, ScheduleRule.self, ScheduleException.self,
            Lesson.self, Attendance.self, AttendanceRevision.self,
            Transaction.self, StudentNote.self, LessonNote.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        try AppStoreDemoData.populate(context)

        let organizations = try context.fetch(FetchDescriptor<Organization>())
        let groups = try context.fetch(FetchDescriptor<Group>())
        let students = try context.fetch(FetchDescriptor<Student>())
        let lessons = try context.fetch(FetchDescriptor<Lesson>())
        let transactions = try context.fetch(FetchDescriptor<Transaction>())
        #expect(organizations.count == 4)
        #expect(students.count == 7)
        #expect(groups.first { $0.name == "Piano Foundations" }?.ratePerStudent == 10)
        #expect(groups.first { $0.name == "Emma Hayes" }?.ratePerStudent == 15)
        #expect(try context.fetch(FetchDescriptor<ScheduleRule>()).count == 8)
        #expect(lessons.contains { $0.source == .generated && $0.status == .completed })
        #expect(lessons.contains { $0.source == .manual && $0.status == .completed })
        #expect(lessons.filter { $0.group.name == "Emma Hayes" && $0.source == .manual }.count >= 3)
        #expect(lessons.contains { $0.status == .planned && $0.startDate > .now })
        #expect(lessons.contains { $0.status == .cancelled })
        #expect(transactions.contains { $0.type == .charge })
        #expect(transactions.filter { $0.type == .payment }.count >= 7)
        #expect(transactions.contains { $0.type == .deposit })
        let studentDebts = students.map {
            AccountLedger.summary(AccountLedger.entries(for: $0, in: transactions)).debt
        }
        let organizationDebts = organizations.map {
            AccountLedger.summary(AccountLedger.entries(organization: $0, in: transactions)).debt
        }
        #expect(studentDebts.contains { $0 > 0 })
        #expect(organizationDebts.contains { $0 > 0 })
        #expect(studentDebts.allSatisfy { $0 <= 60 })
        #expect(organizationDebts.allSatisfy { $0 <= 60 })
    }

    @MainActor
    private func context() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(
            for: Organization.self, Group.self, Student.self, Enrollment.self,
            Lesson.self, Attendance.self, AttendanceRevision.self, Transaction.self,
            ScheduleRule.self, ScheduleException.self,
            configurations: configuration
        )
        return ModelContext(container)
    }

    @Test @MainActor
    func organizationLessonDepositAndCancellation() throws {
        let context = try context()
        let organization = Organization(name: "School", type: .school)
        let group = Group(name: "Class", revenueModel: .fixedPerLesson, organization: organization)
        group.fixedLessonRate = 100
        let student = Student(firstName: "A", lastName: "B")
        let enrollment = Enrollment(student: student, group: group, lessonPrice: nil)
        let lesson = Lesson(
            group: group,
            startDate: .now.addingTimeInterval(60),
            endDate: .now.addingTimeInterval(3660),
            source: .manual
        )
        context.insert(organization)
        context.insert(group)
        context.insert(student)
        context.insert(enrollment)
        context.insert(lesson)
        try context.save()

        lesson.status = .completed
        try LessonBillingService.syncCharge(for: lesson, context: context)

        // Historical attendance may exist, but fixed organization billing does not require it.
        let attendance = Attendance(student: student, lesson: lesson, status: .absent)
        context.insert(attendance)
        try context.save()
        try LessonBillingService.syncCharge(for: lesson, context: context)
        try context.save()

        let original = try context.fetch(FetchDescriptor<Transaction>())
        #expect(original.count == 1)
        #expect(original.first?.organization?.uuid == organization.uuid)
        #expect(original.first?.amount == 100)

        let payment = Transaction(amount: 40, type: .payment)
        payment.organization = organization
        let deposit = Transaction(amount: 30, type: .deposit)
        deposit.organization = organization
        context.insert(payment)
        context.insert(deposit)
        try context.save()
        let entries = AccountLedger.entries(
            organization: organization,
            in: try context.fetch(FetchDescriptor<Transaction>())
        )
        #expect(AccountLedger.summary(entries).debt == 30)
        #expect(AccountLedger.summary(entries).outstanding.first?.unpaid == 30)

        lesson.status = .cancelled
        try LessonBillingService.syncCharge(for: lesson, context: context)
        try context.save()
        let final = AccountLedger.entries(
            organization: organization,
            in: try context.fetch(FetchDescriptor<Transaction>())
        )
        #expect(final.filter { $0.type == .charge }.count == 2)
        #expect(AccountLedger.summary(final).debt == 0)
        #expect(AccountLedger.summary(final).depositBalance == 70)
        #expect(attendance.status == .absent)
    }

    @Test @MainActor
    func studentChargesFollowAttendance() throws {
        let context = try context()
        let organization = Organization(name: "School", type: .school)
        let group = Group(name: "Students", revenueModel: .perStudent, organization: organization)
        group.ratePerStudent = 25
        let first = Student(firstName: "One", lastName: "Student")
        let second = Student(firstName: "Two", lastName: "Student")
        let firstEnrollment = Enrollment(student: first, group: group, lessonPrice: 25)
        let secondEnrollment = Enrollment(student: second, group: group, lessonPrice: 25)
        let lesson = Lesson(
            group: group,
            startDate: .now.addingTimeInterval(60),
            endDate: .now.addingTimeInterval(3660),
            source: .manual
        )
        context.insert(organization)
        context.insert(group)
        context.insert(first)
        context.insert(second)
        context.insert(firstEnrollment)
        context.insert(secondEnrollment)
        context.insert(lesson)
        let present = Attendance(student: first, lesson: lesson, status: .present)
        let excused = Attendance(student: second, lesson: lesson, status: .excused)
        context.insert(present)
        context.insert(excused)
        try context.save()

        lesson.status = .completed
        try LessonBillingService.syncCharge(for: lesson, context: context)
        try context.save()
        var charges = try context.fetch(FetchDescriptor<Transaction>())
        #expect(charges.count == 1)
        #expect(charges.first?.student?.uuid == first.uuid)
        #expect(charges.first?.amount == 25)

        excused.status = .absent
        try LessonBillingService.syncCharge(for: lesson, context: context)
        try context.save()
        charges = try context.fetch(FetchDescriptor<Transaction>())
        #expect(charges.count == 2)
        #expect(charges.contains { $0.student?.uuid == second.uuid && $0.amount == 25 })

        let deposit = Transaction(amount: 10, type: .deposit)
        deposit.student = first
        context.insert(deposit)
        try context.save()
        var firstEntries = AccountLedger.entries(
            for: first,
            in: try context.fetch(FetchDescriptor<Transaction>())
        )
        #expect(AccountLedger.summary(firstEntries).debt == 15)

        let payment = Transaction(amount: 15, type: .payment)
        payment.student = first
        context.insert(payment)
        try context.save()
        firstEntries = AccountLedger.entries(
            for: first,
            in: try context.fetch(FetchDescriptor<Transaction>())
        )
        #expect(AccountLedger.summary(firstEntries).debt == 0)
    }

    @Test @MainActor
    func organizationChargeCountsOnlyPresentStudents() throws {
        let context = try context()
        let organization = Organization(name: "School", type: .school)
        let group = Group(
            name: "Attendance Based",
            revenueModel: .organizationPerAttendee,
            organization: organization
        )
        group.organizationAttendanceRate = 30
        let first = Student(firstName: "First", lastName: "Student")
        let second = Student(firstName: "Second", lastName: "Student")
        let firstEnrollment = Enrollment(student: first, group: group, lessonPrice: nil)
        let secondEnrollment = Enrollment(student: second, group: group, lessonPrice: nil)
        let lesson = Lesson(
            group: group,
            startDate: .now.addingTimeInterval(60),
            endDate: .now.addingTimeInterval(3660),
            source: .manual
        )
        context.insert(organization)
        context.insert(group)
        context.insert(first)
        context.insert(second)
        context.insert(firstEnrollment)
        context.insert(secondEnrollment)
        context.insert(lesson)
        let present = Attendance(student: first, lesson: lesson, status: .present)
        let absent = Attendance(student: second, lesson: lesson, status: .absent)
        context.insert(present)
        context.insert(absent)
        try context.save()

        lesson.status = .completed
        try LessonBillingService.syncCharge(for: lesson, context: context)
        try context.save()
        var entries = try context.fetch(FetchDescriptor<Transaction>())
        #expect(entries.count == 1)
        #expect(entries.first?.organization?.uuid == organization.uuid)
        #expect(entries.first?.student == nil)
        #expect(AccountLedger.summary(entries).charges == 30)

        group.organizationAttendanceRate = 50
        absent.status = .present
        try LessonBillingService.syncCharge(for: lesson, context: context)
        try context.save()
        entries = try context.fetch(FetchDescriptor<Transaction>())
        #expect(AccountLedger.summary(entries).charges == 60)
        #expect(lesson.billedRate == 30)

        present.status = .excused
        try LessonBillingService.syncCharge(for: lesson, context: context)
        try context.save()
        entries = try context.fetch(FetchDescriptor<Transaction>())
        #expect(AccountLedger.summary(entries).charges == 30)
        #expect(entries.contains { $0.amount == -30 })

        lesson.status = .cancelled
        try LessonBillingService.syncCharge(for: lesson, context: context)
        try context.save()
        entries = try context.fetch(FetchDescriptor<Transaction>())
        #expect(AccountLedger.summary(entries).charges == 0)
        #expect(entries.filter { $0.type == .charge }.count == 4)
    }

    @Test @MainActor
    func reportsHideArchivedPeopleAndFutureLessons() {
        let now = Date()
        let organization = Organization(name: "School", type: .school)
        let group = Group(name: "Group", revenueModel: .perStudent, organization: organization)
        let active = Student(firstName: "Active", lastName: "Student")
        let archived = Student(firstName: "Archived", lastName: "Student")
        archived.isActive = false
        let past = Lesson(
            group: group,
            startDate: now.addingTimeInterval(-86_400),
            endDate: now.addingTimeInterval(-82_800),
            source: .manual
        )
        past.status = .completed
        let inProgress = Lesson(
            group: group,
            startDate: now.addingTimeInterval(-1_800),
            endDate: now.addingTimeInterval(1_800),
            source: .manual
        )
        let future = Lesson(
            group: group,
            startDate: now.addingTimeInterval(86_400),
            endDate: now.addingTimeInterval(90_000),
            source: .manual
        )
        let records = [
            Attendance(student: active, lesson: past, status: .present),
            Attendance(student: archived, lesson: past, status: .present),
            Attendance(student: active, lesson: future, status: .present)
        ]

        #expect(ReportVisibility.attendances(records, now: now).count == 1)
        #expect(ReportVisibility.attendances(
            records, now: now, includeArchived: true
        ).count == 2)
        #expect(ReportVisibility.lessons([past, inProgress, future], now: now).count == 1)

        organization.isActive = false
        #expect(ReportVisibility.attendances(records, now: now).isEmpty)
        #expect(ReportVisibility.lessons([past, inProgress, future], now: now).isEmpty)
    }

    @Test @MainActor
    func reportRangeIncludesEntireLastDayAndFiltersLessons() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let first = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 1)))
        let last = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 30)))
        let next = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 1)))
        let range = ReportDateRange(from: first, through: last, calendar: calendar)

        #expect(range.contains(first))
        #expect(range.contains(next.addingTimeInterval(-1)))
        #expect(!range.contains(next))

        let organization = Organization(name: "School", type: .school)
        let group = Group(name: "Class", revenueModel: .perStudent, organization: organization)
        let september = Lesson(group: group, startDate: last, endDate: last.addingTimeInterval(3600), source: .manual)
        september.status = .completed
        let october = Lesson(group: group, startDate: next, endDate: next.addingTimeInterval(3600), source: .manual)
        #expect(ReportVisibility.lessons([september, october], now: next, range: range).count == 1)
    }

    @Test @MainActor
    func periodDebtAppliesPaymentsThroughPeriodEnd() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let august = try #require(calendar.date(from: DateComponents(year: 2026, month: 8, day: 15)))
        let september = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 15)))
        let septemberEnd = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 30)))
        let october = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 1)))
        let range = ReportDateRange(from: september, through: septemberEnd, calendar: calendar)
        let organization = Organization(name: "School", type: .school)
        let group = Group(name: "Class", revenueModel: .fixedPerLesson, organization: organization)
        let oldLesson = Lesson(group: group, startDate: august, endDate: august.addingTimeInterval(3600), source: .manual)
        let newLesson = Lesson(group: group, startDate: september, endDate: september.addingTimeInterval(3600), source: .manual)
        let oldCharge = Transaction(amount: 100, type: .charge)
        oldCharge.date = august
        oldCharge.lesson = oldLesson
        let newCharge = Transaction(amount: 50, type: .charge)
        newCharge.date = september
        newCharge.lesson = newLesson
        let payment = Transaction(amount: 120, type: .payment)
        payment.date = september
        let laterPayment = Transaction(amount: 30, type: .payment)
        laterPayment.date = october

        #expect(ReportDebtCalculator.unpaid(entries: [oldCharge, newCharge, payment, laterPayment], range: range) == 30)
        #expect(ReportDebtCalculator.unpaid(entries: [oldCharge, newCharge, payment, laterPayment], range: nil) == 0)
    }

    @Test @MainActor
    func databaseSnapshotRoundTripsRelationshipsAndClearsAllModels() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try ModelContainer(
            for: Organization.self, Group.self, Student.self, Contact.self,
            Enrollment.self, ScheduleRule.self, ScheduleException.self,
            Lesson.self, Attendance.self, AttendanceRevision.self,
            Transaction.self, StudentNote.self, LessonNote.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        let organization = Organization(name: "Kindergarten", type: .kindergarten)
        organization.email = "office@example.com"
        let student = Student(firstName: "Ada", lastName: "Example")
        student.phone = "555-0100"
        let group = Group(name: "Artists", revenueModel: .perStudent,
                          organization: organization)
        group.ratePerStudent = 35
        let contact = Contact(student: student, name: "Parent", relationship: "Mother")
        contact.phone = "555-0101"
        let enrollment = Enrollment(student: student, group: group, lessonPrice: 35)
        let rule = ScheduleRule(group: group, weekday: .monday,
                                startHour: 10, startMinute: 30, durationMinutes: 45)
        let exception = ScheduleException(rule: rule, date: .now)
        let lesson = Lesson(group: group, startDate: .now,
                            endDate: .now.addingTimeInterval(2700), source: .generated)
        lesson.generatedFromRule = rule
        lesson.status = .completed
        let attendance = Attendance(student: student, lesson: lesson, status: .present)
        let revision = AttendanceRevision(attendance: attendance, status: .present,
                                          notes: "Confirmed")
        let payment = Transaction(amount: 35, type: .payment)
        payment.student = student
        payment.lesson = lesson
        let studentNote = StudentNote(student: student, text: "Likes painting")
        let lessonNote = LessonNote(lesson: lesson, text: "Watercolors")
        for model in [organization as any PersistentModel, student, group, contact,
                      enrollment, rule, exception, lesson, attendance, revision,
                      payment, studentNote, lessonNote] {
            context.insert(model)
        }
        try context.save()

        let original = try DatabaseSnapshot.capture(from: context)
        #expect(original.recordCount == 13)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DatabaseSnapshot.self, from: encoded)
        try decoded.validate()
        let workbookCopy = try NumbersWorkbookBackup.read(
            NumbersWorkbookBackup.make(original)
        )
        #expect(workbookCopy.recordCount == 13)
        #expect(workbookCopy.contacts.first?.studentID == student.uuid)
        #expect(workbookCopy.exceptions.first?.ruleID == rule.uuid)
        #expect(workbookCopy.studentNotes.first?.studentID == student.uuid)
        #expect(workbookCopy.lessonNotes.first?.lessonID == lesson.uuid)

        try DatabaseSnapshot.clear(context)
        #expect(try context.fetch(FetchDescriptor<Student>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Transaction>()).isEmpty)
        try workbookCopy.restore(into: context)

        let restored = try DatabaseSnapshot.capture(from: context)
        #expect(restored.recordCount == original.recordCount)
        #expect(restored.organizations.first?.id == organization.uuid)
        #expect(restored.groups.first?.organizationID == organization.uuid)
        #expect(restored.enrollments.first?.studentID == student.uuid)
        #expect(restored.lessons.first?.generatedRuleID == rule.uuid)
        #expect(restored.attendances.first?.lessonID == lesson.uuid)
        #expect(restored.revisions.first?.attendanceID == attendance.uuid)
        #expect(restored.transactions.first?.lessonID == lesson.uuid)
        #expect(restored.contacts.first?.phone == "555-0101")

        // Cloud refresh replaces an existing local graph, not an empty store.
        try decoded.restore(into: context)
        let replaced = try DatabaseSnapshot.capture(from: context)
        #expect(replaced.recordCount == original.recordCount)
        #expect(replaced.revisions.first?.attendanceID == attendance.uuid)
    }

    @Test @MainActor
    func numbersWorkbookRoundTripsUnicodeDatesMoneyAndRelationships() throws {
        let organizationID = UUID()
        let studentID = UUID()
        let groupID = UUID()
        let enrollmentID = UUID()
        let ruleID = UUID()
        let lessonID = UUID()
        let attendanceID = UUID()
        let transactionID = UUID()
        let start = Date(timeIntervalSince1970: 1_800_000_000.123)
        var source = DatabaseSnapshot()
        source.organizations = [
            .init(id: organizationID, name: "Музыкальная школа № 5", type: .school,
                  phone: nil, email: nil, address: "Москва", notes: "日本語", isActive: true)
        ]
        source.students = [
            .init(id: studentID, firstName: "Анна", lastName: "Иванова",
                  phone: nil, email: nil, notes: "♫ & <music>", type: .regular, isActive: true)
        ]
        source.groups = [
            .init(id: groupID, name: "Фортепиано", revenueModel: .perStudent,
                  fixedLessonRate: nil, organizationAttendanceRate: nil,
                  ratePerStudent: 15.25, notes: nil, isActive: true,
                  organizationID: organizationID)
        ]
        source.enrollments = [
            .init(id: enrollmentID, studentID: studentID, groupID: groupID,
                  lessonPrice: 15.25, enrollmentDate: start, endDate: nil, isActive: true)
        ]
        source.rules = [
            .init(id: ruleID, groupID: groupID, weekday: .monday, startHour: 15,
                  startMinute: 30, durationMinutes: 45, isActive: true)
        ]
        source.lessons = [
            .init(id: lessonID, groupID: groupID, startDate: start,
                  endDate: start.addingTimeInterval(2700), status: .completed,
                  source: .generated, generatedRuleID: ruleID,
                  isManuallyModified: false, notes: nil, billedRate: 15.25)
        ]
        source.attendances = [
            .init(id: attendanceID, studentID: studentID, lessonID: lessonID,
                  status: .present, makeupSourceID: nil, notes: nil)
        ]
        source.transactions = [
            .init(id: transactionID, date: start, type: .payment, amount: 15.25,
                  studentID: studentID, organizationID: nil, lessonID: lessonID, notes: nil)
        ]

        let workbook = try NumbersWorkbookBackup.make(source)
        #expect(workbook.starts(with: [0x50, 0x4b]))
        let imported = try NumbersWorkbookBackup.read(workbook)
        #expect(imported.recordCount == source.recordCount)
        #expect(imported.organizations.first?.name == "Музыкальная школа № 5")
        #expect(imported.students.first?.notes == "♫ & <music>")
        #expect(imported.groups.first?.ratePerStudent == 15.25)
        #expect(imported.enrollments.first?.groupID == groupID)
        #expect(imported.lessons.first?.generatedRuleID == ruleID)
        #expect(imported.lessons.first?.startDate.timeIntervalSince1970 == start.timeIntervalSince1970)
        #expect(imported.transactions.first?.amount == 15.25)
        var files = try StoredZip.read(workbook)
        let studentSheet = "xl/worksheets/sheet3.xml"
        let originalXML = try #require(files[studentSheet].flatMap {
            String(data: $0, encoding: .utf8)
        })
        #expect(originalXML.contains("Анна"))
        files[studentSheet] = Data(originalXML.replacingOccurrences(
            of: "Анна", with: "Мария"
        ).utf8)
        let editedWorkbook = try StoredZip.write(files.sorted { $0.key < $1.key })
        #expect(try NumbersWorkbookBackup.read(editedWorkbook).students.first?.firstName == "Мария")
        #expect(throws: Error.self) {
            try NumbersWorkbookBackup.read(Data("not an xlsx".utf8))
        }
    }

    @Test @MainActor
    func readableWorkbookKeepsHiddenLinksAndImportsNewStudents() throws {
        let organizationID = UUID()
        let privateOrganizationID = UUID()
        let studentID = UUID()
        let groupID = UUID()
        var snapshot = DatabaseSnapshot()
        snapshot.organizations = [.init(id: organizationID, name: "Sunnyvale School",
                                        type: .school, phone: nil, email: nil,
                                        address: nil, notes: nil, isActive: true),
                                  .init(id: privateOrganizationID, name: "Private Studio",
                                        type: .privateClient, phone: nil, email: nil,
                                        address: nil, notes: nil, isActive: true)]
        snapshot.students = [.init(id: studentID, firstName: "Emma", lastName: "Johnson",
                                   phone: nil, email: nil, notes: nil,
                                   type: .regular, isActive: true)]
        snapshot.groups = [.init(id: groupID, name: "Piano Beginners",
                                 revenueModel: .perStudent, fixedLessonRate: nil,
                                 organizationAttendanceRate: nil, ratePerStudent: 15,
                                 notes: nil, isActive: true, organizationID: organizationID)]
        var files = try StoredZip.read(NumbersWorkbookBackup.make(snapshot))
        let groupsXML = try #require(files["xl/worksheets/sheet4.xml"])
        let groupsText = try #require(String(data: groupsXML, encoding: .utf8))
        #expect(groupsText.contains("hidden=\"1\""))
        #expect(groupsText.contains("Sunnyvale School"))
        #expect(groupsText.contains("Organization ID"))

        let path = "xl/worksheets/sheet15.xml"
        let newStudentsXML = try #require(files[path].flatMap { String(data: $0, encoding: .utf8) })
        let added = """
        <row r="2"><c r="A2" t="inlineStr"><is><t>Анна</t></is></c>
        <c r="B2" t="inlineStr"><is><t>Иванова</t></is></c>
        <c r="C2" t="inlineStr"><is><t>Regular</t></is></c>
        <c r="F2" t="inlineStr"><is><t>555-0100</t></is></c></row>
        <row r="3"><c r="A3" t="inlineStr"><is><t>Leo</t></is></c>
        <c r="B3" t="inlineStr"><is><t>Brown</t></is></c>
        <c r="C3" t="inlineStr"><is><t>Private</t></is></c>
        <c r="D3" t="inlineStr"><is><t>Private Studio</t></is></c>
        <c r="E3"><v>40</v></c></row>
        """
        files[path] = Data(newStudentsXML.replacingOccurrences(
            of: "</sheetData>", with: added + "</sheetData>"
        ).utf8)
        let edited = try StoredZip.write(files.sorted { $0.key < $1.key })
        let rows = try NumbersWorkbookBackup.readNewStudents(edited)
        #expect(rows.count == 2)
        #expect(rows[0].student.firstName == "Анна")
        #expect(rows[0].student.phone == "555-0100")
        #expect(try NumbersWorkbookBackup.readNewStudents(edited)[0].student.id == rows[0].student.id)
        #expect(rows[1].student.type == .privateClient)
        #expect(rows[1].lessonRate == 40)
        let restored = try NumbersWorkbookBackup.read(edited)
        #expect(restored.students.count == 3)
        #expect(restored.groups.count == 2)
        #expect(restored.enrollments.count == 1)
        #expect(restored.enrollments[0].studentID == rows[1].student.id)
        #expect(restored.groups[0].organizationID == organizationID)
    }

    @Test @MainActor
    func qaOrganizationFixedLessonCompletesWithoutStudentEnrollment() throws {
        let context = try context()
        let organization = Organization(name: "QA school", type: .school)
        let group = Group(name: "QA fixed lesson", revenueModel: .fixedPerLesson,
                          organization: organization)
        group.fixedLessonRate = 100
        let lesson = Lesson(group: group, startDate: .now.addingTimeInterval(-7200),
                            endDate: .now.addingTimeInterval(-3600), source: .manual)
        lesson.status = .completed
        context.insert(organization)
        context.insert(group)
        context.insert(lesson)
        try context.save()

        // An organization-paid fixed lesson is billed for the completed lesson itself.
        try LessonBillingService.syncCharge(for: lesson, context: context)
        try context.save()
        let charges = try context.fetch(FetchDescriptor<Transaction>())
        #expect(charges.count == 1)
        #expect(charges.first?.organization?.uuid == organization.uuid)
        #expect(charges.first?.amount == 100)
    }

    @Test @MainActor
    func qaGroupRateChangeAppliesToFutureLesson() throws {
        let context = try context()
        let organization = Organization(name: "QA school", type: .school)
        let group = Group(name: "QA students", revenueModel: .perStudent,
                          organization: organization)
        group.ratePerStudent = 10
        let student = Student(firstName: "QA", lastName: "Student")
        let enrollment = Enrollment(student: student, group: group, lessonPrice: 10)
        let lesson = Lesson(group: group, startDate: .now.addingTimeInterval(3600),
                            endDate: .now.addingTimeInterval(7200), source: .manual)
        let attendance = Attendance(student: student, lesson: lesson, status: .present)
        for model in [organization as any PersistentModel, group, student, enrollment,
                      lesson, attendance] { context.insert(model) }
        try context.save()

        group.ratePerStudent = 15
        lesson.status = .completed
        try LessonBillingService.syncCharge(for: lesson, context: context)
        try context.save()
        let charges = try context.fetch(FetchDescriptor<Transaction>())
        #expect(charges.count == 1)
        #expect(charges.first?.amount == 15)
    }

    @Test @MainActor
    func qaGeneratedScheduleIsIdempotentAndDeletedLessonStaysDeleted() throws {
        let context = try context()
        let organization = Organization(name: "QA School", type: .school)
        let group = Group(name: "QA Schedule", revenueModel: .perStudent,
                          organization: organization)
        group.ratePerStudent = 15
        let day = Calendar.current.startOfDay(for: .now.addingTimeInterval(86_400))
        let weekday = try #require(Weekday(rawValue: Calendar.current.component(.weekday, from: day)))
        let rule = ScheduleRule(group: group, weekday: weekday,
                                startHour: 14, startMinute: 0, durationMinutes: 60)
        context.insert(organization)
        context.insert(group)
        context.insert(rule)
        try context.save()

        LessonGenerator.generateLessons(from: day, through: day, context: context)
        LessonGenerator.generateLessons(from: day, through: day, context: context)
        var lessons = try context.fetch(FetchDescriptor<Lesson>())
        #expect(lessons.count == 1)
        let lesson = try #require(lessons.first)
        #expect(lesson.source == .generated)

        try LessonGenerator.deleteGeneratedLesson(lesson, context: context)
        #expect(try context.fetch(FetchDescriptor<ScheduleException>()).count == 1)
        LessonGenerator.generateLessons(from: day, through: day, context: context)
        lessons = try context.fetch(FetchDescriptor<Lesson>())
        #expect(lessons.isEmpty)
    }

    @Test @MainActor
    func qaRepeatedCompletionDoesNotDoubleCharge() throws {
        let context = try context()
        let organization = Organization(name: "QA School", type: .school)
        let group = Group(name: "QA Group", revenueModel: .perStudent,
                          organization: organization)
        group.ratePerStudent = 15
        let student = Student(firstName: "QA", lastName: "Student")
        let enrollment = Enrollment(student: student, group: group, lessonPrice: 15)
        let lesson = Lesson(group: group, startDate: .now.addingTimeInterval(-7200),
                            endDate: .now.addingTimeInterval(-3600), source: .manual)
        enrollment.enrollmentDate = lesson.startDate.addingTimeInterval(-3600)
        lesson.status = .completed
        let attendance = Attendance(student: student, lesson: lesson, status: .present)
        for model in [organization as any PersistentModel, group, student, enrollment,
                      lesson, attendance] { context.insert(model) }
        try context.save()

        try LessonBillingService.syncCharge(for: lesson, context: context)
        try context.save()
        try LessonBillingService.syncCharge(for: lesson, context: context)
        try context.save()
        let entries = try context.fetch(FetchDescriptor<Transaction>())
        #expect(entries.count == 1)
        #expect(AccountLedger.summary(entries).debt == 15)
    }

    @Test @MainActor
    func qaPrivateLessonChargesDepositsPaymentsAndCancellation() throws {
        let context = try context()
        let organization = Organization(name: "QA Private Studio", type: .privateClient)
        let student = Student(firstName: "QA", lastName: "Private", studentType: .privateClient)
        let group = Group(name: "QA Private Lessons", revenueModel: .perStudent,
                          organization: organization)
        group.ratePerStudent = 40
        let enrollment = Enrollment(student: student, group: group, lessonPrice: 40)
        let first = Lesson(group: group, startDate: .now.addingTimeInterval(-14_400),
                           endDate: .now.addingTimeInterval(-10_800), source: .manual)
        let second = Lesson(group: group, startDate: .now.addingTimeInterval(-7200),
                            endDate: .now.addingTimeInterval(-3600), source: .manual)
        enrollment.enrollmentDate = first.startDate.addingTimeInterval(-3600)
        first.status = .completed
        second.status = .completed
        let firstAttendance = Attendance(student: student, lesson: first, status: .present)
        let secondAttendance = Attendance(student: student, lesson: second, status: .present)
        for model in [organization as any PersistentModel, student, group, enrollment, first,
                      second, firstAttendance, secondAttendance] { context.insert(model) }
        try context.save()

        try LessonBillingService.syncCharge(for: first, context: context)
        try LessonBillingService.syncCharge(for: second, context: context)
        let deposit = Transaction(amount: 50, type: .deposit)
        deposit.student = student
        let payment = Transaction(amount: 20, type: .payment)
        payment.student = student
        context.insert(deposit)
        context.insert(payment)
        try context.save()

        var entries = AccountLedger.entries(
            for: student, in: try context.fetch(FetchDescriptor<Transaction>())
        )
        #expect(entries.filter { $0.type == .charge }.count == 2)
        #expect(AccountLedger.summary(entries).charges == 80)
        #expect(AccountLedger.summary(entries).debt == 10)

        second.status = .cancelled
        try LessonBillingService.syncCharge(for: second, context: context)
        try context.save()
        entries = AccountLedger.entries(
            for: student, in: try context.fetch(FetchDescriptor<Transaction>())
        )
        #expect(entries.filter { $0.type == .charge }.count == 3)
        #expect(AccountLedger.summary(entries).charges == 40)
        #expect(AccountLedger.summary(entries).debt == 0)
        #expect(AccountLedger.summary(entries).depositBalance == 30)
    }

    @Test @MainActor
    func qaHistoricalLessonCannotBeDeleted() throws {
        let context = try context()
        let group = Group(name: "QA History", revenueModel: .perStudent)
        let student = Student(firstName: "QA", lastName: "History")
        let lesson = Lesson(group: group, startDate: .now.addingTimeInterval(-7200),
                            endDate: .now.addingTimeInterval(-3600), source: .manual)
        let attendance = Attendance(student: student, lesson: lesson, status: .present)
        for model in [group as any PersistentModel, student, lesson, attendance] {
            context.insert(model)
        }
        try context.save()
        #expect(throws: LessonBillingService.BillingError.historicalLesson) {
            try LessonBillingService.ensureCanDelete(lesson, context: context)
        }
    }

    @Test @MainActor
    func qaDeletingScheduleRuleRemovesFutureGeneratedLessons() throws {
        let context = try context()
        let today = Calendar.current.startOfDay(for: .now)
        let nextWeek = try #require(Calendar.current.date(byAdding: .day, value: 7, to: today))
        let weekday = try #require(Weekday(
            rawValue: Calendar.current.component(.weekday, from: today)
        ))
        let group = Group(name: "QA Deleted Schedule", revenueModel: .perStudent)
        group.ratePerStudent = 15
        let rule = ScheduleRule(group: group, weekday: weekday,
                                startHour: 17, startMinute: 0, durationMinutes: 60)
        context.insert(group)
        context.insert(rule)
        try context.save()

        LessonGenerator.generateLessons(from: today, through: nextWeek, context: context)
        #expect(try context.fetch(FetchDescriptor<Lesson>()).count == 2)
        LessonGenerator.removeFutureLessons(for: rule, from: today, context: context)
        rule.isActive = false
        try context.save()
        #expect(try context.fetch(FetchDescriptor<Lesson>()).isEmpty)
        LessonGenerator.generateLessons(from: today, through: nextWeek, context: context)
        #expect(try context.fetch(FetchDescriptor<Lesson>()).isEmpty)
    }

    @Test @MainActor
    func qaArchivingStudentEndsEnrollmentButPreservesPastAttendance() throws {
        let context = try context()
        let group = Group(name: "Archive QA", revenueModel: .perStudent)
        let student = Student(firstName: "Archive", lastName: "QA")
        let enrollment = Enrollment(student: student, group: group, lessonPrice: 15)
        let past = Lesson(group: group, startDate: .now.addingTimeInterval(-7200),
                          endDate: .now.addingTimeInterval(-3600), source: .manual)
        enrollment.enrollmentDate = past.startDate.addingTimeInterval(-3600)
        let attendance = Attendance(student: student, lesson: past, status: .present)
        for model in [group as any PersistentModel, student, enrollment, past, attendance] {
            context.insert(model)
        }
        try context.save()
        try StudentService(context: context).archiveStudent(student)
        #expect(!student.isActive)
        #expect(!enrollment.isActive)
        #expect(enrollment.endDate != nil)
        #expect(try context.fetch(FetchDescriptor<Attendance>()).count == 1)
    }

    @Test @MainActor
    func qaArchivingGroupRemovesOnlyFutureUnrecordedLessons() throws {
        let context = try context()
        let group = Group(name: "Archive QA", revenueModel: .fixedPerLesson)
        group.fixedLessonRate = 100
        let past = Lesson(group: group, startDate: .now.addingTimeInterval(-7200),
                          endDate: .now.addingTimeInterval(-3600), source: .manual)
        past.status = .completed
        let future = Lesson(group: group, startDate: .now.addingTimeInterval(7200),
                            endDate: .now.addingTimeInterval(10800), source: .manual)
        let ongoing = Lesson(group: group, startDate: .now.addingTimeInterval(-60),
                             endDate: .now.addingTimeInterval(3600), source: .manual)
        context.insert(group)
        context.insert(past)
        context.insert(future)
        context.insert(ongoing)
        try context.save()
        try GroupService(context: context).archiveGroup(group)
        let remaining = try context.fetch(FetchDescriptor<Lesson>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.uuid == past.uuid)
    }

    @Test @MainActor
    func qaFixedOrganizationLessonWithoutStudentsCancelsAndClearsDebt() throws {
        let context = try context()
        let organization = Organization(name: "Fixed QA", type: .school)
        let group = Group(name: "No enrollment", revenueModel: .fixedPerLesson,
                          organization: organization)
        group.fixedLessonRate = 100
        let lesson = Lesson(group: group, startDate: .now.addingTimeInterval(-7200),
                            endDate: .now.addingTimeInterval(-3600), source: .manual)
        context.insert(organization)
        context.insert(group)
        context.insert(lesson)
        try context.save()

        lesson.status = .completed
        try LessonBillingService.syncCharge(for: lesson, context: context)
        try context.save()
        var entries = AccountLedger.entries(
            organization: organization,
            in: try context.fetch(FetchDescriptor<Transaction>())
        )
        #expect(AccountLedger.summary(entries).debt == 100)

        lesson.status = .cancelled
        try LessonBillingService.syncCharge(for: lesson, context: context)
        try context.save()
        entries = AccountLedger.entries(
            organization: organization,
            in: try context.fetch(FetchDescriptor<Transaction>())
        )
        #expect(AccountLedger.summary(entries).debt == 0)
        #expect(entries.filter { $0.type == .charge }.count == 2)
    }

    @Test @MainActor
    func qaCompletedLessonKeepsRateWhenAttendanceIsCorrectedLater() throws {
        let context = try context()
        let group = Group(name: "Rate QA", revenueModel: .perStudent)
        group.ratePerStudent = 10
        let student = Student(firstName: "Rate", lastName: "QA")
        let enrollment = Enrollment(student: student, group: group, lessonPrice: 10)
        let lesson = Lesson(group: group, startDate: .now.addingTimeInterval(-7200),
                            endDate: .now.addingTimeInterval(-3600), source: .manual)
        enrollment.enrollmentDate = lesson.startDate.addingTimeInterval(-3600)
        let attendance = Attendance(student: student, lesson: lesson, status: .absent)
        for model in [group as any PersistentModel, student, enrollment, lesson, attendance] {
            context.insert(model)
        }
        try context.save()

        lesson.status = .completed
        try LessonBillingService.syncCharge(for: lesson, context: context)
        group.ratePerStudent = 15
        attendance.status = .present
        try LessonBillingService.syncCharge(for: lesson, context: context)
        try context.save()
        #expect(lesson.billedRate == 10)
        let charges = try context.fetch(FetchDescriptor<Transaction>())
        #expect(charges.count == 1)
        #expect(charges.first?.amount == 10)
    }
}
