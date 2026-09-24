//
//  MoveStudentView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 9/24/26.
//
import SwiftUI
import SwiftData

struct MoveStudentView: View {

    let enrollment: Enrollment

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    @Query(
        filter: #Predicate<Group> {
            $0.isActive
        },
        sort: \Group.name
    )
    private var allGroups: [Group]

    @Query
    private var allEnrollments: [Enrollment]

    @State
    private var selectedGroup: Group?

    @State
    private var lessonPrice: String

    init(enrollment: Enrollment) {

        self.enrollment = enrollment

        _lessonPrice = State(
            initialValue: enrollment.lessonPrice.description
        )
    }

    private var availableGroups: [Group] {

        allGroups.filter { group in

            // Do not show the current group.
            guard group.uuid != enrollment.group.uuid else {
                return false
            }

            // Do not show groups where the student
            // already has an active enrollment.
            let alreadyEnrolled = allEnrollments.contains { existing in

                existing.student.uuid == enrollment.student.uuid &&
                existing.group.uuid == group.uuid &&
                existing.isActive
            }

            return !alreadyEnrolled
        }
    }

    var body: some View {

        NavigationStack {

            Form {

                Section("Student") {

                    Text(
                        "\(enrollment.student.firstName) \(enrollment.student.lastName)"
                    )
                }

                Section("Current Group") {

                    Text(
                        enrollment.group.name
                    )
                    .foregroundStyle(.secondary)
                }

                Section("New Group") {

                    if availableGroups.isEmpty {

                        Text(
                            "No available groups"
                        )
                        .foregroundStyle(.secondary)

                    } else {

                        Picker(
                            "Group",
                            selection: $selectedGroup
                        ) {

                            Text("Select Group")
                                .tag(nil as Group?)

                            ForEach(
                                availableGroups,
                                id: \.uuid
                            ) { group in

                                Text(group.name)
                                    .tag(group as Group?)
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

            .navigationTitle("Move Student")
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

                    Button("Move") {
                        moveStudent()
                    }
                    .disabled(
                        selectedGroup == nil ||
                        Decimal(string: lessonPrice) == nil
                    )
                }
            }
        }
    }

    private func moveStudent() {

        guard let newGroup = selectedGroup,
              let price = Decimal(
                  string: lessonPrice
              )
        else {
            return
        }

        let studentID = enrollment.student.uuid
        let newGroupID = newGroup.uuid

        // Final protection against creating
        // a duplicate active enrollment.
        let descriptor = FetchDescriptor<Enrollment>(
            predicate: #Predicate<Enrollment> {
                $0.student.uuid == studentID &&
                $0.group.uuid == newGroupID &&
                $0.isActive
            }
        )

        let alreadyEnrolled =
            ((try? context.fetchCount(descriptor)) ?? 0) > 0

        guard !alreadyEnrolled else {
            return
        }

        // Close the current enrollment.
        enrollment.isActive = false
        enrollment.endDate = .now

        // Create a new enrollment in the new group.
        let newEnrollment = Enrollment(
            student: enrollment.student,
            group: newGroup,
            lessonPrice: price
        )

        context.insert(newEnrollment)

        try? context.save()

        dismiss()
    }
}
