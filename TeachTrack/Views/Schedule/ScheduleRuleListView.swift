//
//  ScheduleRuleListView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/11/26.
//
import SwiftUI
import SwiftData

struct ScheduleRuleListView: View {

    let group: Group

    @Query
    private var allRules: [ScheduleRule]

    private var rules: [ScheduleRule] {

        allRules.filter {

            $0.group.uuid == group.uuid
            &&
            $0.isActive
        }
    }

    @State
    private var showAddRule = false

    var body: some View {

        List {

            ForEach(
                rules,
                id: \.uuid
            ) { rule in

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
    }
}
