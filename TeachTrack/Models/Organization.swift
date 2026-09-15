//
//  Organisation.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/9/26.
//
import Foundation
import SwiftData

@Model
final class Organization {

    @Attribute(.unique)
    var uuid: UUID

    var name: String

    var type: OrganizationType

    var phone: String?

    var email: String?

    var address: String?

    var notes: String?

    var isActive: Bool
    
    @Relationship(
            deleteRule: .nullify,
            inverse: \Group.organization
        )
        var groups: [Group] = []

    init(
        name: String,
        type: OrganizationType
    ) {
        self.uuid = UUID()
        self.name = name
        self.type = type
        self.isActive = true
    }
}
