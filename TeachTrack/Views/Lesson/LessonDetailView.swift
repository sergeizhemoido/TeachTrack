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

    @State
    private var actionErrorMessage: String?

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

            if lesson.group.revenueModel == .perStudent {
                NavigationLink {
                    LessonAttendanceView(lesson: lesson)
                } label: {
                    Label("Attendance", systemImage: "checklist")
                }
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

                cancelLesson()
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

                deleteLesson()
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
        .alert(
            "Unable to Update Lesson",
            isPresented: Binding(
                get: { actionErrorMessage != nil },
                set: { if !$0 { actionErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { actionErrorMessage = nil }
        } message: {
            Text(actionErrorMessage ?? "")
        }
    }

    private func cancelLesson() {
        lesson.status = .cancelled
        do {
            try FixedLessonBillingService.syncCharge(for: lesson, context: context)
            try context.save()
        } catch {
            context.rollback()
            actionErrorMessage = error.localizedDescription
        }
    }

    private func deleteLesson() {
        do {
            try LessonGenerator.deleteGeneratedLesson(lesson, context: context)
            dismiss()
        } catch {
            context.rollback()
            actionErrorMessage = error.localizedDescription
        }
    }
}
