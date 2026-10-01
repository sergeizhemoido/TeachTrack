//
//  AddStudentView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/9/26.
//

import SwiftUI
import SwiftData

struct AddStudentView: View {

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    @State
    private var firstName = ""

    @State
    private var lastName = ""

    @State private var phone = ""
    @State private var email = ""
    @State private var notes = ""
    @State private var saveError: String?

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
                }

                Section("Contact") {
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Notes", text: $notes, axis: .vertical)
                }
            }

            .teachTrackScreen()
            .navigationTitle("New Student")
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
            .alert("Could Not Save Student", isPresented: Binding(
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
        do {
            try StudentService(context: context).createStudent(
                firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                studentType: .regular,
                phone: optionalValue(phone),
                email: optionalValue(email),
                notes: optionalValue(notes)
            )
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}
