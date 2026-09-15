//
//  RevenueReportView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/11/26.
//
import SwiftUI
import SwiftData

struct RevenueReportView: View {

    @Query
    private var transactions: [Transaction]

    private var totalRevenue: Decimal {

        transactions
            .filter {
                $0.type == .payment
            }
            .reduce(
                Decimal.zero
            ) {
                $0 + $1.amount
            }
    }

    var body: some View {

        Form {

            HStack {

                Text("Total Revenue")

                Spacer()

                Text(
                    totalRevenue.formatted()
                )
            }
        }
        .navigationTitle("Revenue")
    }
}
