//
//  Transaction.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/9/26.
//
import Foundation
import SwiftData

@Model
final class Transaction {

    @Attribute(.unique)
    var uuid: UUID

    var date: Date

    var type: TransactionType

    var amount: Decimal

    var student: Student?

    var organization: Organization?

    var lesson: Lesson?

    var notes: String?

    init(
        amount: Decimal,
        type: TransactionType
    ) {
        self.uuid = UUID()
        self.date = .now
        self.amount = amount
        self.type = type
    }
}
