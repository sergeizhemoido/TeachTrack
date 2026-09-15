//
//  Lesson.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/9/26.
//
import Foundation
import SwiftData

@Model
final class Lesson {

    @Attribute(.unique)
    var uuid: UUID

    var group: Group

    var startDate: Date

    var endDate: Date

    var status: LessonStatus

    var source: LessonSource

    var generatedFromRule: ScheduleRule?

    var notes: String?
    
    @Relationship(
        deleteRule: .cascade,
        inverse: \Attendance.lesson
    )
    var attendances: [Attendance] = []

    @Relationship(
        deleteRule: .cascade,
        inverse: \LessonNote.lesson
    )
    var lessonNotes: [LessonNote] = []

    init(
        group: Group,
        startDate: Date,
        endDate: Date,
        source: LessonSource
    ) {
        self.uuid = UUID()
        self.group = group
        self.startDate = startDate
        self.endDate = endDate
        self.status = .planned
        self.source = source
    }
}
