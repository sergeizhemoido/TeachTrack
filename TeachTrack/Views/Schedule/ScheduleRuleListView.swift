//
//  ScheduleRuleListView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 9/17/26.
//

import SwiftUI
import SwiftData

struct ScheduleRuleListView: View {

    let group: Group

    @Environment(\.modelContext)
    private var context

    @Query
    private var allRules: [ScheduleRule]

    @State
    private var showAddScheduleRule = false

    @State
    private var ruleToDelete: ScheduleRule?

    private var rules: [ScheduleRule] {

        allRules
            .filter {
                $0.group.uuid == group.uuid &&
                $0.isActive
            }
            .sorted {
                if $0.weekday.rawValue != $1.weekday.rawValue {
                    return $0.weekday.rawValue <
                        $1.weekday.rawValue
                }

                if $0.startHour != $1.startHour {
                    return $0.startHour <
                        $1.startHour
                }

                return $0.startMinute <
                    $1.startMinute
            }
    }

    var body: some View {

        List {

            ForEach(
                rules,
                id: \.uuid
            ) { rule in

                NavigationLink {
                    EditScheduleRuleView(
                        rule: rule
                    )
                } label: {

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {

                        Text(
                            rule.weekday.title
                        )

                        Text(
                            String(
                                format: "%02d:%02d",
                                rule.startHour,
                                rule.startMinute
                            )
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        Text(
                            "\(rule.durationMinutes) min"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .swipeActions(
                    edge: .trailing,
                    allowsFullSwipe: false
                ) {

                    Button(role: .destructive) {

                        ruleToDelete = rule

                    } label: {

                        Label(
                            "Delete",
                            systemImage: "trash"
                        )
                    }
                }
            }
        }
        .navigationTitle("Schedule")
        .toolbar {

            ToolbarItem(
                placement: .topBarTrailing
            ) {

                Button {

                    showAddScheduleRule = true

                } label: {

                    Image(
                        systemName: "plus"
                    )
                }
            }
        }
        .sheet(
            isPresented: $showAddScheduleRule
        ) {

            AddScheduleRuleView(
                group: group
            )
        }
        .confirmationDialog(
            "Delete Schedule?",
            isPresented: Binding(
                get: {
                    ruleToDelete != nil
                },
                set: { isPresented in

                    if !isPresented {
                        ruleToDelete = nil
                    }
                }
            ),
            presenting: ruleToDelete
        ) { rule in

            Button(
                "Delete",
                role: .destructive
            ) {

                let calendar = Calendar.current

                let today = calendar.startOfDay(
                    for: Date()
                )

                LessonGenerator.removeFutureLessons(
                    for: rule,
                    from: today,
                    context: context
                )

                rule.isActive = false

                try? context.save()

                ruleToDelete = nil
            }

            Button(
                "Cancel",
                role: .cancel
            ) {
                ruleToDelete = nil
            }

        } message: { rule in

            Text(
                "Delete the schedule for \(rule.weekday.title) at \(String(format: "%02d:%02d", rule.startHour, rule.startMinute))?"
            )
        }
    }
}
