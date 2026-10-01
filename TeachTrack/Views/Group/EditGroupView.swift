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
    private var organizationAttendanceRate: String

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

        _organizationAttendanceRate = State(
            initialValue: group.organizationAttendanceRate?
                .description ?? ""
        )
    }

    private var selectedRate: Decimal? {
        let text: String
        switch group.revenueModel {
        case .perStudent:
            text = ratePerStudent
        case .fixedPerLesson:
            text = fixedLessonRate
        case .organizationPerAttendee:
            text = organizationAttendanceRate
        }
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

                    LabeledContent("Payment Method", value: group.revenueModel.title)
                }

                if group.revenueModel == .perStudent {

                    Section("Rate") {

                        TextField(
                            "Lesson Rate Per Student",
                            text: $ratePerStudent
                        )
                        .keyboardType(.decimalPad)
                    }
                }

                if group.revenueModel == .fixedPerLesson {

                    Section("Rate") {

                        TextField(
                            "Organization Lesson Rate",
                            text: $fixedLessonRate
                        )
                        .keyboardType(.decimalPad)
                    }
                }

                if group.revenueModel == .organizationPerAttendee {
                    Section("Rate") {
                        TextField(
                            "Rate Per Present Student",
                            text: $organizationAttendanceRate
                        )
                        .keyboardType(.decimalPad)
                    }
                }
            }

            .teachTrackScreen()
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

        switch group.revenueModel {
        case .perStudent:
            group.ratePerStudent = rate
            group.fixedLessonRate = nil
            group.organizationAttendanceRate = nil
        case .fixedPerLesson:
            group.fixedLessonRate = rate
            group.ratePerStudent = nil
            group.organizationAttendanceRate = nil
        case .organizationPerAttendee:
            group.organizationAttendanceRate = rate
            group.ratePerStudent = nil
            group.fixedLessonRate = nil
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
