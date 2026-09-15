//
//  AddLessonView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/10/26.
//
import SwiftUI
import SwiftData

struct AddLessonView: View {

    let group: Group

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    @State
    private var startDate = Date()

    @State
    private var durationMinutes = 60

    var body: some View {

        NavigationStack {

            Form {

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
            .navigationTitle(
                "New Lesson"
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

                        context.insert(
                            lesson
                        )

                        try? context.save()

                        dismiss()
                    }
                }
            }
        }
    }
}
