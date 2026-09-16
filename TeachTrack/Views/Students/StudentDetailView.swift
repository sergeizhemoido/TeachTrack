import SwiftUI
import SwiftData

struct StudentDetailView: View {

    let student: Student

    @Environment(\.modelContext)
    private var context

    @State
    private var showEditStudent = false

    @State
    private var showDeleteConfirmation = false

    var body: some View {

        Form {

            Section("Student") {

                Text(
                    "\(student.firstName) \(student.lastName)"
                )

                if let phone = student.phone {
                    Text(phone)
                }

                if let email = student.email {
                    Text(email)
                }
            }

            Section("Contacts") {

                NavigationLink {
                    ContactListView(
                        student: student
                    )

                } label: {

                    Label(
                        "Contacts",
                        systemImage: "person.2"
                    )
                }
            }

            Section("Finance") {

                NavigationLink {

                    StudentBalanceView(
                        student: student
                    )

                } label: {

                    Label(
                        "Balance",
                        systemImage: "dollarsign.circle"
                    )
                }

                NavigationLink {

                    TransactionListView(
                        student: student
                    )

                } label: {

                    Label(
                        "Transactions",
                        systemImage: "list.bullet.rectangle"
                    )
                }

                NavigationLink {

                    AddPaymentView(
                        student: student
                    )

                } label: {

                    Label(
                        "Add Payment",
                        systemImage: "plus.circle"
                    )
                }
            }
        }
        .navigationTitle(
            "\(student.firstName) \(student.lastName)"
        )
        .toolbar {
            ToolbarItem(
                placement: .topBarTrailing
            ) {
                Button("Edit") {
                    showEditStudent = true
                }
            }

            ToolbarItem(
                placement: .bottomBar
            ) {
                Button(
                    "Delete Student",
                    role: .destructive
                ) {
                    showDeleteConfirmation = true
                }
            }
        }
        .sheet(isPresented: $showEditStudent) {
            EditStudentView(student: student)
        }
        .confirmationDialog(
            "Delete Student?",
            isPresented: $showDeleteConfirmation
        ) {
            Button(
                "Delete",
                role: .destructive
            ) {
                student.isActive = false
                try? context.save()
            }

            Button(
                "Cancel",
                role: .cancel
            ) {
            }
        } message: {
            Text(
                "Are you sure you want to delete \(student.firstName) \(student.lastName)?"
            )
        }
    }
}
