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

    private var privateGroups: [Group] {
        student.enrollments
            .filter {
                $0.isActive &&
                $0.group.isActive &&
                $0.group.organization == nil
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

            if !privateGroups.isEmpty {

                Section("Private Lessons") {

                    ForEach(
                        privateGroups,
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
                                        verbatim: "Lesson price: \(rate)"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(
                                        .secondary
                                    )

                                } else if
                                    group.revenueModel == .fixedPerLesson,
                                    let rate = group.fixedLessonRate {

                                    Text(
                                        verbatim: "Lesson price: \(rate)"
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

                student.isActive = false

                try? context.save()
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
    }
}
