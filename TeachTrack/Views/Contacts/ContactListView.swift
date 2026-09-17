import SwiftUI
import SwiftData

struct ContactListView: View {

    let student: Student

    @Environment(\.modelContext)
    private var context

    @Query
    private var contacts: [Contact]

    @State
    private var showAddContact = false

    @State
    private var contactToDelete: Contact?

    private var studentContacts: [Contact] {

        contacts.filter {
            $0.student.uuid == student.uuid
        }
    }

    var body: some View {

        List {

            ForEach(
                studentContacts,
                id: \.uuid
            ) { contact in

                NavigationLink {

                    ContactDetailView(
                        contact: contact
                    )

                } label: {

                    Text(
                        contact.name
                    )
                }
                .swipeActions(
                    edge: .trailing,
                    allowsFullSwipe: false
                ) {

                    Button(
                        role: .destructive
                    ) {

                        contactToDelete = contact

                    } label: {

                        Label(
                            "Delete",
                            systemImage: "trash"
                        )
                    }
                }
            }
        }
        .navigationTitle("Contacts")
        .toolbar {

            Button {

                showAddContact = true

            } label: {

                Image(systemName: "plus")
            }
        }
        .sheet(
            isPresented: $showAddContact
        ) {

            AddContactView(
                student: student
            )
        }
        .confirmationDialog(
            "Delete Contact?",
            isPresented: Binding(
                get: {
                    contactToDelete != nil
                },
                set: { isPresented in

                    if !isPresented {
                        contactToDelete = nil
                    }
                }
            ),
            presenting: contactToDelete
        ) { contact in

            Button(
                "Delete",
                role: .destructive
            ) {

                context.delete(contact)

                try? context.save()

                contactToDelete = nil
            }

            Button(
                "Cancel",
                role: .cancel
            ) {

                contactToDelete = nil
            }

        } message: { contact in

            Text(
                "Are you sure you want to delete \(contact.name)?"
            )
        }
    }
}
