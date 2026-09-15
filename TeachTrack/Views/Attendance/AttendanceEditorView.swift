//
//  AttendanceEditorView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/10/26.
//
import SwiftUI
import SwiftData

struct AttendanceEditorView: View {

    let lesson: Lesson

    let student: Student

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    @Query
    private var attendances: [Attendance]

    @State
    private var selectedStatus: AttendanceStatus = .present

    @State
    private var notes = ""

    private var existingAttendance: Attendance? {

        attendances.first {

            $0.lesson.uuid == lesson.uuid
            &&
            $0.student.uuid == student.uuid
        }
    }

    var body: some View {

        Form {

            Section("Student") {

                Text(
                    "\(student.lastName) \(student.firstName)"
                )
            }

            Section("Attendance") {

                Picker(
                    "Status",
                    selection: $selectedStatus
                ) {

                    ForEach(
                        AttendanceStatus.allCases,
                        id: \.self
                    ) { status in

                        Text(
                            status.title
                        )
                        .tag(status)
                    }
                }
                .pickerStyle(.inline)
            }

            Section("Notes") {

                TextField(
                    "Notes",
                    text: $notes,
                    axis: .vertical
                )
            }
        }
        .navigationTitle(
            "Attendance"
        )

        .onAppear {

            guard
                let attendance =
                    existingAttendance
            else {
                return
            }

            selectedStatus =
                attendance.status

            notes =
                attendance.notes ?? ""
        }

        .toolbar {

            ToolbarItem(
                placement: .confirmationAction
            ) {

                Button("Save") {

                    saveAttendance()
                }
            }
        }
    }

    private func saveAttendance() {

        if let attendance =
            existingAttendance {

            attendance.status =
                selectedStatus

            attendance.notes =
                notes.isEmpty
                ? nil
                : notes

        } else {

            let attendance =
                Attendance(
                    student: student,
                    lesson: lesson,
                    status: selectedStatus
                )

            attendance.notes =
                notes.isEmpty
                ? nil
                : notes

            context.insert(
                attendance
            )
        }

        try? context.save()

        dismiss()
    }
}

#Preview {
    let organization = Organization(
        name: "Test School",
        type: .school
    )

    let group = Group(
        name: "Test Group",
        revenueModel: .perStudent,
        organization: organization
    )

    let lesson = Lesson(
        group: group,
        startDate: Date(),
        endDate: Date().addingTimeInterval(60 * 60),
        source: .manual
    )

    let student = Student(
        firstName: "John",
        lastName: "Smith"
    )

    AttendanceEditorView(
        lesson: lesson,
        student: student
    )
    .modelContainer(
        for: [
            Organization.self,
            Group.self,
            Lesson.self,
            Student.self,
            Attendance.self
        ],
        inMemory: true
    )
}
