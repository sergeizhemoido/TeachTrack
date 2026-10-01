import Foundation
import SwiftData

/// A versioned, relationship-safe copy of every persisted TeachTrack model.
struct DatabaseSnapshot: Codable {
    static let currentVersion = 1

    struct OrganizationRow: Codable {
        var id: UUID
        var name: String
        var type: OrganizationType
        var phone: String?
        var email: String?
        var address: String?
        var notes: String?
        var isActive: Bool
    }

    struct StudentRow: Codable {
        var id: UUID
        var firstName: String
        var lastName: String
        var phone: String?
        var email: String?
        var notes: String?
        var type: StudentType
        var isActive: Bool
    }

    struct GroupRow: Codable {
        var id: UUID
        var name: String
        var revenueModel: RevenueModel
        var fixedLessonRate: Decimal?
        var organizationAttendanceRate: Decimal?
        var ratePerStudent: Decimal?
        var notes: String?
        var isActive: Bool
        var organizationID: UUID?
    }

    struct ContactRow: Codable {
        var id: UUID
        var studentID: UUID
        var name: String
        var relationship: String
        var phone: String?
        var email: String?
        var notes: String?
    }

    struct EnrollmentRow: Codable {
        var id: UUID
        var studentID: UUID
        var groupID: UUID
        var lessonPrice: Decimal?
        var enrollmentDate: Date
        var endDate: Date?
        var isActive: Bool
    }

    struct RuleRow: Codable {
        var id: UUID
        var groupID: UUID
        var weekday: Weekday
        var startHour: Int
        var startMinute: Int
        var durationMinutes: Int
        var isActive: Bool
    }

    struct ExceptionRow: Codable {
        var id: UUID
        var ruleID: UUID
        var date: Date
        var isActive: Bool
    }

    struct LessonRow: Codable {
        var id: UUID
        var groupID: UUID
        var startDate: Date
        var endDate: Date
        var status: LessonStatus
        var source: LessonSource
        var generatedRuleID: UUID?
        var isManuallyModified: Bool
        var notes: String?
        var billedRate: Decimal?
    }

    struct AttendanceRow: Codable {
        var id: UUID
        var studentID: UUID
        var lessonID: UUID
        var status: AttendanceStatus
        var makeupSourceID: UUID?
        var notes: String?
    }

    struct RevisionRow: Codable {
        var id: UUID
        var attendanceID: UUID
        var status: AttendanceStatus
        var recordedAt: Date
        var notes: String?
    }

    struct TransactionRow: Codable {
        var id: UUID
        var date: Date
        var type: TransactionType
        var amount: Decimal
        var studentID: UUID?
        var organizationID: UUID?
        var lessonID: UUID?
        var notes: String?
    }

    struct StudentNoteRow: Codable {
        var id: UUID
        var studentID: UUID
        var text: String
        var createdAt: Date
    }

    struct LessonNoteRow: Codable {
        var id: UUID
        var lessonID: UUID
        var text: String
        var createdAt: Date
    }

    var version = currentVersion
    var organizations: [OrganizationRow] = []
    var students: [StudentRow] = []
    var groups: [GroupRow] = []
    var contacts: [ContactRow] = []
    var enrollments: [EnrollmentRow] = []
    var rules: [RuleRow] = []
    var exceptions: [ExceptionRow] = []
    var lessons: [LessonRow] = []
    var attendances: [AttendanceRow] = []
    var revisions: [RevisionRow] = []
    var transactions: [TransactionRow] = []
    var studentNotes: [StudentNoteRow] = []
    var lessonNotes: [LessonNoteRow] = []

    var recordCount: Int {
        organizations.count + students.count + groups.count + contacts.count +
        enrollments.count + rules.count + exceptions.count + lessons.count +
        attendances.count + revisions.count + transactions.count +
        studentNotes.count + lessonNotes.count
    }

    @MainActor
    static func capture(from context: ModelContext) throws -> DatabaseSnapshot {
        var snapshot = DatabaseSnapshot()
        snapshot.organizations = try context.fetch(FetchDescriptor<Organization>()).map {
            OrganizationRow(id: $0.uuid, name: $0.name, type: $0.type, phone: $0.phone,
                            email: $0.email, address: $0.address, notes: $0.notes,
                            isActive: $0.isActive)
        }
        snapshot.students = try context.fetch(FetchDescriptor<Student>()).map {
            StudentRow(id: $0.uuid, firstName: $0.firstName, lastName: $0.lastName,
                       phone: $0.phone, email: $0.email, notes: $0.notes,
                       type: $0.studentType, isActive: $0.isActive)
        }
        snapshot.groups = try context.fetch(FetchDescriptor<Group>()).map {
            GroupRow(id: $0.uuid, name: $0.name, revenueModel: $0.revenueModel,
                     fixedLessonRate: $0.fixedLessonRate,
                     organizationAttendanceRate: $0.organizationAttendanceRate,
                     ratePerStudent: $0.ratePerStudent, notes: $0.notes,
                     isActive: $0.isActive, organizationID: $0.organization?.uuid)
        }
        snapshot.contacts = try context.fetch(FetchDescriptor<Contact>()).map {
            ContactRow(id: $0.uuid, studentID: $0.student.uuid, name: $0.name,
                       relationship: $0.relationship, phone: $0.phone,
                       email: $0.email, notes: $0.notes)
        }
        snapshot.enrollments = try context.fetch(FetchDescriptor<Enrollment>()).map {
            EnrollmentRow(id: $0.uuid, studentID: $0.student.uuid, groupID: $0.group.uuid,
                          lessonPrice: $0.lessonPrice, enrollmentDate: $0.enrollmentDate,
                          endDate: $0.endDate, isActive: $0.isActive)
        }
        snapshot.rules = try context.fetch(FetchDescriptor<ScheduleRule>()).map {
            RuleRow(id: $0.uuid, groupID: $0.group.uuid, weekday: $0.weekday,
                    startHour: $0.startHour, startMinute: $0.startMinute,
                    durationMinutes: $0.durationMinutes, isActive: $0.isActive)
        }
        snapshot.exceptions = try context.fetch(FetchDescriptor<ScheduleException>()).map {
            ExceptionRow(id: $0.uuid, ruleID: $0.rule.uuid, date: $0.date,
                         isActive: $0.isActive)
        }
        snapshot.lessons = try context.fetch(FetchDescriptor<Lesson>()).map {
            LessonRow(id: $0.uuid, groupID: $0.group.uuid, startDate: $0.startDate,
                      endDate: $0.endDate, status: $0.status, source: $0.source,
                      generatedRuleID: $0.generatedFromRule?.uuid,
                      isManuallyModified: $0.isManuallyModified, notes: $0.notes,
                      billedRate: $0.billedRate)
        }
        snapshot.attendances = try context.fetch(FetchDescriptor<Attendance>()).map {
            AttendanceRow(id: $0.uuid, studentID: $0.student.uuid, lessonID: $0.lesson.uuid,
                          status: $0.status, makeupSourceID: $0.makeupSourceAttendance?.uuid,
                          notes: $0.notes)
        }
        snapshot.revisions = try context.fetch(FetchDescriptor<AttendanceRevision>()).map {
            RevisionRow(id: $0.uuid, attendanceID: $0.attendance.uuid,
                        status: $0.status, recordedAt: $0.recordedAt, notes: $0.notes)
        }
        snapshot.transactions = try context.fetch(FetchDescriptor<Transaction>()).map {
            TransactionRow(id: $0.uuid, date: $0.date, type: $0.type, amount: $0.amount,
                           studentID: $0.student?.uuid, organizationID: $0.organization?.uuid,
                           lessonID: $0.lesson?.uuid, notes: $0.notes)
        }
        snapshot.studentNotes = try context.fetch(FetchDescriptor<StudentNote>()).map {
            StudentNoteRow(id: $0.uuid, studentID: $0.student.uuid,
                           text: $0.text, createdAt: $0.createdAt)
        }
        snapshot.lessonNotes = try context.fetch(FetchDescriptor<LessonNote>()).map {
            LessonNoteRow(id: $0.uuid, lessonID: $0.lesson.uuid,
                          text: $0.text, createdAt: $0.createdAt)
        }
        return snapshot
    }

    enum SnapshotError: LocalizedError {
        case unsupportedVersion(Int)
        case missingRelationship(String)

        var errorDescription: String? {
            switch self {
            case .unsupportedVersion(let version):
                "This backup uses unsupported format version \(version)."
            case .missingRelationship(let relation):
                "The backup is incomplete: \(relation)."
            }
        }
    }

    private func require<T>(_ value: T?, _ relation: String) throws -> T {
        guard let value else { throw SnapshotError.missingRelationship(relation) }
        return value
    }

    /// Validate references before any live models are removed.
    func validate() throws {
        guard version == Self.currentVersion else {
            throw SnapshotError.unsupportedVersion(version)
        }
        let organizationIDs = Set(organizations.map(\.id))
        let studentIDs = Set(students.map(\.id))
        let groupIDs = Set(groups.map(\.id))
        let ruleIDs = Set(rules.map(\.id))
        let lessonIDs = Set(lessons.map(\.id))
        let attendanceIDs = Set(attendances.map(\.id))

        for row in groups where row.organizationID != nil {
            guard organizationIDs.contains(row.organizationID!) else {
                throw SnapshotError.missingRelationship("group organization")
            }
        }
        for row in contacts { guard studentIDs.contains(row.studentID) else {
            throw SnapshotError.missingRelationship("contact student")
        } }
        for row in enrollments { guard studentIDs.contains(row.studentID) && groupIDs.contains(row.groupID) else {
            throw SnapshotError.missingRelationship("enrollment")
        } }
        for row in rules { guard groupIDs.contains(row.groupID) else {
            throw SnapshotError.missingRelationship("schedule group")
        } }
        for row in exceptions { guard ruleIDs.contains(row.ruleID) else {
            throw SnapshotError.missingRelationship("schedule exception rule")
        } }
        for row in lessons {
            guard groupIDs.contains(row.groupID) &&
                    (row.generatedRuleID == nil || ruleIDs.contains(row.generatedRuleID!)) else {
                throw SnapshotError.missingRelationship("lesson")
            }
        }
        for row in attendances {
            guard studentIDs.contains(row.studentID) && lessonIDs.contains(row.lessonID) &&
                    (row.makeupSourceID == nil || attendanceIDs.contains(row.makeupSourceID!)) else {
                throw SnapshotError.missingRelationship("attendance")
            }
        }
        for row in revisions { guard attendanceIDs.contains(row.attendanceID) else {
            throw SnapshotError.missingRelationship("attendance revision")
        } }
        for row in transactions {
            guard (row.studentID == nil || studentIDs.contains(row.studentID!)) &&
                    (row.organizationID == nil || organizationIDs.contains(row.organizationID!)) &&
                    (row.lessonID == nil || lessonIDs.contains(row.lessonID!)) else {
                throw SnapshotError.missingRelationship("transaction")
            }
        }
        for row in studentNotes { guard studentIDs.contains(row.studentID) else {
            throw SnapshotError.missingRelationship("student note")
        } }
        for row in lessonNotes { guard lessonIDs.contains(row.lessonID) else {
            throw SnapshotError.missingRelationship("lesson note")
        } }
    }

    @MainActor
    private static func deleteAll(_ context: ModelContext) throws {
        try delete(AttendanceRevision.self, from: context)
        try delete(Attendance.self, from: context)
        try delete(Transaction.self, from: context)
        try delete(Contact.self, from: context)
        try delete(Enrollment.self, from: context)
        try delete(StudentNote.self, from: context)
        try delete(LessonNote.self, from: context)
        try delete(ScheduleException.self, from: context)
        try delete(Lesson.self, from: context)
        try delete(ScheduleRule.self, from: context)
        try delete(Group.self, from: context)
        try delete(Student.self, from: context)
        try delete(Organization.self, from: context)
    }

    @MainActor
    private static func delete<T: PersistentModel>(_ type: T.Type, from context: ModelContext) throws {
        for model in try context.fetch(FetchDescriptor<T>()) {
            context.delete(model)
        }
    }

    @MainActor
    static func clear(_ context: ModelContext) throws {
        do {
            try deleteAll(context)
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    @MainActor
    func restore(into context: ModelContext) throws {
        try validate()
        var didSave = false
        defer { if !didSave { context.rollback() } }
        try Self.deleteAll(context)

        var organizationsByID: [UUID: Organization] = [:]
        for row in organizations {
            let model = Organization(name: row.name, type: row.type)
            model.uuid = row.id
            model.phone = row.phone
            model.email = row.email
            model.address = row.address
            model.notes = row.notes
            model.isActive = row.isActive
            context.insert(model)
            organizationsByID[row.id] = model
        }

        var studentsByID: [UUID: Student] = [:]
        for row in students {
            let model = Student(firstName: row.firstName, lastName: row.lastName,
                                studentType: row.type)
            model.uuid = row.id
            model.phone = row.phone
            model.email = row.email
            model.notes = row.notes
            model.isActive = row.isActive
            context.insert(model)
            studentsByID[row.id] = model
        }

        var groupsByID: [UUID: Group] = [:]
        for row in groups {
            let organization = row.organizationID.flatMap { organizationsByID[$0] }
            let model = Group(name: row.name, revenueModel: row.revenueModel,
                              organization: organization)
            model.uuid = row.id
            model.fixedLessonRate = row.fixedLessonRate
            model.organizationAttendanceRate = row.organizationAttendanceRate
            model.ratePerStudent = row.ratePerStudent
            model.notes = row.notes
            model.isActive = row.isActive
            context.insert(model)
            groupsByID[row.id] = model
        }

        var rulesByID: [UUID: ScheduleRule] = [:]
        for row in rules {
            let group = try require(groupsByID[row.groupID], "schedule group")
            let model = ScheduleRule(group: group, weekday: row.weekday,
                                     startHour: row.startHour, startMinute: row.startMinute,
                                     durationMinutes: row.durationMinutes)
            model.uuid = row.id
            model.isActive = row.isActive
            context.insert(model)
            rulesByID[row.id] = model
        }

        for row in exceptions {
            let rule = try require(rulesByID[row.ruleID], "schedule exception rule")
            let model = ScheduleException(rule: rule, date: row.date)
            model.uuid = row.id
            model.isActive = row.isActive
            context.insert(model)
        }

        var lessonsByID: [UUID: Lesson] = [:]
        for row in lessons {
            let group = try require(groupsByID[row.groupID], "lesson group")
            let model = Lesson(group: group, startDate: row.startDate,
                               endDate: row.endDate, source: row.source)
            model.uuid = row.id
            model.status = row.status
            model.generatedFromRule = row.generatedRuleID.flatMap { rulesByID[$0] }
            model.isManuallyModified = row.isManuallyModified
            model.notes = row.notes
            model.billedRate = row.billedRate
            context.insert(model)
            lessonsByID[row.id] = model
        }

        for row in contacts {
            let student = try require(studentsByID[row.studentID], "contact student")
            let model = Contact(student: student, name: row.name,
                                relationship: row.relationship)
            model.uuid = row.id
            model.phone = row.phone
            model.email = row.email
            model.notes = row.notes
            context.insert(model)
        }

        for row in enrollments {
            let student = try require(studentsByID[row.studentID], "enrollment student")
            let group = try require(groupsByID[row.groupID], "enrollment group")
            let model = Enrollment(student: student, group: group,
                                   lessonPrice: row.lessonPrice)
            model.uuid = row.id
            model.enrollmentDate = row.enrollmentDate
            model.endDate = row.endDate
            model.isActive = row.isActive
            context.insert(model)
        }

        var attendancesByID: [UUID: Attendance] = [:]
        for row in attendances {
            let student = try require(studentsByID[row.studentID], "attendance student")
            let lesson = try require(lessonsByID[row.lessonID], "attendance lesson")
            let model = Attendance(student: student, lesson: lesson, status: row.status)
            model.uuid = row.id
            model.notes = row.notes
            context.insert(model)
            attendancesByID[row.id] = model
        }
        for row in attendances where row.makeupSourceID != nil {
            attendancesByID[row.id]?.makeupSourceAttendance =
                row.makeupSourceID.flatMap { attendancesByID[$0] }
        }

        for row in revisions {
            let attendance = try require(attendancesByID[row.attendanceID],
                                         "attendance revision")
            let model = AttendanceRevision(attendance: attendance, status: row.status,
                                           notes: row.notes)
            model.uuid = row.id
            model.recordedAt = row.recordedAt
            context.insert(model)
        }

        for row in transactions {
            let model = Transaction(amount: row.amount, type: row.type)
            model.uuid = row.id
            model.date = row.date
            model.student = row.studentID.flatMap { studentsByID[$0] }
            model.organization = row.organizationID.flatMap { organizationsByID[$0] }
            model.lesson = row.lessonID.flatMap { lessonsByID[$0] }
            model.notes = row.notes
            context.insert(model)
        }

        for row in studentNotes {
            let student = try require(studentsByID[row.studentID], "student note")
            let model = StudentNote(student: student, text: row.text)
            model.uuid = row.id
            model.createdAt = row.createdAt
            context.insert(model)
        }

        for row in lessonNotes {
            let lesson = try require(lessonsByID[row.lessonID], "lesson note")
            let model = LessonNote(lesson: lesson, text: row.text)
            model.uuid = row.id
            model.createdAt = row.createdAt
            context.insert(model)
        }

        try context.save()
        didSave = true
    }
}
