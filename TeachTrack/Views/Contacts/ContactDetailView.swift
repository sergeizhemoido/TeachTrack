//
//  ContactDetailView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/11/26.
//
import SwiftUI

struct ContactDetailView: View {

    let contact: Contact

    var body: some View {

        Form {

            Text(contact.name)

            Text(contact.relationship)

            if let phone = contact.phone {

                Text(phone)
            }

            if let email = contact.email {

                Text(email)
            }
        }
        .navigationTitle(
            contact.name
        )
    }
}
