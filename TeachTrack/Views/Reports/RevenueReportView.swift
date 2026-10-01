//
//  RevenueReportView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/11/26.
//
import SwiftUI
import SwiftData

struct RevenueReportView: View {

    let range: ReportDateRange?

    init(range: ReportDateRange? = nil) {
        self.range = range
    }

    @Query
    private var transactions: [Transaction]

    private var periodTransactions: [Transaction] {
        transactions.filter { range?.contains($0.date) ?? true }
    }

    private var earnedRevenue: Decimal {

        periodTransactions
            .filter {
                $0.type == .charge
            }
            .reduce(
                Decimal.zero
            ) {
                $0 + $1.amount
            }
    }

    private var received: Decimal {
        periodTransactions.filter { $0.type == .payment || $0.type == .deposit }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    var body: some View {

        Form {

            HStack {

                Text("Earned from Lessons")

                Spacer()

                Text(
                    earnedRevenue.formatted()
                )
            }

            HStack {
                Text("Payments and Deposits Received")
                Spacer()
                Text(received.formatted())
            }
        }
        .teachTrackScreen()
        .navigationTitle("Revenue")
    }
}
