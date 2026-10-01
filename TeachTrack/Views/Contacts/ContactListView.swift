import SwiftUI
import SwiftData

struct ContactListView: View {

    let student: Student

    @Environment(\.modelContext)
    private var context

    @Query
    private var contacts: [Contact]

    @State
    private var showAddRelativeContact = false

    @State private var showStudentContact = false

    @State
    private var contactToDelete: Contact?

    @State private var saveError: String?

    private enum StudentField {
        case phone, email, notes
    }

    private var studentContacts: [Contact] {

        contacts.filter {
            $0.student.uuid == student.uuid
        }
    }

    var body: some View {

        List {

            Section("Student Contact") {
                if let phone = student.phone, !phone.isEmpty {
                    studentFieldRow("Phone", value: phone, field: .phone)
                }
                if let email = student.email, !email.isEmpty {
                    studentFieldRow("Email", value: email, field: .email)
                }
                if let notes = student.notes, !notes.isEmpty {
                    studentFieldRow("Notes", value: notes, field: .notes)
                }
                if (student.phone?.isEmpty ?? true) &&
                    (student.email?.isEmpty ?? true) &&
                    (student.notes?.isEmpty ?? true) {
                    Text("No contact details")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Relatives and Other Contacts") {
                if studentContacts.isEmpty {
                    Text("No additional contacts")
                        .foregroundStyle(.secondary)
                }
                ForEach(studentContacts, id: \.uuid) { contact in
                    NavigationLink {
                        ContactDetailView(contact: contact)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(contact.displayName)
                            if !contact.relationship.isEmpty && contact.relationship != contact.displayName {
                                Text(contact.relationship)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            contactToDelete = contact
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
        }
        .teachTrackScreen()
        .navigationTitle("Contacts")
        .toolbar {
            Menu {
                Button("Student Contact", systemImage: "person") {
                    showStudentContact = true
                }
                Button("Relative Contact", systemImage: "person.2") {
                    showAddRelativeContact = true
                }
            } label: {
                Label("Add Contact", systemImage: "plus")
            }
            .accessibilityIdentifier("addStudentContactButton")
        }
        .sheet(
            isPresented: $showAddRelativeContact
        ) {

            AddContactView(
                student: student
            )
        }
        .sheet(isPresented: $showStudentContact) {
            EditStudentContactView(student: student)
        }
        .alert("Could Not Delete Contact Data", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK") { saveError = nil }
        } message: {
            Text(saveError ?? "Unknown error")
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

                do {
                    try context.save()
                } catch {
                    context.rollback()
                    saveError = error.localizedDescription
                }

                contactToDelete = nil
            }

            Button(
                "Cancel",
                role: .cancel
            ) {

                contactToDelete = nil
            }

        } message: { contact in

            Text("Are you sure you want to delete \(contact.displayName)?")
        }
    }

    private func studentFieldRow(
        _ title: String,
        value: String,
        field: StudentField
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                clearStudentField(field)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
    }

    private func clearStudentField(_ field: StudentField) {
        let previous: String?
        switch field {
        case .phone:
            previous = student.phone
            student.phone = nil
        case .email:
            previous = student.email
            student.email = nil
        case .notes:
            previous = student.notes
            student.notes = nil
        }
        do {
            try context.save()
        } catch {
            switch field {
            case .phone: student.phone = previous
            case .email: student.email = previous
            case .notes: student.notes = previous
            }
            saveError = error.localizedDescription
        }
    }
}
