//
//  LessonNote.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/9/26.
//
import Foundation
import SwiftData

@Model
final class LessonNote {

    @Attribute(.unique)
    var uuid: UUID

    var lesson: Lesson

    var text: String

    var createdAt: Date

    init(
        lesson: Lesson,
        text: String
    ) {
        self.uuid = UUID()
        self.lesson = lesson
        self.text = text
        self.createdAt = .now
    }
}
