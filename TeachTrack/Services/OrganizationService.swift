//
//  OrganizationService.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/10/26.
//
import Foundation
import SwiftData

@MainActor
final class OrganizationService {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func createOrganization(
        name: String,
        type: OrganizationType
    ) throws {

        let organization = Organization(
            name: name,
            type: type
        )

        context.insert(organization)

        try context.save()
    }
}
