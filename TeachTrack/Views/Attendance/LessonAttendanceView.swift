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

            $0.isActive
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

                        Text(
                            "\(enrollment.student.lastName) \(enrollment.student.firstName)"
                        )                    
                }
            }
        }
        .navigationTitle(
            "Attendance"
        )
    }
}



