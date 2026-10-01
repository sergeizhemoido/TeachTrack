//
//  EditContactView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 9/17/26.
//

import SwiftUI
import SwiftData

struct EditContactView: View {

    let contact: Contact

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    @State
    private var name: String

    @State
    private var relationship: String

    @State
    private var phone: String

    @State
    private var email: String

    @State
    private var notes: String

    @State private var saveError: String?

    private var hasContent: Bool {
        [name, relationship, phone, email, notes].contains {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    init(contact: Contact) {

        self.contact = contact

        _name = State(
            initialValue: contact.name
        )

        _relationship = State(
            initialValue: contact.relationship
        )

        _phone = State(
            initialValue: contact.phone ?? ""
        )

        _email = State(
            initialValue: contact.email ?? ""
        )

        _notes = State(
            initialValue: contact.notes ?? ""
        )
    }

    var body: some View {

        NavigationStack {

            Form {

                Section("Contact") {

                    TextField(
                        "Relative / Contact Name",
                        text: $name
                    )

                    TextField(
                        "Relationship",
                        text: $relationship
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
                    .textInputAutocapitalization(.never)

                    TextField(
                        "Notes",
                        text: $notes,
                        axis: .vertical
                    )
                }
            }
            .teachTrackScreen()
            .navigationTitle("Edit Contact")
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

                    Button("Save") { save() }
                        .disabled(!hasContent)
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
        contact.name = optionalValue(name) ?? ""
        contact.relationship = optionalValue(relationship) ?? ""
        contact.phone = optionalValue(phone)
        contact.email = optionalValue(email)
        contact.notes = optionalValue(notes)
        do {
            try context.save()
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}
