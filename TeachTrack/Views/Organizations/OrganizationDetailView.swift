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
        .confirmationDialog(
            "Delete Organization?",
            isPresented: $showDeleteConfirmation
        ) {
            Button(
                "Delete",
                role: .destructive
            ) {
                organization.isActive = false
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
