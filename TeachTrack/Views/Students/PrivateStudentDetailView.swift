import SwiftUI
import SwiftData

struct PrivateStudentDetailView: View {

    let student: Student
    let group: Group

    @Query(sort: \Lesson.startDate, order: .reverse)
    private var allLessons: [Lesson]

    @State
    private var showEditStudent = false

    @State
    private var showEditGroup = false

    @State
    private var showAddLesson = false

    private var lessons: [Lesson] {
        allLessons.filter { $0.group.uuid == group.uuid }
    }

    var body: some View {
        List {
            TeachTrackHero(
                eyebrow: "Private student",
                title: "\(student.firstName) \(student.lastName)",
                detail: "Individual lessons and account",
                symbol: "person.crop.circle.fill",
                color: TeachTrackDesign.sunflower
            )
            Section("Student") {
                if let phone = student.phone, !phone.isEmpty {
                    Label(phone, systemImage: "phone")
                }

                if let email = student.email, !email.isEmpty {
                    Label(email, systemImage: "envelope")
                }

                if let notes = student.notes, !notes.isEmpty {
                    Text(notes)
                }

                NavigationLink {
                    ContactListView(student: student)
                } label: {
                    Label("Contacts", systemImage: "person.2")
                }
            }

            Section("Lessons") {
                NavigationLink {
                    ScheduleRuleListView(group: group)
                } label: {
                    Label("Schedule", systemImage: "calendar")
                }

                if let rate = group.ratePerStudent {
                    HStack {
                        Text("Lesson Rate")
                        Spacer()
                        Text(rate.formatted())
                    }
                }

                if lessons.isEmpty {
                    Text("No Lessons")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(lessons, id: \.uuid) { lesson in
                        NavigationLink {
                            LessonDetailView(lesson: lesson)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(
                                    lesson.startDate,
                                    format: .dateTime.day().month().year()
                                )
                                Text(lesson.status.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("Finance") {
                NavigationLink {
                    AccountStatementView(student: student)
                } label: {
                    Label("Account and History", systemImage: "dollarsign.circle")
                }
            }
        }
        .teachTrackScreen()
        .navigationTitle("\(student.firstName) \(student.lastName)")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu {
                    Button("Edit Student") {
                        showEditStudent = true
                    }
                    Button("Edit Lesson Rate") {
                        showEditGroup = true
                    }
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button {
                    showAddLesson = true
                } label: {
                    Label("Add Lesson", systemImage: "calendar.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showEditStudent) {
            EditStudentView(student: student)
        }
        .sheet(isPresented: $showEditGroup) {
            EditGroupView(group: group)
        }
        .sheet(isPresented: $showAddLesson) {
            AddLessonView(group: group)
        }
    }
}
