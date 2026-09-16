import SwiftUI
import SwiftData

struct ScheduleRuleListView: View {

    let group: Group

    @Environment(\.modelContext)
    private var context

    @Query
    private var allRules: [ScheduleRule]

    @State
    private var showAddRule = false

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
                    return $0.weekday.rawValue < $1.weekday.rawValue
                }

                if $0.startHour != $1.startHour {
                    return $0.startHour < $1.startHour
                }

                return $0.startMinute < $1.startMinute
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
                        alignment: .leading
                    ) {

                        Text(
                            rule.weekday.title
                        )

                        Text(
                            "\(rule.startHour):\(String(format: "%02d", rule.startMinute))"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .swipeActions(
                    edge: .trailing,
                    allowsFullSwipe: false
                ) {

                    Button(
                        role: .destructive
                    ) {

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

            Button {

                showAddRule = true

            } label: {

                Image(systemName: "plus")
            }
        }
        .sheet(
            isPresented: $showAddRule
        ) {

            AddScheduleRuleView(
                group: group
            )
        }
        .confirmationDialog(
            "Delete Schedule Rule?",
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
                "Are you sure you want to delete this schedule rule?"
            )
        }
    }
}
