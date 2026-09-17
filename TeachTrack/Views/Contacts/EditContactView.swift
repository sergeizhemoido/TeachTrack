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
                        "Name",
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

                    TextField(
                        "Notes",
                        text: $notes,
                        axis: .vertical
                    )
                }
            }
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

                    Button("Save") {

                        contact.name =
                            name.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )

                        contact.relationship =
                            relationship.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )

                        contact.phone =
                            phone.isEmpty ? nil : phone

                        contact.email =
                            email.isEmpty ? nil : email

                        contact.notes =
                            notes.isEmpty ? nil : notes

                        try? context.save()

                        dismiss()
                    }
                    .disabled(
                        name.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                }
            }
        }
    }
}
