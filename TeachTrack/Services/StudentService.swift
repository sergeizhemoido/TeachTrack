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
        lastName: String
    ) throws {

        let student = Student(
            firstName: firstName,
            lastName: lastName
        )

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
