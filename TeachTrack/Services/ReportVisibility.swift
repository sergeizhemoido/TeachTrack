import Foundation

enum ReportVisibility {
    static func attendances(
        _ records: [Attendance],
        now: Date = .now,
        includeArchived: Bool = false,
        range: ReportDateRange? = nil
    ) -> [Attendance] {
        records.filter { attendance in
            attendance.lesson.startDate <= now &&
            (range?.contains(attendance.lesson.startDate) ?? true) &&
            (includeArchived || (
                attendance.student.isActive &&
                activeGroup(attendance.lesson.group)
            ))
        }
    }

    static func lessons(
        _ records: [Lesson],
        now: Date = .now,
        includeArchived: Bool = false,
        range: ReportDateRange? = nil
    ) -> [Lesson] {
        records.filter { lesson in
            lesson.startDate <= now &&
            (range?.contains(lesson.startDate) ?? true) &&
            (includeArchived || activeGroup(lesson.group))
        }
    }

    private static func activeGroup(_ group: Group) -> Bool {
        group.isActive && (group.organization?.isActive ?? true)
    }
}
