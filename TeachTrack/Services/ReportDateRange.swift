import Foundation

struct ReportDateRange {
    let start: Date
    let endExclusive: Date

    init(from firstDay: Date, through lastDay: Date, calendar: Calendar = .current) {
        start = calendar.startOfDay(for: firstDay)
        let lastDayStart = calendar.startOfDay(for: lastDay)
        endExclusive = calendar.date(byAdding: .day, value: 1, to: lastDayStart)
            ?? lastDayStart.addingTimeInterval(86_400)
    }

    func contains(_ date: Date) -> Bool {
        date >= start && date < endExclusive
    }

    func occurredByEnd(_ date: Date) -> Bool {
        date < endExclusive
    }
}
