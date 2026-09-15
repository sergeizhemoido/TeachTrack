//
//  ContactListView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/11/26.
//
import SwiftUI
import SwiftData

struct ContactListView: View {

    let student: Student

    @Query
    private var contacts: [Contact]

    @State
    private var showAddContact = false

    private var studentContacts: [Contact] {

        contacts.filter {
            $0.student.uuid == student.uuid
        }
    }

    var body: some View {

        List {

            ForEach(
                studentContacts,
                id: \.uuid
            ) { contact in

                NavigationLink {

                    ContactDetailView(
                        contact: contact
                    )

                } label: {

                    Text(
                        contact.name
                    )
                }
            }
        }
        .navigationTitle(
            "Contacts"
        )
        .toolbar {

            Button {

                showAddContact = true

            } label: {

                Image(systemName: "plus")
            }
        }
        .sheet(
            isPresented: $showAddContact
        ) {

            AddContactView(
                student: student
            )
        }
    }
}
