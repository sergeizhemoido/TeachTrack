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

    @State private var saveError: String?

    private enum ContactField {
        case name, relationship, phone, email, notes
    }

    var body: some View {

        Form {

            Section("Contact") {

                if !contact.name.isEmpty {
                    contactFieldRow("Relative / Contact", value: contact.name, field: .name)
                }

                if !contact.relationship.isEmpty {
                    contactFieldRow("Relationship", value: contact.relationship, field: .relationship)
                }

                if let phone = contact.phone, !phone.isEmpty {
                    contactFieldRow("Phone", value: phone, field: .phone)
                }

                if let email = contact.email, !email.isEmpty {
                    contactFieldRow("Email", value: email, field: .email)
                }

                if let notes = contact.notes, !notes.isEmpty {
                    contactFieldRow("Notes", value: notes, field: .notes)
                }
            }
        }
        .teachTrackScreen()
        .navigationTitle(
            contact.displayName
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
            isPresented: $showDeleteConfirmation
        ) {

            Button(
                "Delete",
                role: .destructive
            ) {

                context.delete(contact)

                do {
                    try context.save()
                    dismiss()
                } catch {
                    context.rollback()
                    saveError = error.localizedDescription
                }
            }

            Button(
                "Cancel",
                role: .cancel
            ) {
            }

        } message: {

            Text(
                "Are you sure you want to delete \(contact.displayName)?"
            )
        }
    }

    private func contactFieldRow(
        _ title: String,
        value: String,
        field: ContactField
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                clearField(field)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
    }

    private func clearField(_ field: ContactField) {
        switch field {
        case .name: contact.name = ""
        case .relationship: contact.relationship = ""
        case .phone: contact.phone = nil
        case .email: contact.email = nil
        case .notes: contact.notes = nil
        }

        let isEmpty = contact.name.isEmpty && contact.relationship.isEmpty &&
            (contact.phone?.isEmpty ?? true) && (contact.email?.isEmpty ?? true) &&
            (contact.notes?.isEmpty ?? true)
        if isEmpty {
            context.delete(contact)
        }

        do {
            try context.save()
            if isEmpty { dismiss() }
        } catch {
            context.rollback()
            saveError = error.localizedDescription
        }
    }
}
