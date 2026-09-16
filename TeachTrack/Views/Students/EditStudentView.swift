import SwiftUI
import SwiftData

struct EditStudentView: View {

    let student: Student

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    @State
    private var firstName: String

    @State
    private var lastName: String

    @State
    private var phone: String

    @State
    private var email: String

    init(student: Student) {
        self.student = student

        _firstName = State(
            initialValue: student.firstName
        )

        _lastName = State(
            initialValue: student.lastName
        )

        _phone = State(
            initialValue: student.phone ?? ""
        )

        _email = State(
            initialValue: student.email ?? ""
        )
    }

    var body: some View {

        NavigationStack {

            Form {

                Section("Student") {

                    TextField(
                        "First Name",
                        text: $firstName
                    )

                    TextField(
                        "Last Name",
                        text: $lastName
                    )

                    TextField(
                        "Phone",
                        text: $phone
                    )
                    .keyboardType(.phonePad)

                    TextField(
                        "Email",
                        text: $email
                    )
                    .keyboardType(.emailAddress)
                }
            }
            .navigationTitle("Edit Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {
                    Button("Save") {

                        student.firstName =
                            firstName.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )

                        student.lastName =
                            lastName.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )

                        student.phone =
                            phone.isEmpty ? nil : phone

                        student.email =
                            email.isEmpty ? nil : email

                        try? context.save()

                        dismiss()
                    }
                    .disabled(
                        firstName.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty ||
                        lastName.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                }
            }
        }
    }
}
