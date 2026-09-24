//
//  Group.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/9/26.
//
import Foundation
import SwiftData

@Model
final class Group {

    @Attribute(.unique)
    var uuid: UUID

    var name: String
    var revenueModel: RevenueModel
    var fixedLessonRate: Decimal?
    var ratePerStudent: Decimal?
    var notes: String?
    var isActive: Bool

    var organization: Organization?

    @Relationship(
        deleteRule: .cascade,
        inverse: \Enrollment.group
    )
    var enrollments: [Enrollment] = []

    @Relationship(
        deleteRule: .cascade,
        inverse: \Lesson.group
    )
    var lessons: [Lesson] = []

    @Relationship(
        deleteRule: .cascade,
        inverse: \ScheduleRule.group
    )
    var scheduleRules: [ScheduleRule] = []

    init(
        name: String,
        revenueModel: RevenueModel,
        organization: Organization? = nil
    ) {
        self.uuid = UUID()
        self.name = name
        self.revenueModel = revenueModel
        self.organization = organization
        self.isActive = true
    }
}
