//
//  ScheduleRole.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/9/26.
//
import Foundation
import SwiftData

@Model
final class ScheduleRule {

    @Attribute(.unique)
    var uuid: UUID

    var group: Group

    var weekday: Weekday

    var startHour: Int

    var startMinute: Int

    var durationMinutes: Int

    var isActive: Bool

    init(
        group: Group,
        weekday: Weekday,
        startHour: Int,
        startMinute: Int,
        durationMinutes: Int
    ) {
        self.uuid = UUID()
        self.group = group
        self.weekday = weekday
        self.startHour = startHour
        self.startMinute = startMinute
        self.durationMinutes = durationMinutes
        self.isActive = true
    }
}
