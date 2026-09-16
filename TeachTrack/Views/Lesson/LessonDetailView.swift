import SwiftUI
import SwiftData

struct LessonDetailView: View {

    let lesson: Lesson

    @Environment(\.modelContext)
    private var context

    @State
    private var showEditLesson = false

    @State
    private var showCancelConfirmation = false

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
        .navigationTitle("Lesson")
        .toolbar {

            ToolbarItem(
                placement: .topBarTrailing
            ) {

                Button("Edit") {
                    showEditLesson = true
                }
            }

            if lesson.status != .cancelled {

                ToolbarItem(
                    placement: .bottomBar
                ) {

                    Button(
                        "Cancel Lesson",
                        role: .destructive
                    ) {

                        showCancelConfirmation = true
                    }
                }
            }
        }
        .sheet(
            isPresented: $showEditLesson
        ) {

            EditLessonView(
                lesson: lesson
            )
        }
        .confirmationDialog(
            "Cancel Lesson?",
            isPresented: $showCancelConfirmation
        ) {

            Button(
                "Cancel Lesson",
                role: .destructive
            ) {

                lesson.status = .cancelled
                try? context.save()
            }

            Button(
                "Keep Lesson",
                role: .cancel
            ) {
            }

        } message: {

            Text(
                "Are you sure you want to cancel this lesson?"
            )
        }
    }
}
