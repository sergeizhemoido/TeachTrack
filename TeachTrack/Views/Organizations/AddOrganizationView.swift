//
//  AddOrganizationView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/10/26.
//
import SwiftUI
import SwiftData

struct AddOrganizationView: View {

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    @State
    private var name = ""

    @State
    private var type: OrganizationType = .school

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
                        let organization = Organization(
                            name: name,
                            type: type
                        )
                        context.insert(
                            organization
                        )
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
