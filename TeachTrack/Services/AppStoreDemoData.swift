import Foundation
import SwiftData

/// Fictional, repeatable content used only by the App Store screenshot test.
@MainActor
enum AppStoreDemoData {
    static func populate(_ context: ModelContext, today: Date = .now) throws {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: today)

        func date(_ offset: Int, _ hour: Int, _ minute: Int = 0) -> Date {
            let target = calendar.date(byAdding: .day, value: offset, to: day)!
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: target)!
        }

        let cedar = Organization(name: "Cedar Grove School", type: .school)
        cedar.email = "hello@cedargrove.example"
        cedar.notes = "After-school piano and music classes"
        let littleOaks = Organization(name: "Little Oaks Kindergarten", type: .kindergarten)
        littleOaks.email = "office@littleoaks.example"
        let harbor = Organization(name: "Harbor Arts Academy", type: .school)
        let privateStudio = Organization(name: "Private Lessons", type: .privateClient)
        for organization in [cedar, littleOaks, harbor, privateStudio] {
            context.insert(organization)
        }

        let piano = Group(name: "Piano Foundations", revenueModel: .perStudent,
                          organization: cedar)
        piano.ratePerStudent = 10
        let earlyMusic = Group(name: "Early Music", revenueModel: .fixedPerLesson,
                               organization: littleOaks)
        earlyMusic.fixedLessonRate = 35
        let choir = Group(name: "Choir Workshop", revenueModel: .organizationPerAttendee,
                          organization: harbor)
        choir.organizationAttendanceRate = 10
        let privateGroup = Group(name: "Emma Hayes", revenueModel: .perStudent,
                                 organization: privateStudio)
        privateGroup.ratePerStudent = 15
        for group in [piano, earlyMusic, choir, privateGroup] { context.insert(group) }

        let ava = Student(firstName: "Ava", lastName: "Morgan")
        let noah = Student(firstName: "Noah", lastName: "Rivera")
        let mia = Student(firstName: "Mia", lastName: "Chen")
        let liam = Student(firstName: "Liam", lastName: "Brooks")
        let sophia = Student(firstName: "Sophia", lastName: "Patel")
        let oliver = Student(firstName: "Oliver", lastName: "Reed")
        let emma = Student(firstName: "Emma", lastName: "Hayes", studentType: .privateClient)
        ava.email = "ava.morgan@example.com"
        noah.notes = "Preparing for the spring recital"
        emma.email = "emma.hayes@example.com"
        for student in [ava, noah, mia, liam, sophia, oliver, emma] {
            context.insert(student)
        }

        let parent = Contact(student: ava, name: "Jordan Morgan", relationship: "Parent")
        parent.phone = "555-0101"
        let guardian = Contact(student: sophia, name: "Priya Patel", relationship: "Mother")
        guardian.email = "priya.patel@example.com"
        context.insert(parent)
        context.insert(guardian)

        let members: [(Group, [Student], Decimal?)] = [
            (piano, [ava, noah, mia, liam], 10),
            (earlyMusic, [sophia, oliver], nil),
            (choir, [ava, mia, liam], nil),
            (privateGroup, [emma], 15)
        ]
        var studentsByGroup: [UUID: [Student]] = [:]
        for (group, students, price) in members {
            studentsByGroup[group.uuid] = students
            for student in students {
                let enrollment = Enrollment(student: student, group: group, lessonPrice: price)
                enrollment.enrollmentDate = date(-90, 9)
                context.insert(enrollment)
            }
        }

        let rules: [(Group, Weekday, Int, Int, Int)] = [
            (piano, .monday, 15, 30, 60),
            (piano, .wednesday, 15, 30, 60),
            (earlyMusic, .tuesday, 10, 0, 45),
            (earlyMusic, .friday, 10, 0, 45),
            (choir, .thursday, 16, 0, 60),
            (choir, .saturday, 14, 0, 60),
            (privateGroup, .wednesday, 17, 0, 60),
            (privateGroup, .saturday, 11, 0, 60)
        ]
        for (group, weekday, hour, minute, duration) in rules {
            context.insert(ScheduleRule(group: group, weekday: weekday,
                                        startHour: hour, startMinute: minute,
                                        durationMinutes: duration))
        }
        try context.save()

        LessonGenerator.generateLessons(from: date(-14, 0), through: date(21, 0),
                                        context: context)

        let manualPast = Lesson(group: piano, startDate: date(-2, 17),
                                endDate: date(-2, 18), source: .manual)
        manualPast.notes = "Recital preparation"
        let manualFuture = Lesson(group: choir, startDate: date(2, 14),
                                  endDate: date(2, 15), source: .manual)
        manualFuture.notes = "Extra rehearsal"
        let privatePast = Lesson(group: privateGroup, startDate: date(-5, 16),
                                 endDate: date(-5, 17), source: .manual)
        let privateExtraPast = Lesson(group: privateGroup, startDate: date(-9, 16),
                                      endDate: date(-9, 17), source: .manual)
        let privateFuture = Lesson(group: privateGroup, startDate: date(3, 16),
                                   endDate: date(3, 17), source: .manual)
        context.insert(manualPast)
        context.insert(manualFuture)
        context.insert(privatePast)
        context.insert(privateExtraPast)
        context.insert(privateFuture)
        context.insert(LessonNote(lesson: manualPast, text: "Practice the new duet"))
        try context.save()

        let lessons = try context.fetch(FetchDescriptor<Lesson>(
            sortBy: [SortDescriptor(\Lesson.startDate)]
        ))
        var completedIndex = 0
        var cancelledOne = false
        for lesson in lessons where lesson.endDate < today {
            // One cancellation shows how it differs from a completed lesson.
            if lesson.group.uuid == earlyMusic.uuid && !cancelledOne {
                lesson.status = .cancelled
                cancelledOne = true
                continue
            }
            lesson.status = .completed
            let students = studentsByGroup[lesson.group.uuid] ?? []
            for (index, student) in students.enumerated() {
                let status: AttendanceStatus
                if lesson.group.uuid == choir.uuid && index == 2 {
                    status = .absent
                } else if lesson.group.uuid == piano.uuid && index == 1 && completedIndex % 2 == 0 {
                    status = .absent
                } else if lesson.group.uuid == piano.uuid && index == 2 && completedIndex % 3 == 0 {
                    status = .excused
                } else {
                    status = .present
                }
                let attendance = Attendance(student: student, lesson: lesson, status: status)
                context.insert(attendance)
                if lesson.uuid == manualPast.uuid && index == 0 {
                    context.insert(AttendanceRevision(attendance: attendance,
                                                      status: status, notes: "Confirmed"))
                }
            }
            completedIndex += 1
        }
        try context.save()

        for lesson in lessons where lesson.status == .completed {
            try LessonBillingService.syncCharge(for: lesson, context: context)
        }
        try context.save()
        let charges = try context.fetch(FetchDescriptor<Transaction>())
        for charge in charges where charge.type == .charge {
            if let lesson = charge.lesson { charge.date = lesson.endDate }
        }

        func charged(to student: Student) -> Decimal {
            charges.filter { $0.type == .charge && $0.student?.uuid == student.uuid }
                .reduce(Decimal.zero) { $0 + $1.amount }
        }

        func charged(to organization: Organization) -> Decimal {
            charges.filter { $0.type == .charge && $0.organization?.uuid == organization.uuid }
                .reduce(Decimal.zero) { $0 + $1.amount }
        }

        func receipt(_ type: TransactionType, _ amount: Decimal,
                     student: Student? = nil, organization: Organization? = nil,
                     daysAgo: Int) {
            guard amount > 0 else { return }
            let entry = Transaction(amount: amount, type: type)
            entry.date = date(-daysAgo, 12)
            entry.student = student
            entry.organization = organization
            entry.notes = type == .deposit ? "Account deposit" : "Payment received"
            context.insert(entry)
        }
        let avaPaid = max(charged(to: ava) - 10, 0)
        receipt(.payment, avaPaid / 2, student: ava, daysAgo: 9)
        receipt(.payment, avaPaid / 2, student: ava, daysAgo: 2)
        receipt(.deposit, max(charged(to: noah) - 10, 0), student: noah, daysAgo: 9)
        receipt(.payment, max(charged(to: mia) - 5, 0), student: mia, daysAgo: 1)
        receipt(.payment, max(charged(to: liam) - 5, 0), student: liam, daysAgo: 2)
        let emmaPaid = max(charged(to: emma) - 15, 0)
        let emmaFirstPayment = min(30, emmaPaid)
        receipt(.payment, emmaFirstPayment, student: emma, daysAgo: 9)
        receipt(.payment, emmaPaid - emmaFirstPayment, student: emma, daysAgo: 0)
        let littleOaksPaid = max(charged(to: littleOaks) - 15, 0)
        let littleOaksFirstPayment = min(40, littleOaksPaid)
        receipt(.payment, littleOaksFirstPayment, organization: littleOaks, daysAgo: 7)
        receipt(.payment, littleOaksPaid - littleOaksFirstPayment, organization: littleOaks, daysAgo: 0)
        let harborPaid = max(charged(to: harbor) - 15, 0)
        let harborDeposit = min(25, harborPaid)
        receipt(.deposit, harborDeposit, organization: harbor, daysAgo: 10)
        receipt(.payment, harborPaid - harborDeposit, organization: harbor, daysAgo: 2)
        try context.save()
    }
}
