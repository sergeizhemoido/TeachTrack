//
//  StudentDetailView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/9/26.
//
import SwiftUI
import SwiftData

struct StudentDetailView: View {

    let student: Student

    var body: some View {

        Form {

            Section("Student") {

                Text(
                    "\(student.firstName) \(student.lastName)"
                )

                if let phone = student.phone {

                    Text(phone)
                }

                if let email = student.email {

                    Text(email)
                }
            }

            Section("Contacts") {

                NavigationLink {

                    ContactListView(
                        student: student
                    )

                } label: {

                    Label(
                        "Contacts",
                        systemImage: "person.2"
                    )
                }
            }

            Section("Finance") {

                NavigationLink {

                    StudentBalanceView(
                        student: student
                    )

                } label: {

                    Label(
                        "Balance",
                        systemImage: "dollarsign.circle"
                    )
                }

                NavigationLink {

                    TransactionListView(
                        student: student
                    )

                } label: {

                    Label(
                        "Transactions",
                        systemImage: "list.bullet.rectangle"
                    )
                }

                NavigationLink {

                    AddPaymentView(
                        student: student
                    )

                } label: {

                    Label(
                        "Add Payment",
                        systemImage: "plus.circle"
                    )
                }
            }
        }
        .navigationTitle(
            "\(student.firstName) \(student.lastName)"
        )
    }
}
