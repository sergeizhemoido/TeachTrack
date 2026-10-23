//
//  MainTabView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/11/26.
//
import SwiftUI

struct MainTabView: View {

    var body: some View {

        TabView {

            NavigationStack {
                OrganizationsListView()
            }
            .tabItem {
                Label(
                    "Organizations",
                    systemImage: "building.2"
                )
            }

            NavigationStack {
                StudentListView()
            }
            .tabItem {
                Label(
                    "Students",
                    systemImage: "person.3"
                )
            }

            NavigationStack {
                CalendarView()
            }
            .tabItem {
                Label(
                    "Calendar",
                    systemImage: "calendar"
                )
            }

            NavigationStack {
                FinanceDashboardView()
            }
            .tabItem {
                Label(
                    "Finance",
                    systemImage: "dollarsign.circle"
                )
            }

            NavigationStack {
                MoreView()
            }
            .tabItem {
                Label(
                    "More",
                    systemImage: "ellipsis.circle"
                )
            }
        }
        .tint(TeachTrackDesign.accent)
        .toolbarBackground(TeachTrackDesign.surface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

#Preview {
    MainTabView()
}
