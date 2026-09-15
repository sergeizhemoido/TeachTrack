//
//  AddContactView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/11/26.
//
import SwiftUI
import SwiftData

struct AddContactView: View {

    let student: Student

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    @State
    private var name = ""

    @State
    private var relationship = ""

    @State
    private var phone = ""

    @State
    private var email = ""

    var body: some View {

        NavigationStack {

            Form {

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

                TextField(
                    "Email",
                    text: $email
                )
            }
            .navigationTitle("New Contact")
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

                        let contact = Contact(
                            student: student,
                            name: name,
                            relationship: relationship
                        )

                        contact.phone =
                            phone.isEmpty ? nil : phone

                        contact.email =
                            email.isEmpty ? nil : email

                        context.insert(contact)

                        try? context.save()

                        dismiss()
                    }
                    .disabled(
                        name.isEmpty
                    )
                }
            }
        }
    }
}
