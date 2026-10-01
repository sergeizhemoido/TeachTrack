//
//  Contact.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/9/26.
//
import Foundation
import SwiftData

@Model
final class Contact {

    @Attribute(.unique)
    var uuid: UUID

    var student: Student

    var name: String

    var relationship: String

    var phone: String?

    var email: String?

    var notes: String?

    var displayName: String {
        if !name.isEmpty { return name }
        if !relationship.isEmpty { return relationship }
        if let phone, !phone.isEmpty { return phone }
        if let email, !email.isEmpty { return email }
        return "Contact"
    }

    init(
        student: Student,
        name: String,
        relationship: String
    ) {
        self.uuid = UUID()
        self.student = student
        self.name = name
        self.relationship = relationship
    }
}
