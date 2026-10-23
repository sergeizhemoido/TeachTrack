import SwiftUI
import SwiftData

struct StudentDetailView: View {

    let student: Student

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    @State
    private var showEditStudent = false

    @State
    private var showDeleteConfirmation = false

    @State private var archiveErrorMessage: String?

    private var activeGroups: [Group] {
        student.enrollments
            .filter {
                $0.isActive &&
                $0.group.isActive
            }
            .map {
                $0.group
            }
    }

    var body: some View {

        Form {
            TeachTrackHero(
                eyebrow: "Student profile",
                title: "\(student.firstName) \(student.lastName)",
                detail: student.studentType.title,
                symbol: "person.crop.circle.fill",
                color: student.studentType == .privateClient ? TeachTrackDesign.violet : TeachTrackDesign.studentGreen
            )

            if !activeGroups.isEmpty {

                Section("Groups") {

                    ForEach(
                        activeGroups,
                        id: \.uuid
                    ) { group in

                        NavigationLink {

                            GroupDetailView(
                                group: group
                            )

                        } label: {

                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {

                                Text(
                                    group.name
                                )

                                if group.revenueModel == .perStudent,
                                   let rate = group.ratePerStudent {

                                    Text(
                                        verbatim: "Future lesson rate: \(rate.moneyFormatted)"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(
                                        .secondary
                                    )

                                } else if
                                    group.revenueModel == .fixedPerLesson,
                                    let rate = group.fixedLessonRate {

                                    Text(
                                        verbatim: "Lesson price: \(rate.moneyFormatted)"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(
                                        .secondary
                                    )
                                }
                            }
                        }
                    }
                }
            }

            Section("Contacts") {

                NavigationLink {

                    ContactListView(
                        student: student
                    )

                } label: {

                    TeachTrackIconRow(
                        title: "Contacts",
                        detail: "Phone, email, and relatives",
                        symbol: "person.2"
                    )
                }
                .accessibilityLabel("Contacts")
            }

            Section("Finance") {

                NavigationLink {

                    AccountStatementView(
                        student: student
                    )

                } label: {

                    TeachTrackIconRow(
                        title: "Account and History",
                        detail: "Balance and transaction history",
                        symbol: "dollarsign.circle"
                    )
                }
                .accessibilityLabel("Account and History")
            }
        }

        .teachTrackScreen()
        .navigationTitle(
            "\(student.firstName) \(student.lastName)"
        )

        .toolbar {

            ToolbarItem(
                placement: .topBarTrailing
            ) {

                Button("Edit") {

                    showEditStudent = true
                }
            }

            ToolbarItem(
                placement: .bottomBar
            ) {

                Button(
                    "Delete Student",
                    role: .destructive
                ) {

                    showDeleteConfirmation = true
                }
            }
        }

        .sheet(
            isPresented: $showEditStudent
        ) {

            EditStudentView(
                student: student
            )
        }

        .confirmationDialog(
            "Delete Student?",
            isPresented: $showDeleteConfirmation
        ) {

            Button(
                "Delete",
                role: .destructive
            ) {

                do {
                    try StudentService(context: context).archiveStudent(student)
                    dismiss()
                } catch {
                    context.rollback()
                    archiveErrorMessage = error.localizedDescription
                }
            }

            Button(
                "Cancel",
                role: .cancel
            ) {
            }

        } message: {

            Text(
                "Are you sure you want to delete \(student.firstName) \(student.lastName)?"
            )
        }
        .alert("Unable to Delete Student", isPresented: Binding(
            get: { archiveErrorMessage != nil },
            set: { if !$0 { archiveErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { archiveErrorMessage = nil }
        } message: {
            Text(archiveErrorMessage ?? "")
        }
    }
}
