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

    @State private var notes = ""
    @State private var saveError: String?

    private var hasContent: Bool {
        [name, relationship, phone, email, notes].contains {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var body: some View {

        NavigationStack {

            Form {

                TextField("Relative / Contact Name", text: $name)

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

                TextField("Notes", text: $notes, axis: .vertical)
            }
            .teachTrackScreen()
            .navigationTitle("New Relative Contact")
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
        let contact = Contact(
            student: student,
            name: optionalValue(name) ?? "",
            relationship: optionalValue(relationship) ?? ""
        )
        contact.phone = optionalValue(phone)
        contact.email = optionalValue(email)
        contact.notes = optionalValue(notes)
        context.insert(contact)
        do {
            try context.save()
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}
