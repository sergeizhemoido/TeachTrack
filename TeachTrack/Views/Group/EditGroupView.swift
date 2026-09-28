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
    private var ratePerStudent: String

    @State
    private var fixedLessonRate: String

    @State
    private var saveErrorMessage: String?

    init(group: Group) {

        self.group = group

        _name = State(
            initialValue: group.name
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

    private var selectedRate: Decimal? {
        let text = group.revenueModel == .perStudent
            ? ratePerStudent : fixedLessonRate
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedRate.map { $0 >= 0 } == true
    }

    var body: some View {

        NavigationStack {

            Form {

                Section("Group") {

                    TextField(
                        "Group Name",
                        text: $name
                    )

                    LabeledContent("Compensation", value: group.revenueModel.title)
                }

                if group.revenueModel == .perStudent {

                    Section("Rate") {

                        TextField(
                            "Rate Per Student",
                            text: $ratePerStudent
                        )
                        .keyboardType(.decimalPad)
                    }
                }

                if group.revenueModel == .fixedPerLesson {

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
                        saveGroup()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .alert(
            "Unable to Save Group",
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

    private func saveGroup() {
        guard let rate = selectedRate, rate >= 0 else { return }

        group.name = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if group.revenueModel == .perStudent {
            group.ratePerStudent = rate
            group.fixedLessonRate = nil
        } else {
            group.fixedLessonRate = rate
            group.ratePerStudent = nil
        }

        do {
            try context.save()
            dismiss()
        } catch {
            context.rollback()
            saveErrorMessage = error.localizedDescription
        }
    }
}
