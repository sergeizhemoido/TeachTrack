import SwiftUI
import SwiftData

struct FinanceDashboardView: View {
    @Query private var transactions: [Transaction]
    @Query private var students: [Student]
    @Query private var organizations: [Organization]

    @State private var receiptKind: TransactionType?

    private var totalPayments: Decimal {
        transactions.filter { $0.type == .payment || $0.type == .deposit }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var totalCharges: Decimal {
        transactions.filter { $0.type == .charge }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var totalUnpaid: Decimal {
        studentDebts.reduce(Decimal.zero) { $0 + $1.1 }
            + organizationDebts.reduce(Decimal.zero) { $0 + $1.1 }
    }

    private var studentDebts: [(Student, Decimal)] {
        students.compactMap { student in
            let debt = AccountLedger.summary(
                AccountLedger.entries(for: student, in: transactions)
            ).debt
            return debt > 0 ? (student, debt) : nil
        }.sorted { $0.0.lastName < $1.0.lastName }
    }

    private var organizationDebts: [(Organization, Decimal)] {
        organizations.compactMap { organization in
            let debt = AccountLedger.summary(
                AccountLedger.entries(organization: organization, in: transactions)
            ).debt
            return debt > 0 ? (organization, debt) : nil
        }.sorted { $0.0.name < $1.0.name }
    }

    var body: some View {
        List {
            TeachTrackHero(
                eyebrow: "Financial overview",
                title: "Know where you stand",
                detail: "Receipts, charges, and balances across your teaching business.",
                symbol: "chart.line.uptrend.xyaxis",
                color: TeachTrackDesign.sunflower
            )

            Section("Overview") {
                HStack(spacing: 12) {
                    TeachTrackMetric(
                        title: "Received",
                        value: totalPayments.formatted(),
                        symbol: "arrow.down.left.circle.fill",
                        color: TeachTrackDesign.positive
                    )
                    TeachTrackMetric(
                        title: "Charges",
                        value: totalCharges.formatted(),
                        symbol: "doc.text.fill",
                        color: TeachTrackDesign.blue,
                        valueID: "financeTotalCharges"
                    )
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)

                TeachTrackMetric(
                    title: "Unpaid",
                    value: totalUnpaid.formatted(),
                    symbol: "exclamationmark.circle.fill",
                    color: TeachTrackDesign.warning
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
            }

            Section("Unpaid by Student") {
                if studentDebts.isEmpty {
                    Text("No unpaid student balances")
                        .foregroundStyle(.secondary)
                }
                ForEach(studentDebts, id: \.0.uuid) { student, debt in
                    NavigationLink {
                        AccountStatementView(student: student)
                    } label: {
                        HStack {
                            TeachTrackIconRow(
                                title: "\(student.lastName) \(student.firstName)",
                                detail: "Student",
                                symbol: "person.crop.circle",
                                color: TeachTrackDesign.warning
                            )
                            Spacer()
                            Text(debt.formatted())
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(TeachTrackDesign.warning)
                        }
                    }
                }
            }

            Section("Unpaid by Organization") {
                if organizationDebts.isEmpty {
                    Text("No unpaid organization balances")
                        .foregroundStyle(.secondary)
                }
                ForEach(organizationDebts, id: \.0.uuid) { organization, debt in
                    NavigationLink {
                        AccountStatementView(organization: organization)
                    } label: {
                        HStack {
                            TeachTrackIconRow(
                                title: organization.name,
                                detail: "Organization",
                                symbol: organization.type.displaySymbol,
                                color: TeachTrackDesign.warning
                            )
                            Spacer()
                            Text(debt.formatted())
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(TeachTrackDesign.warning)
                        }
                    }
                }
            }

            NavigationLink {
                FinanceHistoryView()
            } label: {
                TeachTrackIconRow(
                    title: "All Transactions",
                    detail: "Browse payments, deposits, and charges",
                    symbol: "list.bullet.rectangle",
                    color: TeachTrackDesign.blue
                )
            }
            .accessibilityLabel("All Transactions")
        }
        .teachTrackScreen()
        .navigationTitle("Finance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Menu {
                Button("Record Payment") { receiptKind = .payment }
                Button("Add Deposit") { receiptKind = .deposit }
            } label: {
                Label("Add Receipt", systemImage: "plus")
            }
        }
        .sheet(item: $receiptKind) { kind in
            AddPaymentView(kind: kind)
        }
    }
}
