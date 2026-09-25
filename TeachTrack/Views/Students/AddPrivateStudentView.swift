//
//  AddPrivateStudentView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 9/23/26.
//

import SwiftUI
import SwiftData

struct AddPrivateStudentView: View {

    let organization: Organization

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    @State
    private var firstName = ""

    @State
    private var lastName = ""

    @State
    private var phone = ""

    @State
    private var email = ""

    @State
    private var lessonPrice = ""

    var body: some View {

        NavigationStack {

            Form {

                Section("Student") {

                    TextField(
                        "First Name",
                        text: $firstName
                    )

                    TextField(
                        "Last Name",
                        text: $lastName
                    )

             //       TextField(
             //           "Phone",
             //           text: $phone
             //       )
             //       .keyboardType(.phonePad)

             //       TextField(
             //           "Email",
             //           text: $email
             //       )
             //       .keyboardType(.emailAddress)
             //       .textInputAutocapitalization(.never)
                }

                Section("Lesson") {

                    TextField(
                        "Lesson Price",
                        text: $lessonPrice
                    )
                    .keyboardType(.decimalPad)
                }
            }

            .navigationTitle("New Private Student")
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
                        firstName
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty
                        ||
                        lastName
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )
                            .isEmpty
                    )
                }
            }
        }
    }

    private func save() {

        let cleanFirstName =
            firstName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let cleanLastName =
            lastName.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let price =
            Decimal(string: lessonPrice) ?? 0

        // Private students are always created
        // with the privateClient student type.
        let student = Student(
            firstName: cleanFirstName,
            lastName: cleanLastName,
            studentType: .privateClient
        )

        student.phone =
            phone.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        student.email =
            email.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        // Each private student gets an individual group.
        // The group belongs to the selected Private Client organization.
        let group = Group(
            name: "\(cleanFirstName) \(cleanLastName)",
            revenueModel: .perStudent,
            organization: organization
        )

        group.ratePerStudent = price
        group.fixedLessonRate = nil

        let enrollment = Enrollment(
            student: student,
            group: group,
            lessonPrice: price
        )

        context.insert(student)
        context.insert(group)
        context.insert(enrollment)

        do {

            try context.save()
            dismiss()

        } catch {

            print(
                "Failed to save private student: \(error)"
            )
        }
    }
}

