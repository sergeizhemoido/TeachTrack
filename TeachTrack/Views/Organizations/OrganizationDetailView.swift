
import SwiftUI
import SwiftData

struct OrganizationDetailView: View {

    let organization: Organization

    @Environment(\.modelContext)
    private var context

    @State
    private var showAddGroup = false

    @State
    private var showAddPrivateStudent = false

    var body: some View {

        List {

            Section("Organization") {

                Text(organization.name)

                Text(organization.type.title)
                    .foregroundStyle(.secondary)
            }

            Section("Groups") {

                ForEach(
                    organization.groups
                        .filter { $0.isActive }
                        .sorted { $0.name < $1.name },
                    id: \.uuid
                ) { group in

                    NavigationLink {

                        GroupDetailView(
                            group: group
                        )

                    } label: {

                        VStack(
                            alignment: .leading
                        ) {

                            Text(group.name)

                            Text(group.revenueModel.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }

        .navigationTitle(organization.name)
        .navigationBarTitleDisplayMode(.inline)

        .toolbar {

            ToolbarItem(
                placement: .topBarTrailing
            ) {

                if organization.type == .privateClient {

                    Button {
                        showAddPrivateStudent = true
                    } label: {

                        Label(
                            "Add Student",
                            systemImage: "person.badge.plus"
                        )
                    }

                } else {

                    Button {
                        showAddGroup = true
                    } label: {

                        Label(
                            "Add Group",
                            systemImage: "plus"
                        )
                    }
                }
            }
        }

        .sheet(
            isPresented: $showAddGroup
        ) {

            AddGroupView(
                organization: organization
            )
        }

        .sheet(
            isPresented: $showAddPrivateStudent
        ) {

            AddPrivateStudentView(
                organization: organization
            )
        }
    }
}

