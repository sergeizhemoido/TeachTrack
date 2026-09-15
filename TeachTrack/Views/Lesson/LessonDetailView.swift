//
//  LessonDetailView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/10/26.
//
import SwiftUI

struct LessonDetailView: View {

    let lesson: Lesson

    var body: some View {

        Form {

            Section("Lesson") {

                Text(
                    lesson.startDate,
                    format: .dateTime
                )

                Text(
                    lesson.endDate,
                    format: .dateTime
                )

                Text(
                    lesson.status.rawValue
                )
            }

            NavigationLink {

                LessonAttendanceView(
                    lesson: lesson
                )

            } label: {

                Label(
                    "Attendance",
                    systemImage: "checklist"
                )
            }
        }
        .navigationTitle(
            "Lesson"
        )
    }
}
