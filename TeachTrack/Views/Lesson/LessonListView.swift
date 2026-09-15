//
//  LessonListView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/10/26.
//
import SwiftUI
import SwiftData

struct LessonListView: View {

    let group: Group

    @Query(
        sort: \Lesson.startDate,
        order: .reverse
    )
    private var allLessons: [Lesson]

    @State
    private var showAddLesson = false

    private var lessons: [Lesson] {

        allLessons.filter {
            $0.group.uuid == group.uuid
        }
    }

    var body: some View {

        List {

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
        .navigationTitle(
            "Lessons"
        )
        .toolbar {

            Button {

                showAddLesson = true

            } label: {

                Image(systemName: "plus")
            }
        }
        .sheet(
            isPresented: $showAddLesson
        ) {

            AddLessonView(
                group: group
            )
        }
    }
}
