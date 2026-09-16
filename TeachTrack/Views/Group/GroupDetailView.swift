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

    @Query
    private var enrollments: [Enrollment]

    @Query(
        sort: \Lesson.startDate,
        order: .reverse
    )
    private var allLessons: [Lesson]

    private var activeEnrollments: [Enrollment] {

        enrollments.filter {
            $0.group.uuid == group.uuid &&
            $0.isActive
        }
    }

    private var lessons: [Lesson] {

        allLessons.filter {
            $0.group.uuid == group.uuid
        }
    }

    var body: some View {

        List {

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

            Section("Students") {

                if activeEnrollments.isEmpty {

                    Text("No Students")
                        .foregroundStyle(.secondary)
                }

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
                }
            }

            Section("Lessons") {

                if lessons.isEmpty {

                    Text("No Lessons")
                        .foregroundStyle(.secondary)
                }

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
                }
            }
        }

        .navigationTitle(
            group.name
        )

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

        .sheet(
            isPresented: $showEditGroup
        ) {

            EditGroupView(
                group: group
            )
        }

        .sheet(
            isPresented: $showAddStudent
        ) {

            AddEnrollmentView(
                group: group
            )
        }

        .sheet(
            isPresented: $showAddLesson
        ) {

            AddLessonView(
                group: group
            )
        }

        .confirmationDialog(
            "Delete Group?",
            isPresented: $showDeleteConfirmation
        ) {

            Button(
                "Delete",
                role: .destructive
            ) {

                group.isActive = false

                try? context.save()
            }

            Button(
                "Cancel",
                role: .cancel
            ) {
            }

        } message: {

            Text(
                "Are you sure you want to delete \(group.name)?"
            )
        }
    }
}

