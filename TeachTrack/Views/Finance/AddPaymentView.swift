import SwiftUI
import SwiftData

struct AddPaymentView: View {
    let student: Student?
    let organization: Organization?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query(sort: \Student.lastName) private var students: [Student]
    @Query(sort: \Organization.name) private var organizations: [Organization]

    @State private var accountID = ""
    @State private var kind: TransactionType
    @State private var amount = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var saveErrorMessage: String?

    init(
        student: Student? = nil,
        organization: Organization? = nil,
        kind: TransactionType = .payment
    ) {
        self.student = student
        self.organization = organization
        _kind = State(initialValue: kind)
    }

    private var selectedAccount: String {
        if let student { return "student:\(student.uuid)" }
        if let organization { return "organization:\(organization.uuid)" }
        return accountID
    }

    private var parsedAmount: Decimal? {
        Decimal(string: amount.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Payer") {
                    if let student {
                        Text("\(student.firstName) \(student.lastName)")
                    } else if let organization {
                        Text(organization.name)
                    } else {
                        Picker("Student or Organization", selection: $accountID) {
                            Text("Select payer").tag("")
                            ForEach(students.filter(\.isActive), id: \.uuid) { student in
                                Text("\(student.lastName) \(student.firstName)")
                                    .tag("student:\(student.uuid)")
                            }
                            ForEach(organizations.filter(\.isActive), id: \.uuid) { organization in
                                Text(organization.name)
                                    .tag("organization:\(organization.uuid)")
                            }
                        }
                    }
                }

                Section("Receipt") {
                    Picker("Type", selection: $kind) {
                        Text("Payment").tag(TransactionType.payment)
                        Text("Deposit").tag(TransactionType.deposit)
                    }
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    DatePicker("Received", selection: $date)
                    TextField("Notes", text: $notes, axis: .vertical)
                }

                Text("Payments and deposits cover the oldest unpaid lessons first. Any remainder stays as a deposit.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .teachTrackScreen()
            .navigationTitle(kind == .deposit ? "Add Deposit" : "Record Payment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(selectedAccount.isEmpty || parsedAmount.map { $0 <= 0 } != false)
                }
            }
        }
        .alert("Unable to Save Receipt", isPresented: Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { saveErrorMessage = nil }
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    private func save() {
        guard let value = parsedAmount, value > 0 else { return }
        let entry = Transaction(amount: value, type: kind)
        entry.date = date
        entry.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let student = student ?? students.first(where: {
            selectedAccount == "student:\($0.uuid)"
        }) {
            entry.student = student
        } else if let organization = organization ?? organizations.first(where: {
            selectedAccount == "organization:\($0.uuid)"
        }) {
            entry.organization = organization
        } else {
            return
        }

        context.insert(entry)
        do {
            try context.save()
            dismiss()
        } catch {
            context.rollback()
            saveErrorMessage = error.localizedDescription
        }
    }
}
