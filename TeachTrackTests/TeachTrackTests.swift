import Foundation
import SwiftData
import Testing
@testable import TeachTrack

struct TeachTrackTests {
    @MainActor
    private func context() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Organization.self, Group.self, Student.self, Enrollment.self,
            Lesson.self, Attendance.self, AttendanceRevision.self, Transaction.self,
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
        #expect(throws: LessonBillingService.BillingError.incompleteAttendance) {
            try LessonBillingService.syncCharge(for: lesson, context: context)
        }

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
        #expect(ReportVisibility.lessons([past, future], now: now).count == 1)

        organization.isActive = false
        #expect(ReportVisibility.attendances(records, now: now).isEmpty)
        #expect(ReportVisibility.lessons([past, future], now: now).isEmpty)
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
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
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

        try DatabaseSnapshot.clear(context)
        #expect(try context.fetch(FetchDescriptor<Student>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Transaction>()).isEmpty)
        try decoded.restore(into: context)

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
}
