import SwiftUI
import SwiftData

struct LessonListView: View {

    let group: Group

    @Environment(\.modelContext)
    private var context

    @Query(
        sort: \Lesson.startDate,
        order: .reverse
    )
    private var allLessons: [Lesson]

    @State
    private var showAddLesson = false

    @State
    private var lessonToCancel: Lesson?

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
                .swipeActions(
                    edge: .trailing,
                    allowsFullSwipe: false
                ) {

                    if lesson.status != .cancelled {

                        Button {
                            lessonToCancel = lesson
                        } label: {
                            Label(
                                "Cancel",
                                systemImage: "xmark.circle"
                            )
                        }
                        .tint(.orange)
                    }
                }
            }
        }
        .navigationTitle("Lessons")
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
        .confirmationDialog(
            "Cancel Lesson?",
            isPresented: Binding(
                get: {
                    lessonToCancel != nil
                },
                set: { isPresented in
                    if !isPresented {
                        lessonToCancel = nil
                    }
                }
            ),
            presenting: lessonToCancel
        ) { lesson in

            Button(
                "Cancel Lesson",
                role: .destructive
            ) {

                lesson.status = .cancelled
                try? context.save()

                lessonToCancel = nil
            }

            Button(
                "Keep Lesson",
                role: .cancel
            ) {

                lessonToCancel = nil
            }

        } message: { lesson in

            Text(
                "Are you sure you want to cancel this lesson?"
            )
        }
    }
}
