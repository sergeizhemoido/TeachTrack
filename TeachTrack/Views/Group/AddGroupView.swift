//
//  AddGroupView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/10/26.
//

import SwiftUI
import SwiftData

struct AddGroupView: View {

    let organization: Organization

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    @State
    private var name = ""

    @State
    private var revenueModel: RevenueModel = .perStudent

    @State
    private var ratePerStudent = ""

    @State
    private var fixedLessonRate = ""

    private var isPrivateClient: Bool {
        organization.type == .privateClient
    }

    var body: some View {

        NavigationStack {

            Form {

                Section("Group") {

                    TextField(
                        "Group Name",
                        text: $name
                    )

                    if !isPrivateClient {

                        Picker(
                            "Compensation",
                            selection: $revenueModel
                        ) {

                            ForEach(
                                RevenueModel.allCases,
                                id: \.self
                            ) { model in

                                Text(model.title)
                                    .tag(model)
                            }
                        }
                    }
                }

                if revenueModel == .perStudent {

                    Section("Rate") {

                        TextField(
                            "Rate Per Student",
                            text: $ratePerStudent
                        )
                        .keyboardType(.decimalPad)
                    }
                }

                if revenueModel == .fixedPerLesson {

                    Section("Rate") {

                        TextField(
                            "Fixed Lesson Rate",
                            text: $fixedLessonRate
                        )
                        .keyboardType(.decimalPad)
                    }
                }
            }

            .navigationTitle("New Group")
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

                        let finalRevenueModel: RevenueModel =
                            isPrivateClient
                            ? .perStudent
                            : revenueModel

                        let group = Group(
                            name: name,
                            revenueModel: finalRevenueModel,
                            organization: organization
                        )

                        if finalRevenueModel == .perStudent {

                            group.ratePerStudent =
                                Decimal(
                                    string: ratePerStudent
                                )

                            group.fixedLessonRate = nil

                        } else {

                            group.fixedLessonRate =
                                Decimal(
                                    string: fixedLessonRate
                                )

                            group.ratePerStudent = nil
                        }

                        context.insert(group)

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

