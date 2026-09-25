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

    @Query
    private var allStudents: [Student]

    @Query
    private var allEnrollments: [Enrollment]

    @State
    private var selectedStudent: Student?

    @State
    private var showDuplicateWarning = false

    private var availableStudents: [Student] {

        let requiredType: StudentType =
            group.organization?.type == .privateClient
            ? .privateClient
            : .regular

        print("")
        print("========== AddEnrollmentView ==========")

        print("GROUP:")
        print("  Name:", group.name)

        print("ORGANIZATION:")
        print(
            "  Name:",
            group.organization?.name ?? "nil"
        )

        print(
            "  Type:",
            group.organization?.type.rawValue ?? "nil"
        )

        print("STUDENT FILTER:")
        print(
            "  Required type:",
            requiredType.rawValue
        )

        print("ALL ACTIVE STUDENTS:")

        for student in allStudents where student.isActive {

            print(
                "  \(student.lastName) \(student.firstName)",
                "| studentType:",
                student.studentType.rawValue
            )
        }

        let result = allStudents.filter { student in

            guard student.isActive else {
                return false
            }

            guard student.studentType == requiredType else {
                return false
            }

            let alreadyEnrolled = allEnrollments.contains { enrollment in

                enrollment.student.uuid == student.uuid &&
                enrollment.group.uuid == group.uuid &&
                enrollment.isActive
            }

            return !alreadyEnrolled
        }

        print("AVAILABLE STUDENTS:")

        for student in result {

            print(
                "  \(student.lastName) \(student.firstName)",
                "| studentType:",
                student.studentType.rawValue
            )
        }

        print("=======================================")
        print("")

        return result
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

                    Button("Add") {
                        save()
                    }
                    .disabled(
                        selectedStudent == nil
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

        guard let student = selectedStudent else {
            return
        }

        print("")
        print("========== SAVING ENROLLMENT ==========")
        print(
            "Student:",
            student.firstName,
            student.lastName
        )
        print(
            "Student type:",
            student.studentType.rawValue
        )
        print(
            "Group:",
            group.name
        )
        print(
            "Organization:",
            group.organization?.name ?? "nil"
        )
        print(
            "Organization type:",
            group.organization?.type.rawValue ?? "nil"
        )

        let alreadyEnrolled = allEnrollments.contains { enrollment in

            enrollment.student.uuid == student.uuid &&
            enrollment.group.uuid == group.uuid &&
            enrollment.isActive
        }

        guard !alreadyEnrolled else {

            print("RESULT: Already enrolled")
            print("=======================================")
            print("")

            showDuplicateWarning = true
            return
        }

        guard let price = group.ratePerStudent else {

            print("RESULT: No ratePerStudent")
            print("=======================================")
            print("")

            return
        }

        let enrollment = Enrollment(
            student: student,
            group: group,
            lessonPrice: price
        )

        context.insert(enrollment)

        do {

            try context.save()

            print("RESULT: Enrollment saved successfully")
            print("=======================================")
            print("")

            dismiss()

        } catch {

            print(
                "RESULT: Failed to save enrollment:",
                error
            )
            print("=======================================")
            print("")

        }
    }
}
