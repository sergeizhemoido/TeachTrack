//
//  StudentsListView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/9/26.
//
import SwiftUI
import SwiftData

struct StudentsListView: View {

    @Environment(\.modelContext)
    private var context

    @Query(
        filter: #Predicate<Student> {
            $0.isActive == true
        },
        sort: \Student.lastName
    )
    private var students: [Student]

    @State
    private var showAddStudent = false

    var body: some View {

        NavigationStack {
            List {
                ForEach(students) { student in
                    NavigationLink {
                        StudentDetailView(
                            student: student
                        )
                    } label: {
                        VStack(alignment: .leading) {
                            Text(
                                "\(student.lastName) \(student.firstName)"
                            )
                            if let phone = student.phone {
                                Text(phone)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Students")
            .toolbar {
                Button {
                    showAddStudent = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(
                isPresented: $showAddStudent
            ) {
                AddStudentView()
            }
        }
    }
}
