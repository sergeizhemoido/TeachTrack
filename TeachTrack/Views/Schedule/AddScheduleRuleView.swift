//
//  AddScheduleRuleView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/11/26.
//
import SwiftUI
import SwiftData

struct AddScheduleRuleView: View {

    let group: Group

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    @State
    private var weekday: Weekday = .monday

    @State
    private var startHour = 17

    @State
    private var startMinute = 0

    @State
    private var durationMinutes = 60

    var body: some View {

        NavigationStack {

            Form {

                Picker(
                    "Weekday",
                    selection: $weekday
                ) {
                    ForEach(
                            Weekday.allCases
                        ) { day in
                            Text(
                                day.title
                            )
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
                    "Duration: \(durationMinutes)",
                    value: $durationMinutes,
                    in: 15...240,
                    step: 15
                )
            }
            .navigationTitle(
                "New Schedule"
            )

            .toolbar {

                ToolbarItem(
                    placement: .confirmationAction
                ) {

                    Button("Save") {

                        let rule =
                            ScheduleRule(
                                group: group,
                                weekday: weekday,
                                startHour: startHour,
                                startMinute: startMinute,
                                durationMinutes: durationMinutes
                            )

                        context.insert(rule)

                        try? context.save()

                        dismiss()
                    }
                }
            }
        }
    }
}
