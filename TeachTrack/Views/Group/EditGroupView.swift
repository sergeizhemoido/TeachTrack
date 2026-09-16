//
//  EditGroupView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 9/16/26.
//

import SwiftUI
import SwiftData

struct EditGroupView: View {

    let group: Group

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    @State
    private var name: String

    @State
    private var revenueModel: RevenueModel

    @State
    private var ratePerStudent: String

    @State
    private var fixedLessonRate: String

    init(group: Group) {

        self.group = group

        _name = State(
            initialValue: group.name
        )

        _revenueModel = State(
            initialValue: group.revenueModel
        )

        _ratePerStudent = State(
            initialValue: group.ratePerStudent?
                .description ?? ""
        )

        _fixedLessonRate = State(
            initialValue: group.fixedLessonRate?
                .description ?? ""
        )
    }

    var body: some View {

        NavigationStack {

            Form {

                Section("Group") {

                    TextField(
                        "Group Name",
                        text: $name
                    )

                    Picker(
                        "Compensation",
                        selection: $revenueModel
                    ) {

                        ForEach(
                            RevenueModel.allCases,
                            id: \.self
                        ) { model in

                            Text(
                                model.title
                            )
                            .tag(model)
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

            .navigationTitle(
                "Edit Group"
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

                        group.name =
                            name.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )

                        group.revenueModel =
                            revenueModel

                        if revenueModel == .perStudent {

                            group.ratePerStudent =
                                Decimal(
                                    string: ratePerStudent
                                )

                            group.fixedLessonRate =
                                nil

                        } else {

                            group.fixedLessonRate =
                                Decimal(
                                    string: fixedLessonRate
                                )

                            group.ratePerStudent =
                                nil
                        }

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

