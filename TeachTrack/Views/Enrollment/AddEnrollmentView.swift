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
    private var students: [Student]

    @State
    private var selectedStudent: Student?

    @State
    private var lessonPrice = ""

    var body: some View {

        NavigationStack {

            Form {

                Section("Student") {

                    Picker(
                        "Student",
                        selection: $selectedStudent
                    ) {

                        Text("Select Student")
                            .tag(nil as Student?)

                        ForEach(
                            students,
                            id: \.uuid
                        ) { student in

                            Text(
                                "\(student.lastName) \(student.firstName)"
                            )
                            .tag(student as Student?)
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
            .navigationTitle(
                "Add Student"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )

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

                        guard
                            let student = selectedStudent,
                            let price = Decimal(
                                string: lessonPrice
                            )
                        else {
                            return
                        }

                        let enrollment =
                            Enrollment(
                                student: student,
                                group: group,
                                lessonPrice: price
                            )

                        context.insert(
                            enrollment
                        )

                        try? context.save()

                        dismiss()
                    }
                    .disabled(
                        selectedStudent == nil
                    )
                }
            }
        }
    }
}
