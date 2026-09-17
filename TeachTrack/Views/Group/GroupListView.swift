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

    private var groups: [Group] {
        allGroups.filter {
            $0.organization.uuid == organization.uuid
        }
    }

    @State
    private var groupToDelete: Group?
    
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
                
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            groupToDelete = group
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                }
                
            }
        }
        .navigationTitle(
            organization.name
        )
        .confirmationDialog(
            "Delete Group?",
            isPresented: Binding(
                get: {
                    groupToDelete != nil
                },
                set: { isPresented in
                    if !isPresented {
                        groupToDelete = nil
                    }
                }
            ),
            presenting: groupToDelete
        ) { group in
            Button(
                "Delete",
                role: .destructive
            ) {
                group.isActive = false
                try? context.save()
                groupToDelete = nil
                }
                Button(
                    "Cancel",
                    role: .cancel
                ) {
                    groupToDelete = nil
                    }
                    } message: { group in
                        Text(
                            "Are you sure you want to delete \(group.name)?"
                        )
                    }

        
        
    }
}
