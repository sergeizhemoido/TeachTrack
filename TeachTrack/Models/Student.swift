//
//  Student.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/9/26.
//
import Foundation
import SwiftData

enum StudentType: String, Codable, CaseIterable, Identifiable {
    case regular
    case privateClient

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .regular:
            return "Regular"
        case .privateClient:
            return "Private Client"
        }
    }
}

@Model
final class Student {

    @Attribute(.unique)
    var uuid: UUID

    var firstName: String
    var lastName: String

    var phone: String?
    var email: String?
    var notes: String?

    var studentType: StudentType

    var isActive: Bool

    @Relationship(
        deleteRule: .cascade,
        inverse: \Contact.student
    )
    var contacts: [Contact] = []

    @Relationship(
        deleteRule: .cascade,
        inverse: \Enrollment.student
    )
    var enrollments: [Enrollment] = []

    @Relationship(
        deleteRule: .cascade,
        inverse: \Attendance.student
    )
    var attendances: [Attendance] = []

    @Relationship(
        deleteRule: .cascade,
        inverse: \StudentNote.student
    )
    var notesList: [StudentNote] = []

    init(
        firstName: String,
        lastName: String,
        studentType: StudentType = .regular
    ) {
        self.uuid = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.studentType = studentType
        self.isActive = true
    }
}
