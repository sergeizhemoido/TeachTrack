//
//  StudentService.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/9/26.
//

import Foundation
import SwiftData

@MainActor
final class StudentService {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func createStudent(
        firstName: String,
        lastName: String,
        studentType: StudentType,
        phone: String? = nil,
        email: String? = nil,
        notes: String? = nil
    ) throws {

        let student = Student(
            firstName: firstName,
            lastName: lastName,
            studentType: studentType
        )

        student.phone = phone
        student.email = email
        student.notes = notes

        context.insert(student)

        try context.save()
    }

    func archiveStudent(
        _ student: Student
    ) throws {

        student.isActive = false

        try context.save()
    }

    func save() throws {
        try context.save()
    }
}
