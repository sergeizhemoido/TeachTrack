//
//  GroupDetailView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/10/26.
//

import SwiftUI
import SwiftData

struct GroupDetailView: View {

    let group: Group

    @Environment(\.modelContext)
    private var context

    @State
    private var showAddStudent = false

    @State
    private var showAddLesson = false

    @State
    private var showEditGroup = false

    @State
    private var showDeleteConfirmation = false

    @State
    private var enrollmentToRemove: Enrollment?

    @State
    private var lessonToDelete: Lesson?

    @Query
    private var enrollments: [Enrollment]

    @Query(
        sort: \Lesson.startDate,
        order: .forward
    )
    private var allLessons: [Lesson]

    // MARK: - Active Enrollments

    private var activeEnrollments: [Enrollment] {

        enrollments
            .filter {
                $0.group.uuid == group.uuid &&
                $0.isActive
            }
            .sorted {

                if $0.student.lastName != $1.student.lastName {
                    return $0.student.lastName < $1.student.lastName
                }

                return $0.student.firstName < $1.student.firstName
            }
    }

    // MARK: - Manual Lessons

    private var lessons: [Lesson] {

        allLessons
            .filter {
                $0.group.uuid == group.uuid &&
                $0.source != .generated
            }
    }

    // MARK: - Body

    var body: some View {

        List {

            // MARK: General

            Section("General") {

                Text(group.name)

                Text(
                    group.revenueModel.title
                )

                NavigationLink {

                    ScheduleRuleListView(
                        group: group
                    )

                } label: {

                    Label(
                        "Schedule",
                        systemImage: "calendar"
                    )
                }

                if let rate = group.ratePerStudent {

                    HStack {

                        Text("Rate Per Student")

                        Spacer()

                        Text(rate.formatted())
                    }
                }

                if let rate = group.fixedLessonRate {

                    HStack {

                        Text("Fixed Lesson Rate")

                        Spacer()

                        Text(rate.formatted())
                    }
                }
            }

            // MARK: Students

            Section("Students") {

                if activeEnrollments.isEmpty {

                    Text("No Students")
                        .foregroundStyle(.secondary)

                } else {

                    ForEach(
                        activeEnrollments,
                        id: \.uuid
                    ) { enrollment in

                        NavigationLink {

                            StudentDetailView(
                                student: enrollment.student
                            )

                        } label: {

                            VStack(
                                alignment: .leading
                            ) {

                                Text(
                                    "\(enrollment.student.lastName) \(enrollment.student.firstName)"
                                )

                                Text(
                                    enrollment.lessonPrice.formatted()
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }

                        .swipeActions(
                            edge: .trailing,
                            allowsFullSwipe: false
                        ) {

                            Button {

                                enrollmentToRemove = enrollment

                            } label: {

                                Label(
                                    "Remove",
                                    systemImage: "person.badge.minus"
                                )
                            }
                            .tint(.orange)
                        }
                    }
                }
            }

            // MARK: Lessons

            Section("Lessons") {

                if lessons.isEmpty {

                    Text("No Lessons")
                        .foregroundStyle(.secondary)

                } else {

                    ForEach(
                        lessons,
                        id: \.uuid
                    ) { lesson in

                        NavigationLink {

                            LessonDetailView(
                                lesson: lesson
                            )

                        } label: {

                            VStack(
                                alignment: .leading
                            ) {

                                Text(
                                    lesson.startDate,
                                    format: .dateTime
                                        .day()
                                        .month()
                                        .year()
                                )

                                Text(
                                    lesson.status.rawValue
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

                                lessonToDelete = lesson

                            } label: {

                                Label(
                                    "Delete",
                                    systemImage: "trash"
                                )
                            }
                        }
                    }
                }
            }
        }

        .navigationTitle(
            group.name
        )

        // MARK: Toolbar

        .toolbar {

            ToolbarItemGroup(
                placement: .topBarTrailing
            ) {

                Button("Edit") {

                    showEditGroup = true
                }

                Menu {

                    Button {

                        showAddStudent = true

                    } label: {

                        Label(
                            "Add Student",
                            systemImage: "person.badge.plus"
                        )
                    }

                    Button {

                        showAddLesson = true

                    } label: {

                        Label(
                            "Add Lesson",
                            systemImage: "calendar.badge.plus"
                        )
                    }

                } label: {

                    Image(
                        systemName: "plus"
                    )
                }
            }

            ToolbarItem(
                placement: .bottomBar
            ) {

                Button(
                    "Delete Group",
                    role: .destructive
                ) {

                    showDeleteConfirmation = true
                }
            }
        }

        // MARK: Edit Group

        .sheet(
            isPresented: $showEditGroup
        ) {

            EditGroupView(
                group: group
            )
        }

        // MARK: Add Student

        .sheet(
            isPresented: $showAddStudent
        ) {

            AddEnrollmentView(
                group: group
            )
        }

        // MARK: Add Lesson

        .sheet(
            isPresented: $showAddLesson
        ) {

            AddLessonView(
                group: group
            )
        }

        // MARK: Remove Student

        .confirmationDialog(
            "Remove Student from Group?",
            isPresented: Binding(
                get: {
                    enrollmentToRemove != nil
                },
                set: { isPresented in

                    if !isPresented {
                        enrollmentToRemove = nil
                    }
                }
            ),
            presenting: enrollmentToRemove
        ) { enrollment in

            Button(
                "Remove from Group",
                role: .destructive
            ) {

                enrollment.isActive = false
                enrollment.endDate = .now

                try? context.save()

                enrollmentToRemove = nil
            }

            Button(
                "Cancel",
                role: .cancel
            ) {

                enrollmentToRemove = nil
            }

        } message: { enrollment in

            Text(
                "This will end the student's current enrollment in \(group.name). The enrollment history will be preserved."
            )
        }

        // MARK: Delete Lesson

        .confirmationDialog(
            "Delete Lesson?",
            isPresented: Binding(
                get: {
                    lessonToDelete != nil
                },
                set: { isPresented in

                    if !isPresented {
                        lessonToDelete = nil
                    }
                }
            ),
            presenting: lessonToDelete
        ) { lesson in

            Button(
                "Delete Lesson",
                role: .destructive
            ) {

                context.delete(lesson)

                try? context.save()

                lessonToDelete = nil
            }

            Button(
                "Cancel",
                role: .cancel
            ) {

                lessonToDelete = nil
            }

        } message: { lesson in

            Text(
                "Are you sure you want to delete this lesson?"
            )
        }

        // MARK: Delete Group

        .confirmationDialog(
            "Delete Group?",
            isPresented: $showDeleteConfirmation
        ) {

            Button(
                "Delete",
                role: .destructive
            ) {

                group.isActive = false

                // Close active enrollments but preserve history.
                for enrollment in group.enrollments {

                    if enrollment.isActive {

                        enrollment.isActive = false
                        enrollment.endDate = .now
                    }
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
                "Are you sure you want to delete \(group.name)? Active student enrollments will be closed and preserved in history."
            )
        }
    }
}
