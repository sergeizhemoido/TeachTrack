//
//  OrganizationDetailView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/10/26.
//
import SwiftUI

struct OrganizationDetailView: View {

    let organization: Organization

    var body: some View {

        GroupListView(

            organization: organization

        )

    }

}
