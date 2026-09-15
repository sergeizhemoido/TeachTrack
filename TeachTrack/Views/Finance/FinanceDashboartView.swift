//
//  FinanceDashboartView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/11/26.
//
import SwiftUI
import SwiftData

struct FinanceDashboardView: View {

    @Query
    private var transactions: [Transaction]

    private var totalPayments: Decimal {

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

    private var totalCharges: Decimal {

        transactions
            .filter {
                $0.type == .charge
            }
            .reduce(
                Decimal.zero
            ) {
                $0 + $1.amount
            }
    }

    var body: some View {

        List {

            Section("Overview") {

                HStack {

                    Text("Payments")

                    Spacer()

                    Text(
                        totalPayments.formatted()
                    )
                }

                HStack {

                    Text("Charges")

                    Spacer()

                    Text(
                        totalCharges.formatted()
                    )
                }
            }
        }
        .navigationTitle(
            "Finance"
        )
    }
}
