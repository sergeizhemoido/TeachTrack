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

    var body: some View {
        List {
            Section {
                Toggle("Include Archived Accounts", isOn: $includeArchived)
            } footer: {
                if range != nil {
                    Text("Unpaid lessons in the selected period, after receipts recorded through its end date.")
                } else {
                    Text("Current unpaid balances across all lessons.")
                }
            }
            Section("Students") {
                if unpaidStudents.isEmpty { Text("No unpaid balances") }
                ForEach(unpaidStudents.indices, id: \.self) { index in
                    let item = unpaidStudents[index]
                    NavigationLink {
                        AccountStatementView(student: item.0)
                    } label: {
                        LabeledContent("\(item.0.lastName) \(item.0.firstName)", value: item.1.formatted())
                    }
                }
            }
            Section("Organizations") {
                if unpaidOrganizations.isEmpty { Text("No unpaid balances") }
                ForEach(unpaidOrganizations.indices, id: \.self) { index in
                    let item = unpaidOrganizations[index]
                    NavigationLink {
                        AccountStatementView(organization: item.0)
                    } label: {
                        LabeledContent(item.0.name, value: item.1.formatted())
                    }
                }
            }
        }
        .teachTrackScreen()
        .navigationTitle("Unpaid Balances")
    }
}
