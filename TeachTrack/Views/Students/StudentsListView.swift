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
    
    @State
    private var studentToDelete: Student?

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
                    
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                student.isActive = false
                            } label: {
                                Label("Delete", systemImage: "trash")
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
            
            .confirmationDialog(
                "Delete Student?",
                isPresented: Binding(
                    get: {
                        studentToDelete != nil
                    },
                    set: { isPresented in
                        if !isPresented {
                            studentToDelete = nil
                        }
                    }
                ),
                presenting: studentToDelete
            ) { student in
                Button(
                    "Delete",
                    role: .destructive
                ) {
                    student.isActive = false
                    try? context.save()
                    studentToDelete = nil
                    }
                    Button(
                        "Cancel",
                        role: .cancel
                    ) {
                        studentToDelete = nil
                        }
                        } message: { student in
                            Text(
                                "Are you sure you want to delete \(student.lastName)?"
                            )
                        }
 
            
        }
    }
}
