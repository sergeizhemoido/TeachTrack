//
//  Attendance.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/9/26.
//
import Foundation
import SwiftData

@Model
final class Attendance {

    @Attribute(.unique)
    var uuid: UUID

    var student: Student

    var lesson: Lesson

    var status: AttendanceStatus

    var makeupSourceAttendance: Attendance?

    var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \AttendanceRevision.attendance)
    var revisions: [AttendanceRevision] = []

    init(
        student: Student,
        lesson: Lesson,
        status: AttendanceStatus
    ) {
        self.uuid = UUID()
        self.student = student
        self.lesson = lesson
        self.status = status
    }
}
