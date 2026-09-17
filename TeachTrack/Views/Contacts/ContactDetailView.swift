import SwiftUI
import SwiftData

struct ContactDetailView: View {

    let contact: Contact

    @Environment(\.modelContext)
    private var context

    @Environment(\.dismiss)
    private var dismiss

    @State
    private var showEditContact = false

    @State
    private var showDeleteConfirmation = false

    var body: some View {

        Form {

            Section("Contact") {

                Text(contact.name)

                Text(contact.relationship)

                if let phone = contact.phone {

                    Text(phone)
                }

                if let email = contact.email {

                    Text(email)
                }

                if let notes = contact.notes {

                    Text(notes)
                }
            }
        }
        .navigationTitle(
            contact.name
        )
        .toolbar {

            ToolbarItem(
                placement: .topBarTrailing
            ) {

                Button("Edit") {
                    showEditContact = true
                }
            }

            ToolbarItem(
                placement: .bottomBar
            ) {

                Button(
                    "Delete Contact",
                    role: .destructive
                ) {

                    showDeleteConfirmation = true
                }
            }
        }
        .sheet(
            isPresented: $showEditContact
        ) {

            EditContactView(
                contact: contact
            )
        }
        .confirmationDialog(
            "Delete Contact?",
            isPresented: $showDeleteConfirmation
        ) {

            Button(
                "Delete",
                role: .destructive
            ) {

                context.delete(contact)

                try? context.save()

                dismiss()
            }

            Button(
                "Cancel",
                role: .cancel
            ) {
            }

        } message: {

            Text(
                "Are you sure you want to delete \(contact.name)?"
            )
        }
    }
}
