import SwiftUI
import SwiftData

struct EditLessonView: View {

    let lesson: Lesson

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    @State
    private var startDate: Date

    @State
    private var durationMinutes: Int

    @State
    private var status: LessonStatus

    init(lesson: Lesson) {

        self.lesson = lesson

        _startDate = State(
            initialValue: lesson.startDate
        )

        let duration =
            lesson.endDate.timeIntervalSince(
                lesson.startDate
            ) / 60

        _durationMinutes = State(
            initialValue: Int(duration)
        )

        _status = State(
            initialValue: lesson.status
        )
    }

    var body: some View {

        NavigationStack {

            Form {

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

                    Picker(
                        "Status",
                        selection: $status
                    ) {

                        ForEach(
                            LessonStatus.allCases,
                            id: \.self
                        ) { status in

                            Text(
                                status.rawValue
                            )
                            .tag(status)
                        }
                    }
                }
            }
            .navigationTitle("Edit Lesson")
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

                        lesson.startDate =
                            startDate

                        lesson.endDate =
                            startDate.addingTimeInterval(
                                Double(
                                    durationMinutes * 60
                                )
                            )

                        lesson.status =
                            status

                        try? context.save()

                        dismiss()
                    }
                }
            }
        }
    }
}

