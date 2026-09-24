import SwiftUI
import SwiftData

struct LessonDetailView: View {

    let lesson: Lesson

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    @State
    private var showEditLesson = false

    @State
    private var showCancelConfirmation = false

    @State
    private var showDeleteConfirmation = false

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

                Text(
                    lesson.source == .generated
                    ? "Generated from schedule"
                    : "Manual lesson"
                )
                .foregroundStyle(.secondary)
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

            ToolbarItem(
                placement: .bottomBar
            ) {

                HStack {

                    if lesson.status != .cancelled {

                        Button(
                            "Cancel Lesson",
                            role: .destructive
                        ) {

                            showCancelConfirmation = true
                        }
                    }

                    Spacer()

                    Button(
                        "Delete Lesson",
                        role: .destructive
                    ) {

                        showDeleteConfirmation = true
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
                "The lesson will remain in the calendar as cancelled."
            )
        }

        .confirmationDialog(
            "Delete Lesson?",
            isPresented: $showDeleteConfirmation
        ) {

            Button(
                "Delete Lesson",
                role: .destructive
            ) {

                LessonGenerator.deleteGeneratedLesson(
                    lesson,
                    context: context
                )

                dismiss()
            }

            Button(
                "Cancel",
                role: .cancel
            ) {
            }

        } message: {

            if lesson.source == .generated {

                Text(
                    "This lesson was generated from the schedule. " +
                    "If you generate lessons for this period again, " +
                    "this lesson may be created again."
                )

            } else {

                Text(
                    "This lesson will be permanently deleted."
                )
            }
        }
    }
}
