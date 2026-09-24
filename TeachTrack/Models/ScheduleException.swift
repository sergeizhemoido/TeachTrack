//
//  ScheduleException.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 9/24/26.
//

import Foundation
import SwiftData

@Model
final class ScheduleException {

    @Attribute(.unique)
    var uuid: UUID

    var rule: ScheduleRule
    var date: Date
    var isActive: Bool

    init(
        rule: ScheduleRule,
        date: Date
    ) {
        self.uuid = UUID()
        self.rule = rule
        self.date = date
        self.isActive = true
    }
}
