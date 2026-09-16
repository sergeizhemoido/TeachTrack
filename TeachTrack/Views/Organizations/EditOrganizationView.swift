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

    init(organization: Organization) {

        self.organization = organization

        _name = State(
            initialValue: organization.name
        )

        _type = State(
            initialValue: organization.type
        )
    }

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

                            Text(
                                type.title
                            )
                            .tag(type)
                        }
                    }
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

                        organization.name =
                            name.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )

                        organization.type =
                            type

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

