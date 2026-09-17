//
//  CalendarView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 9/17/26.
//
import SwiftUI
import SwiftData

struct _CalendarView: View {

    @Query(sort: \Lesson.startDate)
    private var lessons: [Lesson]

    @State
    private var selectedDate = Date()

    @State
    private var showAddLesson = false

    private var selectedDayLessons: [Lesson] {
        lessons.filter {
            Calendar.current.isDate(
                $0.startDate,
                inSameDayAs: selectedDate
            )
        }
    }

    var body: some View {
        VStack(spacing: 0) {

            DatePicker(
                "Date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding(.horizontal)

            Divider()

            List {
                Section {
                    if selectedDayLessons.isEmpty {
                        Text("No Lessons")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(
                            selectedDayLessons,
                            id: \.uuid
                        ) { lesson in

                            NavigationLink {
                                LessonDetailView(
                                    lesson: lesson
                                )
                            } label: {
                                VStack(
                                    alignment: .leading,
                                    spacing: 4
                                ) {
                                    Text(
                                        lesson.startDate,
                                        format: .dateTime
                                            .hour()
                                            .minute()
                                    )
                                    .font(.headline)

                                    Text(lesson.group.name)

                                    Text(
                                        lesson.group.organization.name
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                    Text(lesson.status.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text(
                        selectedDate,
                        format: .dateTime
                            .weekday(.wide)
                            .month(.wide)
                            .day()
                    )
                }
            }
        }
        .navigationTitle("Calendar")
        .toolbar {
            ToolbarItem(
                placement: .topBarTrailing
            ) {
                Button {
                    showAddLesson = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(
            isPresented: $showAddLesson
        ) {
            AddLessonFromCalendarView(
                selectedDate: selectedDate
            )
        }
    }
}

#Preview {
    CalendarView()
}
