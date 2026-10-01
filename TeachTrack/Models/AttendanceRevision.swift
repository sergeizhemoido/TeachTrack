import Foundation
import SwiftData

@Model
final class AttendanceRevision {
    @Attribute(.unique) var uuid: UUID
    var attendance: Attendance
    var status: AttendanceStatus
    var recordedAt: Date
    var notes: String?

    init(attendance: Attendance, status: AttendanceStatus, notes: String?) {
        self.uuid = UUID()
        self.attendance = attendance
        self.status = status
        self.recordedAt = .now
        self.notes = notes
    }
}
