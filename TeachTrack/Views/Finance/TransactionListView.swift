//
//  TransactionListView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/11/26.
//
import SwiftUI
import SwiftData

struct TransactionListView: View {

    let student: Student

    @Query(
        sort: \Transaction.date,
        order: .reverse
    )
    private var allTransactions: [Transaction]

    private var transactions: [Transaction] {

        allTransactions.filter {
            $0.student?.uuid == student.uuid
        }
    }

    var body: some View {

        List {

            ForEach(
                transactions,
                id: \.uuid
            ) { transaction in

                VStack(
                    alignment: .leading
                ) {

                    Text(
                        transaction.type.rawValue
                    )

                    Text(
                        transaction.amount.formatted()
                    )
                    .font(.caption)

                    Text(
                        transaction.date,
                        format: .dateTime
                    )
                    .font(.caption2)
                }
            }
        }
        .navigationTitle(
            "Transactions"
        )
    }
}
