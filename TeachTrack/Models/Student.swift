//
//  Student.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/9/26.
//
import Foundation
import SwiftData

@Model
final class Student {

    @Attribute(.unique)
    var uuid: UUID

    var firstName: String

    var lastName: String

    var phone: String?

    var email: String?

    var notes: String?

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
        lastName: String
    ) {
        self.uuid = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.isActive = true
    }
}
