//
//  StudentNote.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/9/26.
//
import Foundation
import SwiftData

@Model
final class StudentNote {

    @Attribute(.unique)
    var uuid: UUID

    var student: Student

    var text: String

    var createdAt: Date

    init(
        student: Student,
        text: String
    ) {
        self.uuid = UUID()
        self.student = student
        self.text = text
        self.createdAt = .now
    }
}
