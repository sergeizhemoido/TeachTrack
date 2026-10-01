import Foundation

enum ReportDebtCalculator {
    static func unpaid(
        entries: [Transaction],
        range: ReportDateRange?
    ) -> Decimal {
        guard let range else {
            return AccountLedger.summary(entries).debt
        }

        let entriesByEnd = entries.filter { range.occurredByEnd($0.date) }
        let summary = AccountLedger.summary(entriesByEnd)
        return summary.outstanding.reduce(Decimal.zero) { total, charge in
            let date = charge.lesson?.startDate ?? entriesByEnd.first {
                $0.uuid == charge.id
            }?.date
            guard let date, range.contains(date) else { return total }
            return total + charge.unpaid
        }
    }
}
