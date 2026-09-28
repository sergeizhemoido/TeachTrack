//
//  EditOrganizationView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 9/16/26.
//



import SwiftUI
import SwiftData

struct EditOrganizationView: View {

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    let organization: Organization

    @State
    private var name: String

    @State
    private var type: OrganizationType

    @State
    private var phone: String

    @State
    private var email: String

    @State
    private var address: String

    @State
    private var notes: String

    @State
    private var saveErrorMessage: String?

    init(organization: Organization) {

        self.organization = organization

        _name = State(
            initialValue: organization.name
        )

        _type = State(
            initialValue: organization.type
        )

        _phone = State(initialValue: organization.phone ?? "")
        _email = State(initialValue: organization.email ?? "")
        _address = State(initialValue: organization.address ?? "")
        _notes = State(initialValue: organization.notes ?? "")
    }

    var body: some View {

        NavigationStack {

            Form {

                Section("Organization") {

                    TextField(
                        "Name",
                        text: $name
                    )

                    if organization.type != .privateClient {
                        Picker(
                            "Type",
                            selection: $type
                        ) {
                            ForEach(OrganizationType.allCases) { type in
                                Text(type.title)
                                    .tag(type)
                            }
                        }
                    }

                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)

                    TextField("Address", text: $address)

                    TextField("Notes", text: $notes, axis: .vertical)
                }
            }

            .navigationTitle(
                "Edit Organization"
            )

            .navigationBarTitleDisplayMode(
                .inline
            )

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
                        saveOrganization()
                    }
                    .disabled(
                        name.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                }
            }
        }
        .alert(
            "Unable to Save Organization",
            isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { saveErrorMessage = nil }
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    private func saveOrganization() {
        organization.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if organization.type != .privateClient {
            organization.type = type
        }
        organization.phone = optionalValue(phone)
        organization.email = optionalValue(email)
        organization.address = optionalValue(address)
        organization.notes = optionalValue(notes)

        do {
            try context.save()
            dismiss()
        } catch {
            saveErrorMessage = error.localizedDescription
        }
    }

    private func optionalValue(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
