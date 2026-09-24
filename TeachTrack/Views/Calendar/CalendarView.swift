//
//  CalendarView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 9/17/26.
//

import SwiftUI
import SwiftData

struct CalendarView: View {

    @Environment(\.modelContext)
    private var context

    @Query(sort: \Lesson.startDate)
    private var lessons: [Lesson]

    @State
    private var selectedDate = Date()

    @State
    private var displayedMonth = Date()

    @State
    private var showAddLesson = false

    private let calendar = Calendar.current

    private var monthTitle: String {

        displayedMonth.formatted(
            .dateTime
                .month(.wide)
                .year()
        )
    }

    private var days: [Date?] {

        guard let interval = calendar.dateInterval(
            of: .month,
            for: displayedMonth
        ) else {
            return []
        }

        let firstDay = interval.start

        guard let range = calendar.range(
            of: .day,
            in: .month,
            for: firstDay
        ) else {
            return []
        }

        let weekday = calendar.component(
            .weekday,
            from: firstDay
        )

        let leadingEmptyDays =
            (
                weekday -
                calendar.firstWeekday +
                7
            ) % 7

        var result: [Date?] = Array(
            repeating: nil,
            count: leadingEmptyDays
        )

        for day in range {

            if let date = calendar.date(
                byAdding: .day,
                value: day - 1,
                to: firstDay
            ) {
                result.append(date)
            }
        }

        while result.count % 7 != 0 {
            result.append(nil)
        }

        return result
    }

    private func lessons(
        on date: Date
    ) -> [Lesson] {

        lessons.filter {

            calendar.isDate(
                $0.startDate,
                inSameDayAs: date
            )
        }
    }

    private var selectedDayLessons: [Lesson] {

        lessons(
            on: selectedDate
        )
    }

    var body: some View {

        VStack(spacing: 0) {

            HStack {

                Button {

                    changeMonth(
                        by: -1
                    )

                } label: {

                    Image(
                        systemName: "chevron.left"
                    )
                }

                Spacer()

                Text(monthTitle)
                    .font(.headline)

                Spacer()

                Button {

                    changeMonth(
                        by: 1
                    )

                } label: {

                    Image(
                        systemName: "chevron.right"
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            let weekdays =
                calendar.shortStandaloneWeekdaySymbols

            HStack(spacing: 0) {

                ForEach(
                    0..<7,
                    id: \.self
                ) { index in

                    Text(
                        weekdays[
                            (
                                index +
                                calendar.firstWeekday -
                                1
                            ) % 7
                        ]
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(
                        maxWidth: .infinity
                    )
                }
            }
            .padding(.horizontal)

            LazyVGrid(
                columns: Array(
                    repeating:
                        GridItem(.flexible()),
                    count: 7
                ),
                spacing: 8
            ) {

                ForEach(
                    Array(
                        days.enumerated()
                    ),
                    id: \.offset
                ) { _, date in

                    if let date {

                        DayCell(
                            date: date,
                            isSelected:
                                calendar.isDate(
                                    date,
                                    inSameDayAs:
                                        selectedDate
                                ),
                            isToday:
                                calendar.isDateInToday(
                                    date
                                ),
                            lessonCount:
                                lessons(
                                    on: date
                                ).count
                        ) {

                            selectedDate = date
                        }

                    } else {

                        Color.clear
                            .frame(height: 42)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Divider()
                .padding(.top, 8)

            List {

                Section {

                    if selectedDayLessons.isEmpty {

                        Text("No Lessons")
                            .foregroundStyle(
                                .secondary
                            )

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
                                        format:
                                            .dateTime
                                            .hour()
                                            .minute()
                                    )
                                    .font(.headline)

                                    Text(
                                        lesson.group.name
                                    )

                                    if let organization =
                                        lesson.group.organization {

                                        Text(
                                            organization.name
                                        )
                                        .font(.caption)
                                        .foregroundStyle(
                                            .secondary
                                        )

                                    } else {

                                        Text(
                                            "Private Student"
                                        )
                                        .font(.caption)
                                        .foregroundStyle(
                                            .secondary
                                        )
                                    }

                                    Text(
                                        lesson.status.rawValue
                                    )
                                    .font(.caption)
                                    .foregroundStyle(
                                        .secondary
                                    )
                                }
                            }
                        }
                    }

                } header: {

                    Text(
                        selectedDate,
                        format:
                            .dateTime
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

                    Image(
                        systemName: "plus"
                    )
                }
            }
        }

        .sheet(
            isPresented:
                $showAddLesson
        ) {

            AddLessonFromCalendarView(
                selectedDate:
                    selectedDate
            )
        }

        .onAppear {

            LessonGenerator.generateForCalendar(
                around: displayedMonth,
                context: context
            )
        }

        .onChange(
            of: displayedMonth
        ) {

            LessonGenerator.generateForCalendar(
                around: displayedMonth,
                context: context
            )
        }
    }

    private func changeMonth(
        by value: Int
    ) {

        if let newMonth =
            calendar.date(
                byAdding: .month,
                value: value,
                to: displayedMonth
            ) {

            displayedMonth = newMonth

            if !calendar.isDate(
                selectedDate,
                equalTo: newMonth,
                toGranularity: .month
            ) {

                selectedDate =
                    calendar.startOfDay(
                        for: newMonth
                    )
            }
        }
    }
}


private struct DayCell: View {

    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let lessonCount: Int
    let action: () -> Void

    var body: some View {

        Button(
            action: action
        ) {

            VStack(spacing: 2) {

                Text(
                    date,
                    format:
                        .dateTime.day()
                )
                .font(.body)
                .frame(
                    width: 32,
                    height: 28
                )
                .background {

                    if isSelected {

                        Circle()
                            .fill(.tint)

                    } else if isToday {

                        Circle()
                            .stroke(
                                .tint,
                                lineWidth: 1
                            )
                    }
                }
                .foregroundStyle(
                    isSelected
                        ? .white
                        : .primary
                )

                HStack(spacing: 2) {

                    ForEach(
                        0..<min(
                            lessonCount,
                            3
                        ),
                        id: \.self
                    ) { _ in

                        Circle()
                            .fill(.tint)
                            .frame(
                                width: 4,
                                height: 4
                            )
                    }
                }
                .frame(height: 6)
            }
            .frame(
                maxWidth: .infinity
            )
            .frame(height: 42)
        }
        .buttonStyle(.plain)
    }
}
