//
//  DebtReport.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/11/26.
//
import SwiftUI

struct DebtReportView: View {

    var body: some View {

        ContentUnavailableView(
            "Debt Report",
            systemImage: "exclamationmark.triangle",
            description: Text(
                "Coming Soon"
            )
        )
        .navigationTitle("Debts")
    }
}
