//
//  AddEnrollmentView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/10/26.
//
import SwiftUI
import SwiftData

struct AddEnrollmentView: View {

    let group: Group

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    @Query(
        filter: #Predicate<Student> {
            $0.isActive
        },
        sort: \Student.lastName
    )
    private var allStudents: [Student]

    @Query
    private var allEnrollments: [Enrollment]

    @State
    private var selectedStudent: Student?

    @State
    private var lessonPrice = ""

    @State
    private var showDuplicateWarning = false

    // Students who do NOT currently have
    // an active enrollment in this group.
    private var availableStudents: [Student] {

        allStudents.filter { student in

            !allEnrollments.contains { enrollment in

                enrollment.student.uuid == student.uuid &&
                enrollment.group.uuid == group.uuid &&
                enrollment.isActive
            }
        }
    }

    var body: some View {

        NavigationStack {

            Form {

                Section("Student") {

                    if availableStudents.isEmpty {

                        Text("No available students")
                            .foregroundStyle(.secondary)

                    } else {

                        Picker(
                            "Student",
                            selection: $selectedStudent
                        ) {

                            Text("Select Student")
                                .tag(nil as Student?)

                            ForEach(
                                availableStudents,
                                id: \.uuid
                            ) { student in

                                Text(
                                    "\(student.lastName) \(student.firstName)"
                                )
                                .tag(student as Student?)
                            }
                        }
                    }
                }

                Section("Lesson Price") {

                    TextField(
                        "Price",
                        text: $lessonPrice
                    )
                    .keyboardType(.decimalPad)
                }
            }

            .navigationTitle("Add Student")
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {

                ToolbarItem(
                    placement: .cancellationAction
                ) {

                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {

                    Button("Save") {
                        save()
                    }
                    .disabled(
                        selectedStudent == nil ||
                        Decimal(string: lessonPrice) == nil
                    )
                }
            }

            .alert(
                "Student Already Enrolled",
                isPresented: $showDuplicateWarning
            ) {

                Button("OK", role: .cancel) {
                }

            } message: {

                Text(
                    "This student is already actively enrolled in this group."
                )
            }
        }
    }

    private func save() {

        guard
            let student = selectedStudent,
            let price = Decimal(
                string: lessonPrice
            )
        else {
            return
        }

        let studentID = student.uuid
        let groupID = group.uuid

        // Final protection against creating
        // two active enrollments for the same
        // student in the same group.
        let descriptor = FetchDescriptor<Enrollment>(
            predicate: #Predicate<Enrollment> {
                $0.student.uuid == studentID &&
                $0.group.uuid == groupID &&
                $0.isActive
            }
        )

        let alreadyEnrolled =
            ((try? context.fetchCount(descriptor)) ?? 0) > 0

        guard !alreadyEnrolled else {

            showDuplicateWarning = true
            return
        }

        // A new enrollment is always created.
        // Previous inactive enrollments remain
        // in the database as history.
        let enrollment = Enrollment(
            student: student,
            group: group,
            lessonPrice: price
        )

        context.insert(enrollment)

        do {
            try context.save()
            dismiss()

        } catch {
            print(
                "Failed to save enrollment: \(error)"
            )
        }
    }
}
