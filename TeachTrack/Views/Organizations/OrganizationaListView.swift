//
//  OrganizationaListView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/10/26.
//
import SwiftUI
import SwiftData

struct OrganizationsListView: View {
    
    @Environment(\.modelContext)
    private var context

    @Query private var allGroups: [Group]

    @Query(sort: \Organization.name) private var organizations: [Organization]

    @State private var archiveErrorMessage: String?

    private var activeOrganizations: [Organization] {
        organizations.filter(\.isActive)
    }

    @State
    private var showAddOrganization = false
    
    @State
    private var organizationToDelete: Organization?

    var body: some View {

        NavigationStack {

            List {
                TeachTrackHero(
                    eyebrow: "Workspace",
                    title: "Your organizations",
                    detail: "Manage schools, private clients, and their groups in one place.",
                    symbol: "building.2.fill",
                    color: TeachTrackDesign.sunflower
                )

                if activeOrganizations.isEmpty {
                    TeachTrackEmptyState(
                        title: "No organizations yet",
                        detail: "Use the + button to create your first organization.",
                        symbol: "building.2.fill",
                        color: TeachTrackDesign.blue
                    )
                } else {
                Section("Organizations · \(activeOrganizations.count)") {
                ForEach(
                    activeOrganizations
                ) { organization in
                    NavigationLink {
                        OrganizationDetailView(
                            organization: organization
                        )
                    } label: {
                        TeachTrackIconRow(
                            title: organization.name,
                            detail: organization.type.title,
                            symbol: organization.type.displaySymbol,
                            color: organization.type.displayColor
                        )
                    }
                    .accessibilityIdentifier("organizationRow-\(organization.name)")
                    
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                organizationToDelete = organization
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.red)
                    }
                    
                }
                }
                }
            }
            .teachTrackScreen()
            .navigationTitle(
                "Organizations"
            )
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {

                Button {

                    showAddOrganization = true

                } label: {

                    Image(
                        systemName: "plus"
                    )
                }
                .accessibilityIdentifier("addOrganizationButton")
            }
            .sheet(
                isPresented:
                    $showAddOrganization
            ) {

                AddOrganizationView()
            }
            
            .confirmationDialog(
                "Delete Organization?",
                isPresented: Binding(
                    get: {
                    organizationToDelete != nil
                    },
                    set: { isPresented in
                        if !isPresented {
                        organizationToDelete = nil
                        }
                    }
                ),
                presenting: organizationToDelete
            ) { organization in
                Button(
                    "Delete",
                    role: .destructive
                ) {
                    do {
                        for group in allGroups where group.organization?.uuid == organization.uuid && group.isActive {
                            let privateStudent = organization.type == .privateClient
                                ? group.enrollments.first(where: { $0.isActive })?.student
                                : nil
                            try GroupService(context: context).archiveGroup(group)
                            if let privateStudent {
                                try StudentService(context: context).archiveStudent(privateStudent)
                            }
                        }
                        organization.isActive = false
                        try context.save()
                    } catch {
                        context.rollback()
                        archiveErrorMessage = error.localizedDescription
                    }
                    organizationToDelete = nil
                    }
                    Button(
                        "Cancel",
                        role: .cancel
                    ) {
                        organizationToDelete = nil
                        }
                        } message: { organization in
                            Text(
                                "Are you sure you want to delete \(organization.name)?"
                            )
                        }
            .alert("Unable to Delete Organization", isPresented: Binding(
                get: { archiveErrorMessage != nil },
                set: { if !$0 { archiveErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { archiveErrorMessage = nil }
            } message: {
                Text(archiveErrorMessage ?? "")
            }
 
        }
    }

}
