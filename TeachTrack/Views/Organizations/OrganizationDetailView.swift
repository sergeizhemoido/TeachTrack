
import SwiftUI
import SwiftData

struct OrganizationDetailView: View {

    let organization: Organization

    @Environment(\.modelContext)
    private var context

    @Query
    private var allGroups: [Group]

    @Query
    private var allEnrollments: [Enrollment]

    private var activeGroups: [Group] {
        allGroups
            .filter { $0.organization?.uuid == organization.uuid && $0.isActive }
            .sorted { $0.name < $1.name }
    }

    @State
    private var showAddGroup = false

    @State
    private var showAddPrivateStudent = false

    @State
    private var showEditOrganization = false

    @State
    private var groupToArchive: Group?

    @State
    private var archiveErrorMessage: String?

    var body: some View {

        List {
            TeachTrackHero(
                eyebrow: "Organization",
                title: organization.name,
                detail: organization.type.title,
                symbol: organization.type.displaySymbol,
                color: TeachTrackDesign.sunflower
            )

            Section(organization.type == .privateClient ? "Students" : "Groups") {

                ForEach(
                    activeGroups,
                    id: \.uuid
                ) { group in

                    NavigationLink {
                        if organization.type == .privateClient,
                           let student = privateStudent(for: group) {
                            PrivateStudentDetailView(
                                student: student,
                                group: group
                            )
                        } else {
                            GroupDetailView(group: group)
                        }

                    } label: {

                        TeachTrackIconRow(
                            title: group.name,
                            detail: organization.type == .privateClient ? "Private student" : group.revenueModel.title,
                            symbol: organization.type == .privateClient ? "person.crop.circle.fill" : "person.3.fill",
                            color: organization.type == .privateClient ? TeachTrackDesign.violet : TeachTrackDesign.coral
                        )
                    }
                    .accessibilityIdentifier("groupRow-\(group.name)")
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            groupToArchive = group
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                }
            }

            Section("Finance") {
                NavigationLink {
                    AccountStatementView(organization: organization)
                } label: {
                    TeachTrackIconRow(
                        title: "Account and History",
                        detail: "Balance, payments, and deposits",
                        symbol: "dollarsign.circle",
                        color: TeachTrackDesign.amber
                    )
                }
                .accessibilityLabel("Account and History")
            }
        }

        .teachTrackScreen()
        .navigationTitle(organization.name)
        .navigationBarTitleDisplayMode(.inline)

        .toolbar {

            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Edit") {
                    showEditOrganization = true
                }

                if organization.type == .privateClient {

                    Button {
                        showAddPrivateStudent = true
                    } label: {

                        Label(
                            "Add Student",
                            systemImage: "person.badge.plus"
                        )
                    }
                    .accessibilityIdentifier("addPrivateStudentButton")

                } else {

                    Button {
                        showAddGroup = true
                    } label: {

                        Label(
                            "Add Group",
                            systemImage: "plus"
                        )
                    }
                    .accessibilityIdentifier("addGroupButton")
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

        .sheet(isPresented: $showEditOrganization) {
            EditOrganizationView(organization: organization)
        }
        .confirmationDialog(
            "Delete Group?",
            isPresented: Binding(
                get: { groupToArchive != nil },
                set: { if !$0 { groupToArchive = nil } }
            ),
            presenting: groupToArchive
        ) { group in
            Button("Delete", role: .destructive) {
                archive(group)
            }
            Button("Cancel", role: .cancel) {
                groupToArchive = nil
            }
        } message: { group in
            Text("\(group.name) will be archived and its active student enrollments will be closed.")
        }
        .alert(
            "Unable to Delete Group",
            isPresented: Binding(
                get: { archiveErrorMessage != nil },
                set: { if !$0 { archiveErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { archiveErrorMessage = nil }
        } message: {
            Text(archiveErrorMessage ?? "")
        }
    }

    private func privateStudent(for group: Group) -> Student? {
        allEnrollments.first {
            $0.group.uuid == group.uuid && $0.isActive
        }?.student
    }

    private func archive(_ group: Group) {
        let associatedPrivateStudent = organization.type == .privateClient
            ? privateStudent(for: group)
            : nil

        group.isActive = false

        for enrollment in group.enrollments where enrollment.isActive {
            enrollment.isActive = false
            enrollment.endDate = .now
        }

        if let student = associatedPrivateStudent {
            student.isActive = false
        }

        do {
            try context.save()
        } catch {
            context.rollback()
            archiveErrorMessage = error.localizedDescription
        }

        groupToArchive = nil
    }
}
