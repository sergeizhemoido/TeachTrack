//
//  ReportsView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/11/26.
//
import SwiftUI

struct ReportsView: View {

    var body: some View {

        List {

            NavigationLink {

                RevenueReportView()

            } label: {

                Label(
                    "Revenue",
                    systemImage: "dollarsign.circle"
                )
            }

            NavigationLink {

                AttendanceReportView()

            } label: {

                Label(
                    "Attendance",
                    systemImage: "person.3"
                )
            }

            NavigationLink {

                DebtReportView()

            } label: {

                Label(
                    "Debts",
                    systemImage: "exclamationmark.triangle"
                )
            }
        }
        .navigationTitle("Reports")
    }
}
