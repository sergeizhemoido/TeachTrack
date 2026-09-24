//
//  LessonGenerator.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 9/17/26.
//

import Foundation
import SwiftData

struct LessonGenerator {

    // MARK: - Generate Lessons

    static func generateLessons(
        from startDate: Date,
        through endDate: Date,
        context: ModelContext
    ) {

        let descriptor = FetchDescriptor<ScheduleRule>(
            predicate: #Predicate<ScheduleRule> {
                $0.isActive
            }
        )

        guard let rules = try? context.fetch(descriptor) else {
            return
        }

        let calendar = Calendar.current

        var date = calendar.startOfDay(
            for: startDate
        )

        let finalDate = calendar.startOfDay(
            for: endDate
        )

        while date <= finalDate {

            let weekday = calendar.component(
                .weekday,
                from: date
            )

            for rule in rules {

                let group = rule.group

                guard group.isActive else {
                    continue
                }

                if let organization = group.organization,
                   !organization.isActive {
                    continue
                }

                guard weekday == rule.weekday.rawValue else {
                    continue
                }

                // Do not generate a lesson if this date
                // has been explicitly excluded from the rule.
                if hasException(
                    for: rule,
                    on: date,
                    context: context
                ) {
                    continue
                }

                var components = calendar.dateComponents(
                    [.year, .month, .day],
                    from: date
                )

                components.hour = rule.startHour
                components.minute = rule.startMinute
                components.second = 0

                guard let lessonStart = calendar.date(
                    from: components
                ) else {
                    continue
                }

                let lessonEnd =
                    lessonStart.addingTimeInterval(
                        Double(rule.durationMinutes * 60)
                    )

                let alreadyExists = lessonExists(
                    group: group,
                    startDate: lessonStart,
                    rule: rule,
                    context: context
                )

                if !alreadyExists {

                    let lesson = Lesson(
                        group: group,
                        startDate: lessonStart,
                        endDate: lessonEnd,
                        source: .generated
                    )

                    lesson.generatedFromRule = rule

                    context.insert(lesson)
                }
            }

            guard let nextDate = calendar.date(
                byAdding: .day,
                value: 1,
                to: date
            ) else {
                break
            }

            date = nextDate
        }

        try? context.save()
    }


    // MARK: - Generate Calendar Range

    static func generateForCalendar(
        around date: Date,
        context: ModelContext
    ) {

        let calendar = Calendar.current

        // Start from today, not from the beginning
        // of the current month.
        let startDate = calendar.startOfDay(
            for: Date()
        )

        // Beginning of the current month.
        guard let monthStart = calendar.date(
            from: calendar.dateComponents(
                [.year, .month],
                from: date
            )
        ) else {
            return
        }

        // Three months from the beginning
        // of the current month.
        guard let monthAfterNext = calendar.date(
            byAdding: .month,
            value: 3,
            to: monthStart
        ) else {
            return
        }

        // Last day of the third month.
        guard let endDate = calendar.date(
            byAdding: .day,
            value: -1,
            to: monthAfterNext
        ) else {
            return
        }

        generateLessons(
            from: startDate,
            through: endDate,
            context: context
        )
    }


    // MARK: - Remove Future Lessons

    static func removeFutureLessons(
        for rule: ScheduleRule,
        from date: Date,
        context: ModelContext
    ) {

        let ruleID = rule.uuid
        let startDate = date

        let descriptor = FetchDescriptor<Lesson>(
            predicate: #Predicate<Lesson> {
                $0.generatedFromRule?.uuid == ruleID &&
                $0.startDate >= startDate
            }
        )

        guard let lessons = try? context.fetch(
            descriptor
        ) else {
            return
        }

        for lesson in lessons where
            lesson.source == .generated &&
            !lesson.isManuallyModified &&
            lesson.status == .planned {
            context.delete(lesson)
        }

        try? context.save()
    }


    // MARK: - Delete Generated Lesson Permanently

    static func deleteGeneratedLesson(
        _ lesson: Lesson,
        context: ModelContext
    ) {

        guard lesson.source == .generated,
              let rule = lesson.generatedFromRule
        else {
            context.delete(lesson)
            try? context.save()
            return
        }

        let calendar = Calendar.current

        let exceptionDate = calendar.startOfDay(
            for: lesson.startDate
        )

        // Check whether an exception already exists.
        if !hasException(
            for: rule,
            on: exceptionDate,
            context: context
        ) {

            let exception = ScheduleException(
                rule: rule,
                date: exceptionDate
            )

            context.insert(exception)
        }

        context.delete(lesson)

        try? context.save()
    }


    // MARK: - Check Schedule Exception

    private static func hasException(
        for rule: ScheduleRule,
        on date: Date,
        context: ModelContext
    ) -> Bool {

        let calendar = Calendar.current

        let targetDate = calendar.startOfDay(
            for: date
        )

        let ruleID = rule.uuid

        let descriptor = FetchDescriptor<ScheduleException>(
            predicate: #Predicate<ScheduleException> {
                $0.rule.uuid == ruleID &&
                $0.date == targetDate &&
                $0.isActive
            }
        )

        let count =
            (try? context.fetchCount(descriptor)) ?? 0

        return count > 0
    }


    // MARK: - Check Existing Lesson

    private static func lessonExists(
        group: Group,
        startDate: Date,
        rule: ScheduleRule,
        context: ModelContext
    ) -> Bool {

        let groupID = group.uuid
        let ruleID = rule.uuid
        let targetDate = startDate

        let descriptor = FetchDescriptor<Lesson>(
            predicate: #Predicate<Lesson> {
                $0.group.uuid == groupID &&
                $0.generatedFromRule?.uuid == ruleID &&
                $0.startDate == targetDate
            }
        )

        let count =
            (try? context.fetchCount(descriptor)) ?? 0

        return count > 0
    }
}
