//
//  AttendanceReportView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/11/26.
//
import SwiftUI
import SwiftData

struct AttendanceReportView: View {

    let range: ReportDateRange?

    init(range: ReportDateRange? = nil) {
        self.range = range
    }

    @Query(sort: \Attendance.lesson.startDate, order: .reverse)
    private var attendances: [Attendance]

    @State private var includeArchived = false

    private var visibleAttendances: [Attendance] {
        ReportVisibility.attendances(
            attendances,
            includeArchived: includeArchived,
            range: range
        )
    }

    var body: some View {

        List {

            Section {
                Toggle("Include Archived Students", isOn: $includeArchived)
            } footer: {
                Text(range == nil
                    ? "Future lessons are not included in attendance history."
                    : "Attendance is filtered by lesson date. Future lessons are excluded.")
            }

            if visibleAttendances.isEmpty {
                ContentUnavailableView(
                    "No Attendance History",
                    systemImage: "checklist",
                    description: Text("Attendance appears here after the lesson date.")
                )
            }

            ForEach(
                visibleAttendances,
                id: \.uuid
            ) { attendance in

                DisclosureGroup {
                    ForEach(attendance.revisions.sorted {
                        $0.recordedAt > $1.recordedAt
                    }, id: \.uuid) { revision in
                        VStack(alignment: .leading) {
                            Text(revision.status.title)
                            Text(revision.recordedAt, format: .dateTime)
                                .font(.caption)
                            if let notes = revision.notes, !notes.isEmpty {
                                Text(notes).font(.caption)
                            }
                        }
                    }
                } label: {
                    VStack(alignment: .leading) {

                    Text(
                        "\(attendance.student.lastName) \(attendance.student.firstName)"
                    )

                    Text(
                        attendance.status.rawValue
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Text(attendance.lesson.group.name)
                        .font(.caption)

                    Text(attendance.lesson.startDate, format: .dateTime)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .teachTrackScreen()
        .navigationTitle("Attendance")
    }
}
