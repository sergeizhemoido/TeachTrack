import Foundation

struct OutstandingCharge: Identifiable {
    let id: UUID
    let lesson: Lesson?
    let charged: Decimal
    let unpaid: Decimal
}

struct AccountSummary {
    let charges: Decimal
    let credits: Decimal
    let outstanding: [OutstandingCharge]

    var debt: Decimal { max(charges - credits, 0) }
    var depositBalance: Decimal { max(credits - charges, 0) }
}

enum AccountLedger {
    static func entries(
        for student: Student? = nil,
        organization: Organization? = nil,
        in transactions: [Transaction]
    ) -> [Transaction] {
        transactions.filter { transaction in
            if let student {
                return transaction.student?.uuid == student.uuid
            }
            if let organization {
                return transaction.student == nil &&
                    transaction.organization?.uuid == organization.uuid
            }
            return false
        }
    }

    static func summary(_ entries: [Transaction]) -> AccountSummary {
        let credits = entries.reduce(Decimal.zero) { total, entry in
            switch entry.type {
            case .payment, .deposit, .adjustment:
                return total + entry.amount
            case .refund:
                return total - entry.amount
            case .charge:
                return total
            }
        }

        let charges = entries.filter { $0.type == .charge }
        let grouped = Dictionary(grouping: charges) {
            $0.lesson?.uuid ?? $0.uuid
        }
        let netCharges = grouped.compactMap { key, group -> (UUID, Lesson?, Decimal)? in
            let amount = group.reduce(Decimal.zero) { $0 + $1.amount }
            guard amount > 0 else { return nil }
            return (key, group.first?.lesson, amount)
        }.sorted {
            let left = $0.1?.startDate ?? .distantPast
            let right = $1.1?.startDate ?? .distantPast
            return left == right ? $0.0.uuidString < $1.0.uuidString : left < right
        }

        var available = max(credits, 0)
        let unpaid = netCharges.compactMap { key, lesson, amount -> OutstandingCharge? in
            let covered = min(amount, available)
            available -= covered
            let remainder = amount - covered
            guard remainder > 0 else { return nil }
            return OutstandingCharge(
                id: key,
                lesson: lesson,
                charged: amount,
                unpaid: remainder
            )
        }

        let totalCharges = netCharges.reduce(Decimal.zero) { $0 + $1.2 }
        return AccountSummary(
            charges: totalCharges,
            credits: credits,
            outstanding: unpaid
        )
    }
}
