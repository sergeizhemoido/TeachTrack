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
                StudentsListView()
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
                ReportsView()
            }
            .tabItem {
                Label(
                    "Reports",
                    systemImage: "chart.bar"
                )
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(
                    "Settings",
                    systemImage: "gear"
                )
            }
        }
    }
}

#Preview {
    MainTabView()
}
