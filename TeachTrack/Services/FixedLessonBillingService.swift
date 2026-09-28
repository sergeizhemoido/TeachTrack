import Foundation
import SwiftData

@MainActor
enum FixedLessonBillingService {

    enum BillingError: LocalizedError {
        case missingRate
        case missingOrganization

        var errorDescription: String? {
            switch self {
            case .missingRate:
                return "Set a fixed lesson rate before completing this lesson."
            case .missingOrganization:
                return "This group must belong to an organization before billing."
            }
        }
    }

    static func syncCharge(for lesson: Lesson, context: ModelContext) throws {
        guard lesson.group.revenueModel == .fixedPerLesson else { return }

        let charges = try charges(for: lesson, context: context)

        guard lesson.status == .completed else {
            charges.forEach { context.delete($0) }
            return
        }

        guard let rate = lesson.group.fixedLessonRate else {
            throw BillingError.missingRate
        }
        guard let organization = lesson.group.organization else {
            throw BillingError.missingOrganization
        }

        if let charge = charges.first {
            charge.date = lesson.startDate
            charge.organization = organization
            for duplicate in charges.dropFirst() {
                context.delete(duplicate)
            }
        } else {
            let charge = Transaction(amount: rate, type: .charge)
            charge.date = lesson.startDate
            charge.organization = organization
            charge.lesson = lesson
            context.insert(charge)
        }
    }

    static func removeCharge(for lesson: Lesson, context: ModelContext) throws {
        guard lesson.group.revenueModel == .fixedPerLesson else { return }
        for charge in try charges(for: lesson, context: context) {
            context.delete(charge)
        }
    }

    private static func charges(
        for lesson: Lesson,
        context: ModelContext
    ) throws -> [Transaction] {
        let transactions = try context.fetch(FetchDescriptor<Transaction>())
        return transactions.filter {
            $0.type == .charge &&
            $0.lesson?.uuid == lesson.uuid &&
            $0.student == nil
        }
    }
}
