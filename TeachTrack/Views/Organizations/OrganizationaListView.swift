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

    @Query(
        filter: #Predicate<Organization> {
            $0.isActive
        },
        sort: \Organization.name
    )
    private var organizations: [Organization]

    @State
    private var showAddOrganization = false
    
    @State
    private var organizationToDelete: Organization?

    var body: some View {

        NavigationStack {

            List {
                ForEach(
                    organizations
                ) { organization in
                    NavigationLink {
                        OrganizationDetailView(
                            organization: organization
                        )
                    } label: {
                        VStack(
                            alignment: .leading
                        ) {
                            Text(
                                organization.name
                            )
                            Text(
                                organization.type.title
                            )
                            .font(.caption)
                            .foregroundStyle(
                                .secondary
                            )
                        }
                    }
                    
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                organizationToDelete = organization
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                    }
                    
                }
            }
            .navigationTitle(
                "Organizations"
            )

            .toolbar {

                Button {

                    showAddOrganization = true

                } label: {

                    Image(
                        systemName: "plus"
                    )
                }
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
}
