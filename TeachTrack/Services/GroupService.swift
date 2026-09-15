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
}
