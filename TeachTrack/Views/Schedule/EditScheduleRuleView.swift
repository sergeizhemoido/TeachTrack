//
//  EditScheduleRuleView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 9/17/26.
//
import SwiftUI
import SwiftData

struct EditScheduleRuleView: View {

    let rule: ScheduleRule

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    @State
    private var weekday: Weekday

    @State
    private var startHour: Int

    @State
    private var startMinute: Int

    @State
    private var durationMinutes: Int

    init(rule: ScheduleRule) {

        self.rule = rule

        _weekday = State(
            initialValue: rule.weekday
        )

        _startHour = State(
            initialValue: rule.startHour
        )

        _startMinute = State(
            initialValue: rule.startMinute
        )

        _durationMinutes = State(
            initialValue: rule.durationMinutes
        )
    }

    var body: some View {

        NavigationStack {

            Form {

                Section("Schedule") {

                    Picker(
                        "Weekday",
                        selection: $weekday
                    ) {
                        ForEach(
                            Weekday.allCases
                        ) { day in

                            Text(day.title)
                                .tag(day)
                        }
                    }

                    Stepper(
                        "Hour: \(startHour)",
                        value: $startHour,
                        in: 0...23
                    )

                    Stepper(
                        "Minute: \(startMinute)",
                        value: $startMinute,
                        in: 0...59
                    )

                    Stepper(
                        "Duration: \(durationMinutes) min",
                        value: $durationMinutes,
                        in: 15...240,
                        step: 15
                    )
                }
            }
            .navigationTitle("Edit Schedule")
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
                        save()
                    }
                }
            }
        }
    }

    private func save() {

        let calendar = Calendar.current

        let today = calendar.startOfDay(
            for: Date()
        )

        // Remove future lessons generated
        // from the old version of this rule.
        LessonGenerator.removeFutureLessons(
            for: rule,
            from: today,
            context: context
        )

        // Update the rule.
        rule.weekday = weekday
        rule.startHour = startHour
        rule.startMinute = startMinute
        rule.durationMinutes = durationMinutes

        try? context.save()

        // Generate the new future lessons.
        LessonGenerator.generateForCalendar(
            around: Date(),
            context: context
        )

        dismiss()
    }
}
