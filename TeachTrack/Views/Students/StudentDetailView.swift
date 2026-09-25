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

            Section("Student") {

                Text(
                    "\(student.firstName) \(student.lastName)"
                )

        //        if let phone = student.phone {

        //            Text(phone)
        //        }

        //        if let email = student.email {

        //            Text(email)
        //        }
            }

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

                    Label(
                        "Contacts",
                        systemImage: "person.2"
                    )
                }
            }

            Section("Finance") {

                NavigationLink {

                    StudentBalanceView(
                        student: student
                    )

                } label: {

                    Label(
                        "Balance",
                        systemImage: "dollarsign.circle"
                    )
                }

                NavigationLink {

                    TransactionListView(
                        student: student
                    )

                } label: {

                    Label(
                        "Transactions",
                        systemImage: "list.bullet.rectangle"
                    )
                }

                NavigationLink {

                    AddPaymentView(
                        student: student
                    )

                } label: {

                    Label(
                        "Add Payment",
                        systemImage: "plus.circle"
                    )
                }
            }
        }

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
