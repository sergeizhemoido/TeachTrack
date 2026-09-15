//
//  AddPaymentView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/11/26.
//
import SwiftUI
import SwiftData

struct AddPaymentView: View {

    let student: Student

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.modelContext)
    private var context

    @State
    private var amount = ""

    @State
    private var notes = ""

    var body: some View {

        NavigationStack {

            Form {

                TextField(
                    "Amount",
                    text: $amount
                )
                .keyboardType(.decimalPad)

                TextField(
                    "Notes",
                    text: $notes
                )
            }
            .navigationTitle(
                "Payment"
            )

            .toolbar {

                ToolbarItem(
                    placement: .confirmationAction
                ) {

                    Button("Save") {

                        guard let value =
                            Decimal(
                                string: amount
                            )
                        else {
                            return
                        }

                        let transaction =
                            Transaction(
                                amount: value,
                                type: .payment
                            )

                        transaction.student =
                            student

                        transaction.notes =
                            notes.isEmpty
                            ? nil
                            : notes

                        context.insert(
                            transaction
                        )

                        try? context.save()

                        dismiss()
                    }
                }
            }
        }
    }
}
