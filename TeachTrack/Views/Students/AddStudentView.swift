//
//  AddStudentView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/9/26.
//
import SwiftUI
import SwiftData

struct AddStudentView: View {

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    @State
    private var firstName = ""

    @State
    private var lastName = ""

    var body: some View {

        NavigationStack {

            Form {
                TextField(
                    "First Name",
                    text: $firstName
                )
                TextField(
                    "Last Name",
                    text: $lastName
                )
            }
            .navigationTitle("New Student")
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
                        let service =
                            StudentService(
                                context: context
                            )
                        try? service.createStudent(
                            firstName: firstName,
                            lastName: lastName
                        )
                        dismiss()
                    }
                    .disabled(
                        firstName.isEmpty ||
                        lastName.isEmpty
                    )
                }
            }
        }
    }
}
