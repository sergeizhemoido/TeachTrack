//
//  Enums.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/9/26.
//
import Foundation

// MARK: - Organization

enum OrganizationType: String, Codable, CaseIterable, Identifiable {
    case school
    case kindergarten
    case privateClient

    var id: String { rawValue }
}

extension OrganizationType {

    var title: String {
        switch self {
        case .school:
            return "School"
        case .kindergarten:
            return "Kindergarten"
        case .privateClient:
            return "Private Client"
        }
    }
}

// MARK: - Revenue

enum RevenueModel: String, Codable, CaseIterable, Identifiable {
    case perStudent
    case fixedPerLesson

    var id: String { rawValue }
}

extension RevenueModel {

    var title: String {
        switch self {
        case .perStudent:
            return "Per Student"
        case .fixedPerLesson:
            return "Fixed Per Lesson"
        }
    }
}

// MARK: - Lesson

enum LessonStatus: String, Codable, CaseIterable, Identifiable {
    case planned
    case completed
    case cancelled
    case rescheduled

    var id: String { rawValue }
}

enum LessonSource: String, Codable, CaseIterable, Identifiable {
    case generated
    case manual

    var id: String { rawValue }
}

// MARK: - Attendance

enum AttendanceStatus: String, Codable, CaseIterable, Identifiable {

    case present

    // отсутствовал, занятие списывается
    case absent

    // отсутствовал, списания нет
    case excused

    // отработка ранее оплаченного занятия
    case makeup

    var id: String { rawValue }

    var createsCharge: Bool {
        switch self {
        case .present:
            return true

        case .absent:
            return true

        case .excused:
            return false

        case .makeup:
            return false
        }
    }
}

extension AttendanceStatus {

    var title: String {

        switch self {
        case .present:
            return "Present"
        case .absent:
            return "Absent"
        case .excused:
            return "Excused"
        case .makeup:
            return "Makeup"
        }
    }
}

// MARK: - Finance

enum TransactionType: String, Codable, CaseIterable, Identifiable {

    case charge
    case payment
    case adjustment
    case refund

    var id: String { rawValue }
}

// MARK: - Schedule

enum Weekday: Int,
              Codable,
              CaseIterable,
              Identifiable {

    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    var id: Int { rawValue }

    var title: String {

        switch self {

        case .sunday:
            return "Sunday"

        case .monday:
            return "Monday"

        case .tuesday:
            return "Tuesday"

        case .wednesday:
            return "Wednesday"

        case .thursday:
            return "Thursday"

        case .friday:
            return "Friday"

        case .saturday:
            return "Saturday"
        }
    }
}
