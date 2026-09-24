//
//  AddOrganizationView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/10/26.
//
import SwiftUI
import SwiftData

struct AddOrganizationView: View {

    let onSave: () -> Void

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    @State
    private var name = ""

    @State
    private var type: OrganizationType = .school

    @State
    private var saveErrorMessage: String?

    var body: some View {

        NavigationStack {
            Form {
                Section("Organization") {
                    TextField(
                        "Name",
                        text: $name
                    )

                    Picker(
                        "Type",
                        selection: $type
                    ) {
                        ForEach(
                            OrganizationType.allCases
                        ) { type in

                            Text(type.title)
                                .tag(type)
                        }
                    }
                }
            }
            .navigationTitle("New Organization")
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
                set: { isPresented in
                    if !isPresented {
                        saveErrorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                saveErrorMessage = nil
            }
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    private func saveOrganization() {
        let organization = Organization(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            type: type
        )

        context.insert(organization)

        do {
            try context.save()
            onSave()
            dismiss()
        } catch {
            context.rollback()
            saveErrorMessage = error.localizedDescription
        }
    }
}
