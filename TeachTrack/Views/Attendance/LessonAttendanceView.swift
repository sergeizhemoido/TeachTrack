//
//  LessonAttendanceView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/10/26.
//
import SwiftUI
import SwiftData

struct LessonAttendanceView: View {

    let lesson: Lesson

    @Query
    private var allEnrollments: [Enrollment]

    private var enrollments: [Enrollment] {

        allEnrollments.filter {

            $0.group.uuid ==
            lesson.group.uuid

            &&

            $0.enrollmentDate <= lesson.endDate &&
            ($0.endDate == nil || $0.endDate! >= lesson.startDate)
        }
    }

    var body: some View {

        List {

            ForEach(
                enrollments,
                id: \.uuid
            ) { enrollment in

                NavigationLink {

                    AttendanceEditorView(
                        lesson: lesson,
                        student: enrollment.student
                    )
                
                } label: {

                        HStack {
                            Text("\(enrollment.student.lastName) \(enrollment.student.firstName)")
                            Spacer()
                            Text(lesson.attendances.first(where: {
                                $0.student.uuid == enrollment.student.uuid
                            })?.status.title ?? "Not marked")
                                .foregroundStyle(.secondary)
                        }
                }
            }
        }
        .teachTrackScreen()
        .navigationTitle(
            "Attendance"
        )
    }
}

