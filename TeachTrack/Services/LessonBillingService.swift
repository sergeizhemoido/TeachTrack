import Foundation
import SwiftData

/// Reconciles lesson charges with signed entries so corrections retain history.
@MainActor
enum LessonBillingService {

    enum BillingError: LocalizedError, Equatable {
        case missingRate
        case missingOrganization
        case incompleteAttendance
        case noStudents
        case historicalLesson

        var errorDescription: String? {
            switch self {
            case .missingRate:
                return "Set a lesson rate before completing the lesson."
            case .missingOrganization:
                return "The group must belong to an organization."
            case .incompleteAttendance:
                return "Mark attendance for every enrolled student before completing the lesson."
            case .noStudents:
                return "Enroll at least one student before completing the lesson."
            case .historicalLesson:
                return "A lesson with attendance or financial history cannot be deleted. Cancel it instead."
            }
        }
    }

    static func syncCharge(for lesson: Lesson, context: ModelContext) throws {
        let priorCharges = try context.fetch(FetchDescriptor<Transaction>())
            .filter { $0.type == .charge && $0.lesson?.uuid == lesson.uuid }

        var desired: [UUID: (student: Student?, organization: Organization?, amount: Decimal)] = [:]

        if lesson.status == .completed {
            try validateAttendance(for: lesson, context: context)

            switch lesson.group.revenueModel {
            case .fixedPerLesson:
                guard let rate = lesson.billedRate ?? lesson.group.fixedLessonRate else {
                    throw BillingError.missingRate
                }
                if lesson.billedRate == nil { lesson.billedRate = rate }
                guard let organization = lesson.group.organization else {
                    throw BillingError.missingOrganization
                }
                desired[organization.uuid] = (nil, organization, rate)

            case .organizationPerAttendee:
                guard let rate = lesson.billedRate ?? lesson.group.organizationAttendanceRate else {
                    throw BillingError.missingRate
                }
                if lesson.billedRate == nil { lesson.billedRate = rate }
                guard let organization = lesson.group.organization else {
                    throw BillingError.missingOrganization
                }
                let enrolledStudents = Set(try context.fetch(FetchDescriptor<Enrollment>())
                    .filter {
                        $0.group.uuid == lesson.group.uuid &&
                        $0.enrollmentDate <= lesson.endDate &&
                        ($0.endDate == nil || $0.endDate! >= lesson.startDate)
                    }.map { $0.student.uuid })
                let presentStudents = Set(lesson.attendances
                    .filter { $0.status == .present && enrolledStudents.contains($0.student.uuid) }
                    .map { $0.student.uuid })
                desired[organization.uuid] = (
                    nil,
                    organization,
                    rate * Decimal(presentStudents.count)
                )

            case .perStudent:
                let enrollments = try context.fetch(FetchDescriptor<Enrollment>())
                    .filter { $0.group.uuid == lesson.group.uuid }
                for attendance in lesson.attendances where attendance.status.createsCharge {
                    guard let enrollment = enrollments.first(where: {
                        $0.student.uuid == attendance.student.uuid &&
                        $0.enrollmentDate <= lesson.endDate &&
                        ($0.endDate == nil || $0.endDate! >= lesson.startDate)
                    }), let rate = enrollment.lessonPrice ?? lesson.group.ratePerStudent else {
                        throw BillingError.missingRate
                    }
                    desired[attendance.student.uuid] = (attendance.student, nil, rate)
                }
            }
        }

        let priorKeys = Set(priorCharges.compactMap { $0.student?.uuid ?? $0.organization?.uuid })
        for key in priorKeys.union(desired.keys) {
            let entries = priorCharges.filter {
                ($0.student?.uuid ?? $0.organization?.uuid) == key
            }
            let charged = entries.reduce(Decimal.zero) { $0 + $1.amount }
            let target = desired[key]?.amount ?? 0
            let difference = target - charged
            guard difference != 0 else { continue }

            let entry = Transaction(amount: difference, type: .charge)
            entry.lesson = lesson
            entry.date = .now
            entry.student = desired[key]?.student ?? entries.first?.student
            entry.organization = desired[key]?.organization ?? entries.first?.organization
            entry.notes = difference < 0 ? "Lesson charge reversal" : "Lesson charge"
            context.insert(entry)
        }
    }

    static func validateAttendance(for lesson: Lesson, context: ModelContext) throws {
        let enrollments = try context.fetch(FetchDescriptor<Enrollment>())
            .filter {
                $0.group.uuid == lesson.group.uuid &&
                $0.enrollmentDate <= lesson.endDate &&
                ($0.endDate == nil || $0.endDate! >= lesson.startDate)
            }
        let attended = Set(lesson.attendances.map { $0.student.uuid })
        guard !enrollments.isEmpty else { throw BillingError.noStudents }
        guard enrollments.allSatisfy({ attended.contains($0.student.uuid) }) else {
            throw BillingError.incompleteAttendance
        }
    }

    static func ensureCanDelete(_ lesson: Lesson, context: ModelContext) throws {
        guard lesson.status == .planned && lesson.attendances.isEmpty else {
            throw BillingError.historicalLesson
        }
        let transactions = try context.fetch(FetchDescriptor<Transaction>())
        guard !transactions.contains(where: { $0.lesson?.uuid == lesson.uuid }) else {
            throw BillingError.historicalLesson
        }
    }
}
