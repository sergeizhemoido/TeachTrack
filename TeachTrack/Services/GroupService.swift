//
//  GroupService.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/10/26.
//
import SwiftData
import Foundation

@MainActor
final class GroupService {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func createGroup(
        name: String,
        organization: Organization,
        revenueModel: RevenueModel
    ) throws {

        let group = Group(
            name: name,
            revenueModel: revenueModel,
            organization: organization
        )

        context.insert(group)

        try context.save()
    }

    func archiveGroup(_ group: Group) throws {
        let archivedAt = Date.now
        let transactions = try context.fetch(FetchDescriptor<Transaction>())
        let lessons = try context.fetch(FetchDescriptor<Lesson>())

        group.isActive = false
        for enrollment in group.enrollments where enrollment.isActive {
            enrollment.isActive = false
            enrollment.endDate = archivedAt
        }
        for rule in group.scheduleRules where rule.isActive {
            rule.isActive = false
        }
        for lesson in lessons where lesson.group.uuid == group.uuid &&
            lesson.status == .planned && lesson.endDate >= archivedAt {
            let hasTransactions = transactions.contains { $0.lesson?.uuid == lesson.uuid }
            if lesson.attendances.isEmpty && !hasTransactions {
                context.delete(lesson)
            } else {
                lesson.status = .cancelled
                try LessonBillingService.syncCharge(for: lesson, context: context)
            }
        }
        try context.save()
    }
}
