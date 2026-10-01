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

    @State
    private var organizations: [Organization] = []

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
            .task {
                loadOrganizations()
            }

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

                AddOrganizationView(
                    onSave: loadOrganizations
                )
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
                    organization.isActive = false
                    try? context.save()
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
 
        }
    }

    private func loadOrganizations() {
        let descriptor = FetchDescriptor<Organization>(
            sortBy: [SortDescriptor(\Organization.name)]
        )

        do {
            organizations = try context.fetch(descriptor)
        } catch {
            organizations = []
        }
    }
}
