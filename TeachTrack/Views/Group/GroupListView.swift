//
//  GroipListView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/10/26.
//
import SwiftUI
import SwiftData

struct GroupListView: View {

    let organization: Organization

    @Environment(\.modelContext)
    private var context

    @Query(
        sort: \Group.name
    )
    private var allGroups: [Group]

    @State
    private var showAddGroup = false

    private var groups: [Group] {
        allGroups.filter {
            $0.organization.uuid == organization.uuid
        }
    }

    var body: some View {
        List {
            ForEach(groups, id: \.uuid) { group in
                NavigationLink {
                    GroupDetailView(
                        group: group
                    )
                } label: {
                    VStack(
                        alignment: .leading
                    ) {
                        Text(group.name)
                        Text(
                            group.revenueModel.title
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(
            organization.name
        )
        .toolbar {
            Button {
                showAddGroup = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(
            isPresented: $showAddGroup
        ) {
            AddGroupView(
                organization: organization
            )
        }
    }
}
