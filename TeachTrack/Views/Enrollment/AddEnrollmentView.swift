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
    private var alertTitle = ""

    @State
    private var alertMessage = ""

    @State
    private var showAlert = false

    private var availableStudents: [Student] {

        let requiredType: StudentType =
            group.organization?.type == .privateClient
            ? .privateClient
            : .regular

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
                        .accessibilityIdentifier("studentPicker")
                    }
                }
            }

            .teachTrackScreen()
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
                        selectedStudent == nil
                    )
                }
            }

            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func save() {

        guard let student = selectedStudent else {
            return
        }

        let alreadyEnrolled = allEnrollments.contains { enrollment in

            enrollment.student.uuid == student.uuid &&
            enrollment.group.uuid == group.uuid &&
            enrollment.isActive
        }

        guard !alreadyEnrolled else {

            alertTitle = "Student Already Enrolled"
            alertMessage = "This student is already actively enrolled in this group."
            showAlert = true
            return
        }

        let lessonPrice: Decimal?
        if group.revenueModel == .perStudent {
            guard let rate = group.ratePerStudent else {
                alertTitle = "Rate Required"
                alertMessage = "Set a rate per student in the group details before enrolling a student."
                showAlert = true
                return
            }
            lessonPrice = rate
        } else {
            lessonPrice = nil
        }

        let enrollment = Enrollment(
            student: student,
            group: group,
            lessonPrice: lessonPrice
        )

        context.insert(enrollment)

        do {

            try context.save()

            dismiss()

        } catch {
            alertTitle = "Unable to Save Enrollment"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
