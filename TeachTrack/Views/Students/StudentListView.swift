//
//  StudentsListView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/9/26.
//

import SwiftUI
import SwiftData

struct StudentListView: View {

    @Environment(\.modelContext)
    private var context

    @Query(
        filter: #Predicate<Student> {
            $0.isActive
        },
        sort: [
            SortDescriptor(\Student.lastName),
            SortDescriptor(\Student.firstName)
        ]
    )
    private var students: [Student]

    @State
    private var showAddStudent = false

    @State
    private var studentToDelete: Student?

    var body: some View {

        List {

            ForEach(
                students,
                id: \.uuid
            ) { student in

                NavigationLink {

                    StudentDetailView(
                        student: student
                    )

                } label: {

                    VStack(
                        alignment: .leading
                    ) {

                        Text(
                            "\(student.lastName) \(student.firstName)"
                        )

                        Text(
                            student.studentType.title
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .swipeActions(
                    edge: .trailing,
                    allowsFullSwipe: false
                ) {

                    Button(role: .destructive) {

                        studentToDelete = student

                    } label: {

                        Label(
                            "Delete",
                            systemImage: "trash"
                        )
                    }
                }
            }
        }

        .navigationTitle("Students")

        .toolbar {

            ToolbarItem(
                placement: .topBarTrailing
            ) {

                Button {

                    showAddStudent = true

                } label: {

                    Label(
                        "Add Student",
                        systemImage: "person.badge.plus"
                    )
                }
            }
        }

        .sheet(
            isPresented: $showAddStudent
        ) {

            AddStudentView()
        }

        .confirmationDialog(
            "Delete Student?",
            isPresented: Binding(
                get: {
                    studentToDelete != nil
                },
                set: { isPresented in

                    if !isPresented {
                        studentToDelete = nil
                    }
                }
            ),
            presenting: studentToDelete
        ) { student in

            Button(
                "Delete",
                role: .destructive
            ) {

                student.isActive = false

                do {
                    try context.save()
                } catch {
                    print(
                        "Failed to archive student: \(error)"
                    )
                }

                studentToDelete = nil
            }

            Button(
                "Cancel",
                role: .cancel
            ) {

                studentToDelete = nil
            }

        } message: { student in

            Text(
                "Are you sure you want to delete \(student.firstName) \(student.lastName)?"
            )
        }
    }
}

