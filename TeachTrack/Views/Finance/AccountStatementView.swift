import SwiftUI
import SwiftData

struct AccountStatementView: View {
    let student: Student?
    let organization: Organization?

    @Query(sort: \Transaction.date, order: .reverse)
    private var allTransactions: [Transaction]

    @State private var receiptKind: TransactionType?
    @State private var useHistoryDateRange = false
    @State private var historyStartDate = Calendar.current.dateInterval(
        of: .month, for: .now
    )?.start ?? .now
    @State private var historyEndDate = Date()

    init(student: Student? = nil, organization: Organization? = nil) {
        self.student = student
        self.organization = organization
    }

    private var transactions: [Transaction] {
        AccountLedger.entries(
            for: student,
            organization: organization,
            in: allTransactions
        )
    }

    private var summary: AccountSummary {
        AccountLedger.summary(transactions)
    }

    private var historyTransactions: [Transaction] {
        guard useHistoryDateRange else { return transactions }
        let range = ReportDateRange(from: historyStartDate, through: historyEndDate)
        return transactions.filter { range.contains($0.date) }
    }

    var body: some View {
        List {
            TeachTrackHero(
                eyebrow: "Account",
                title: student.map { "\($0.firstName) \($0.lastName)" }
                    ?? organization?.name ?? "Account",
                detail: "Current balance and complete transaction history.",
                symbol: "creditcard",
                color: TeachTrackDesign.blue
            )

            Section("Balance") {
                HStack(spacing: 12) {
                    TeachTrackMetric(
                        title: "Unpaid",
                        value: summary.debt.formatted(),
                        symbol: "exclamationmark.circle.fill",
                        color: TeachTrackDesign.warning,
                        valueID: "accountUnpaid"
                    )
                    TeachTrackMetric(
                        title: "Deposit",
                        value: summary.depositBalance.formatted(),
                        symbol: "plus.circle.fill",
                        color: TeachTrackDesign.positive,
                        valueID: "accountDeposit"
                    )
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            }

            if !summary.outstanding.isEmpty {
                Section("Unpaid Lessons") {
                    ForEach(summary.outstanding) { charge in
                        HStack {
                            if let lesson = charge.lesson {
                                NavigationLink {
                                    LessonDetailView(lesson: lesson)
                                } label: {
                                    Text(lesson.startDate, format: .dateTime.day().month().year())
                                }
                            } else {
                                Text("Charge")
                            }
                            Spacer()
                            Text(charge.unpaid.formatted())
                                .foregroundStyle(.red)
                        }
                    }
                }
            }

            Section {
                Toggle("Use Date Range", isOn: $useHistoryDateRange)
                    .accessibilityIdentifier("accountHistoryDateRangeToggle")
                if useHistoryDateRange {
                    DatePicker("From", selection: $historyStartDate, displayedComponents: .date)
                        .accessibilityIdentifier("accountHistoryStartDatePicker")
                    DatePicker("Through", selection: $historyEndDate, displayedComponents: .date)
                        .accessibilityIdentifier("accountHistoryEndDatePicker")
                }
                if historyTransactions.isEmpty {
                    Text(useHistoryDateRange
                        ? "No transactions in this period"
                        : "No transactions")
                        .foregroundStyle(.secondary)
                }
                ForEach(historyTransactions, id: \.uuid) { transaction in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(transaction.type.rawValue.capitalized)
                            Spacer()
                            Text(transaction.amount.formatted())
                        }
                        Text(transaction.date, format: .dateTime)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let lesson = transaction.lesson {
                            Text("Lesson: \(lesson.startDate.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                        }
                        if let notes = transaction.notes, !notes.isEmpty {
                            Text(notes).font(.caption)
                        }
                    }
                }
            } header: {
                Text("Full History")
            } footer: {
                if useHistoryDateRange {
                    Text("Dates filter transaction history only. Balance and unpaid lessons remain current.")
                }
            }
            .onChange(of: historyStartDate) { _, newValue in
                if Calendar.current.startOfDay(for: newValue) >
                    Calendar.current.startOfDay(for: historyEndDate) {
                    historyEndDate = newValue
                }
            }
            .onChange(of: historyEndDate) { _, newValue in
                if Calendar.current.startOfDay(for: newValue) <
                    Calendar.current.startOfDay(for: historyStartDate) {
                    historyStartDate = newValue
                }
            }
        }
        .teachTrackScreen()
        .navigationTitle(student.map { "\($0.firstName) \($0.lastName)" }
            ?? organization?.name ?? "Account")
        .toolbar {
            Menu {
                Button("Record Payment") { receiptKind = .payment }
                Button("Add Deposit") { receiptKind = .deposit }
            } label: {
                Label("Add Receipt", systemImage: "plus")
            }
        }
        .sheet(item: $receiptKind) { kind in
            AddPaymentView(student: student, organization: organization, kind: kind)
        }
    }
}
