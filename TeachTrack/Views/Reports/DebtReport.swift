import SwiftUI
import SwiftData

struct DebtReportView: View {
    let range: ReportDateRange?

    init(range: ReportDateRange? = nil) {
        self.range = range
    }

    @Query private var students: [Student]
    @Query private var organizations: [Organization]
    @Query private var transactions: [Transaction]

    @State private var includeArchived = false

    private var unpaidStudents: [(Student, Decimal)] {
        students.filter { includeArchived || $0.isActive }.compactMap { student in
            let amount = ReportDebtCalculator.unpaid(
                entries: AccountLedger.entries(for: student, in: transactions),
                range: range
            )
            return amount > 0 ? (student, amount) : nil
        }.sorted { $0.1 > $1.1 }
    }

    private var unpaidOrganizations: [(Organization, Decimal)] {
        organizations.filter { includeArchived || $0.isActive }.compactMap { organization in
            let amount = ReportDebtCalculator.unpaid(
                entries: AccountLedger.entries(organization: organization, in: transactions),
                range: range
            )
            return amount > 0 ? (organization, amount) : nil
        }.sorted { $0.1 > $1.1 }
    }

    private var explanation: String {
        if range != nil {
            return "Lesson charges in the selected period, less payments and deposits received by its end. Open an account for its full history."
        }
        return "Lesson charges less payments and deposits received. Open an account to review its full history."
    }

    var body: some View {
        List {
            TeachTrackHero(
                eyebrow: "Payment follow-up",
                title: "See what is still due",
                detail: explanation,
                symbol: "creditcard.fill",
                color: TeachTrackDesign.sunflower
            )

            Section("View Options") {
                Toggle("Include Archived Accounts", isOn: $includeArchived)
            }
            Section("Students · \(unpaidStudents.count)") {
                if unpaidStudents.isEmpty {
                    Text("No unpaid student balances")
                        .foregroundStyle(.secondary)
                }
                ForEach(unpaidStudents.indices, id: \.self) { index in
                    let item = unpaidStudents[index]
                    NavigationLink {
                        AccountStatementView(student: item.0)
                    } label: {
                        HStack {
                            TeachTrackIconRow(
                                title: "\(item.0.lastName) \(item.0.firstName)",
                                detail: "Student account",
                                symbol: "person.crop.circle",
                                color: TeachTrackDesign.warning
                            )
                            Spacer()
                            Text(item.1.moneyFormatted)
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(TeachTrackDesign.warning)
                        }
                    }
                }
            }
            Section("Organizations · \(unpaidOrganizations.count)") {
                if unpaidOrganizations.isEmpty {
                    Text("No unpaid organization balances")
                        .foregroundStyle(.secondary)
                }
                ForEach(unpaidOrganizations.indices, id: \.self) { index in
                    let item = unpaidOrganizations[index]
                    NavigationLink {
                        AccountStatementView(organization: item.0)
                    } label: {
                        HStack {
                            TeachTrackIconRow(
                                title: item.0.name,
                                detail: "Organization account",
                                symbol: item.0.type.displaySymbol,
                                color: TeachTrackDesign.warning
                            )
                            Spacer()
                            Text(item.1.moneyFormatted)
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(TeachTrackDesign.warning)
                        }
                    }
                }
            }
        }
        .teachTrackScreen()
        .navigationTitle("Unpaid Balances")
    }
}
