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
    private var revenueModel: RevenueModel?

    @State
    private var ratePerStudent = ""

    @State
    private var fixedLessonRate = ""

    @State
    private var saveErrorMessage: String?

    private var isPrivateClient: Bool {
        organization.type == .privateClient
    }

    private var selectedRevenueModel: RevenueModel? {
        isPrivateClient ? .perStudent : revenueModel
    }

    private var selectedRate: Decimal? {
        let text = selectedRevenueModel == .perStudent
            ? ratePerStudent : fixedLessonRate
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return Decimal(string: normalized)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedRevenueModel != nil &&
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

                    if !isPrivateClient {

                        Picker(
                            "Compensation",
                            selection: $revenueModel
                        ) {

                            Text("Select Compensation")
                                .tag(nil as RevenueModel?)

                            ForEach(
                                RevenueModel.allCases,
                                id: \.self
                            ) { model in

                                Text(model.title)
                                    .tag(model as RevenueModel?)
                            }
                        }
                        .accessibilityIdentifier("compensationPicker")
                    }
                }

                if selectedRevenueModel == .perStudent {

                    Section("Rate") {

                        TextField(
                            "Rate Per Student",
                            text: $ratePerStudent
                        )
                        .accessibilityIdentifier("perStudentRateField")
                        .keyboardType(.decimalPad)
                    }
                }

                if selectedRevenueModel == .fixedPerLesson {

                    Section("Rate") {

                        TextField(
                            "Fixed Lesson Rate",
                            text: $fixedLessonRate
                        )
                        .accessibilityIdentifier("perLessonRateField")
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
        guard let model = selectedRevenueModel,
              let rate = selectedRate,
              rate >= 0 else { return }

        let group = Group(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            revenueModel: model,
            organization: organization
        )

        if model == .perStudent {
            group.ratePerStudent = rate
        } else {
            group.fixedLessonRate = rate
        }

        context.insert(group)

        do {
            try context.save()
            dismiss()
        } catch {
            context.rollback()
            saveErrorMessage = error.localizedDescription
        }
    }
}
