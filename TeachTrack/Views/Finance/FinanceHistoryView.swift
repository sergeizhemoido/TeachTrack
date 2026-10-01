import SwiftUI
import SwiftData

struct FinanceHistoryView: View {
    let range: ReportDateRange?

    init(range: ReportDateRange? = nil) {
        self.range = range
    }

    @Query(sort: \Transaction.date, order: .reverse)
    private var transactions: [Transaction]

    private var visibleTransactions: [Transaction] {
        transactions.filter { range?.contains($0.date) ?? true }
    }

    var body: some View {
        List {
            if visibleTransactions.isEmpty {
                ContentUnavailableView(
                    "No Transactions",
                    systemImage: "list.bullet.rectangle",
                    description: Text("No payments or charges were recorded in this period.")
                )
            }
            ForEach(visibleTransactions, id: \.uuid) { transaction in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(transaction.type.rawValue.capitalized)
                        Spacer()
                        Text(transaction.amount.formatted())
                    }
                    Text(transaction.student.map { "\($0.lastName) \($0.firstName)" }
                        ?? transaction.organization?.name ?? "Unassigned")
                        .font(.subheadline)
                    if let lesson = transaction.lesson {
                        Text("Lesson: \(lesson.startDate.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                    }
                    Text(transaction.date, format: .dateTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let notes = transaction.notes, !notes.isEmpty {
                        Text(notes).font(.caption)
                    }
                }
            }
        }
        .teachTrackScreen()
        .navigationTitle("Transactions")
    }
}
