//
//  OrganizationaListView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/10/26.
//
import SwiftUI
import SwiftData

struct OrganizationsListView: View {

    @Query(
        filter: #Predicate<Organization> {
            $0.isActive
        },
        sort: \Organization.name
    )
    private var organizations: [Organization]

    @State
    private var showAddOrganization = false

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
        }
    }
}
