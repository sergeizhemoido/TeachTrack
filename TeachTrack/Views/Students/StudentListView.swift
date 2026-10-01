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
            TeachTrackHero(
                eyebrow: "People",
                title: "Student directory",
                detail: "Contact details, enrollments, lessons, and accounts at a glance.",
                symbol: "person.3.sequence",
                color: TeachTrackDesign.sunflower
            )

            if students.isEmpty {
                TeachTrackEmptyState(
                    title: "No students yet",
                    detail: "Use the add button to create a student profile.",
                    symbol: "person.crop.circle.badge.plus",
                    color: TeachTrackDesign.studentGreen
                )
            } else {
            Section("Students · \(students.count)") {

            ForEach(
                students,
                id: \.uuid
            ) { student in

                NavigationLink {

                    StudentDetailView(
                        student: student
                    )

                } label: {

                    TeachTrackIconRow(
                        title: "\(student.lastName) \(student.firstName)",
                        detail: student.studentType.title,
                        symbol: student.studentType == .privateClient ? "person.crop.circle.fill" : "person.crop.circle",
                        color: student.studentType == .privateClient ? TeachTrackDesign.violet : TeachTrackDesign.studentGreen
                    )
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
                    .tint(.red)
                }
            }
            }
            }
        }
        .teachTrackScreen()

        .navigationTitle("Students")
        .navigationBarTitleDisplayMode(.inline)

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
                .accessibilityIdentifier("addRegularStudentButton")
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
