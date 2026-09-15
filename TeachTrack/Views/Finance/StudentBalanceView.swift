//
//  StudentBalanceView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/11/26.
//
import SwiftUI
import SwiftData

struct StudentBalanceView: View {

    let student: Student

    @Query
    private var transactions: [Transaction]

    private var studentTransactions: [Transaction] {

        transactions.filter {
            $0.student?.uuid == student.uuid
        }
    }

    private var balance: Decimal {

        studentTransactions.reduce(
            Decimal.zero
        ) { partial, transaction in

            switch transaction.type {

            case .payment:
                return partial + transaction.amount

            case .refund:
                return partial - transaction.amount

            case .adjustment:
                return partial + transaction.amount

            case .charge:
                return partial - transaction.amount
            }
        }
    }

    var body: some View {

        Form {

            HStack {

                Text("Balance")

                Spacer()

                Text(
                    balance.formatted()
                )
            }
        }
        .navigationTitle("Balance")
    }
}
