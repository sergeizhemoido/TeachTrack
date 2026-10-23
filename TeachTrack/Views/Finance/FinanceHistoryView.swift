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

    private func color(for type: TransactionType) -> Color {
        switch type {
        case .payment, .deposit: TeachTrackDesign.positive
        case .charge: TeachTrackDesign.blue
        case .adjustment, .refund: TeachTrackDesign.warning
        }
    }

    private func symbol(for type: TransactionType) -> String {
        switch type {
        case .payment: "arrow.down.left.circle.fill"
        case .deposit: "plus.circle.fill"
        case .charge: "doc.text.fill"
        case .adjustment: "arrow.left.arrow.right.circle.fill"
        case .refund: "arrow.uturn.backward.circle.fill"
        }
    }

    var body: some View {
        List {
            TeachTrackHero(
                eyebrow: "Account activity",
                title: "Follow every payment",
                detail: "See lesson charges, payments, and deposits in date order for every account.",
                symbol: "list.bullet.rectangle",
                color: TeachTrackDesign.sunflower
            )

            Section("Transactions · \(visibleTransactions.count)") {
                if visibleTransactions.isEmpty {
                    ContentUnavailableView(
                        "No Transactions",
                        systemImage: "list.bullet.rectangle",
                        description: Text("No payments or charges were recorded in this period.")
                    )
                }
                ForEach(visibleTransactions, id: \.uuid) { transaction in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Image(systemName: symbol(for: transaction.type))
                                .foregroundStyle(color(for: transaction.type))
                                .frame(width: 28)
                            Text(transaction.type.rawValue.capitalized)
                                .font(.system(.body, design: .rounded, weight: .semibold))
                            Spacer()
                            Text(transaction.amount.moneyFormatted)
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(color(for: transaction.type))
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
        }
        .teachTrackScreen()
        .navigationTitle("Transactions")
    }
}
