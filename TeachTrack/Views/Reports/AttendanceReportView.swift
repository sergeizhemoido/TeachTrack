//
//  AttendanceReportView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/11/26.
//
import SwiftUI
import SwiftData

struct AttendanceReportView: View {

    @Query
    private var attendances: [Attendance]

    var body: some View {

        List {

            ForEach(
                attendances,
                id: \.uuid
            ) { attendance in

                VStack(
                    alignment: .leading
                ) {

                    Text(
                        "\(attendance.student.lastName) \(attendance.student.firstName)"
                    )

                    Text(
                        attendance.status.rawValue
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Attendance")
    }
}
