import SwiftUI
import SwiftData

struct LessonDetailView: View {

    let lesson: Lesson

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    @Query private var transactions: [Transaction]

    @State
    private var showEditLesson = false

    @State
    private var showCancelConfirmation = false

    @State
    private var showDeleteConfirmation = false

    @State
    private var actionErrorMessage: String?

    private var lessonCharge: Decimal {
        transactions.filter {
            $0.type == .charge && $0.lesson?.uuid == lesson.uuid
        }.reduce(Decimal.zero) { $0 + $1.amount }
    }

    var body: some View {

        Form {
            TeachTrackHero(
                eyebrow: "Lesson · \(lesson.status.rawValue.capitalized)",
                title: lesson.group.name,
                detail: lesson.startDate.formatted(date: .abbreviated, time: .shortened),
                symbol: "calendar.badge.clock",
                color: TeachTrackDesign.sky
            )

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

            if !lesson.group.isPrivate || lesson.group.revenueModel == .perStudent {
                NavigationLink {
                    LessonAttendanceView(lesson: lesson)
                } label: {
                    Label("Attendance", systemImage: "checklist")
                }
            }

            Section("Attendance History") {
                if lesson.attendances.isEmpty {
                    Text("No attendance marked")
                        .foregroundStyle(.secondary)
                }
                ForEach(lesson.attendances, id: \.uuid) { attendance in
                    LabeledContent(
                        "\(attendance.student.lastName) \(attendance.student.firstName)",
                        value: attendance.status.title
                    )
                }
            }

            Section("Billing") {
                LabeledContent("Lesson Charges", value: lessonCharge.formatted())
                if lesson.status == .planned {
                    Text("Mark every student's attendance, then set the lesson to completed or cancelled.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .teachTrackScreen()
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
            try LessonBillingService.syncCharge(for: lesson, context: context)
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
