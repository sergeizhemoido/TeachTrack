//
//  AddLessonFromCalendarView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 9/17/26.
//
import SwiftUI
import SwiftData

struct AddLessonFromCalendarView: View {

    let selectedDate: Date

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    @Query(
        sort: \Group.name
    )
    private var allGroups: [Group]

    private var groups: [Group] {
        allGroups.filter {
            $0.isActive
        }
    }

    @State
    private var selectedGroup: Group?

    @State
    private var startDate: Date

    @State
    private var durationMinutes = 60

    init(selectedDate: Date) {

        self.selectedDate = selectedDate

        _startDate = State(
            initialValue: selectedDate
        )
    }

    var body: some View {

        NavigationStack {

            Form {

                Section("Group") {

                    Picker(
                        "Group",
                        selection: $selectedGroup
                    ) {

                        Text("Select Group")
                            .tag(nil as Group?)

                        ForEach(
                            groups,
                            id: \.uuid
                        ) { group in

                            Text(
                                "\(group.name) — \(group.organization.name)"
                            )
                            .tag(group as Group?)
                        }
                    }
                }

                Section("Lesson") {

                    DatePicker(
                        "Start",
                        selection: $startDate
                    )

                    Stepper(
                        "Duration: \(durationMinutes) min",
                        value: $durationMinutes,
                        in: 15...240,
                        step: 15
                    )
                }
            }
            .navigationTitle("New Lesson")
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

                        guard let group = selectedGroup
                        else {
                            return
                        }

                        let endDate =
                            startDate.addingTimeInterval(
                                Double(
                                    durationMinutes * 60
                                )
                            )

                        let lesson = Lesson(
                            group: group,
                            startDate: startDate,
                            endDate: endDate,
                            source: .manual
                        )

                        context.insert(lesson)

                        try? context.save()

                        dismiss()
                    }
                    .disabled(
                        selectedGroup == nil
                    )
                }
            }
        }
    }
}
