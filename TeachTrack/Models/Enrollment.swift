//
//  Enrollment.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/9/26.
//
import Foundation
import SwiftData

@Model
final class Enrollment {

    @Attribute(.unique)
    var uuid: UUID

    var student: Student

    var group: Group

    var lessonPrice: Decimal

    var enrollmentDate: Date

    var endDate: Date?

    var isActive: Bool

    init(
        student: Student,
        group: Group,
        lessonPrice: Decimal
    ) {
        self.uuid = UUID()
        self.student = student
        self.group = group
        self.lessonPrice = lessonPrice
        self.enrollmentDate = .now
        self.isActive = true
    }
}
