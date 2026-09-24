import SwiftUI
import SwiftData

struct OrganizationDetailView: View {

    let organization: Organization

    @Environment(\.modelContext)
    private var context

    @State
    private var showEditOrganization = false

    @State
    private var showDeleteConfirmation = false

    @State
    private var showAddGroup = false

    var body: some View {

        GroupListView(
            organization: organization
        )
        .navigationTitle(
            organization.name
        )
        .toolbar {

            ToolbarItem(
                placement: .topBarTrailing
            ) {
                Button("Edit") {
                    showEditOrganization = true
                }
            }

            ToolbarItem(
                placement: .topBarTrailing
            ) {
                Button {
                    showAddGroup = true
                } label: {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(
                placement: .bottomBar
            ) {
                Button(
                    "Delete Organization",
                    role: .destructive
                ) {
                    showDeleteConfirmation = true
                }
            }
        }

        .sheet(
            isPresented: $showEditOrganization
        ) {
            EditOrganizationView(
                organization: organization
            )
        }

        .sheet(
            isPresented: $showAddGroup
        ) {
            AddGroupView(
                organization: organization
            )
        }

        .confirmationDialog(
            "Delete Organization?",
            isPresented: $showDeleteConfirmation
        ) {

            Button(
                "Delete",
                role: .destructive
            ) {

                organization.isActive = false

                for group in organization.groups {
                    group.isActive = false
                }

                try? context.save()
            }

            Button(
                "Cancel",
                role: .cancel
            ) {
            }

        } message: {

            Text(
                "Are you sure you want to delete \(organization.name)?"
            )
        }
    }
}
