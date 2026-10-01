import SwiftUI
import SwiftData

struct EditStudentContactView: View {
    let student: Student

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var phone: String
    @State private var email: String
    @State private var notes: String
    @State private var saveError: String?

    init(student: Student) {
        self.student = student
        _phone = State(initialValue: student.phone ?? "")
        _email = State(initialValue: student.email ?? "")
        _notes = State(initialValue: student.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Student Contact") {
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)

                    TextField("Notes", text: $notes, axis: .vertical)
                }
            }
            .teachTrackScreen()
            .navigationTitle("Student Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .alert("Could Not Save Contact", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "Unknown error")
            }
        }
    }

    private func optionalValue(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func save() {
        student.phone = optionalValue(phone)
        student.email = optionalValue(email)
        student.notes = optionalValue(notes)
        do {
            try context.save()
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}
