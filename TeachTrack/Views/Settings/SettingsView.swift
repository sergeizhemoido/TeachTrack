//
//  SettingsView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/11/26.
//
import SwiftUI

struct SettingsView: View {

    var body: some View {

        Form {

            Section("TeachTrack") {

                Text("Version 1.0")
            }

            Section("Cloud") {

                Text("CloudKit Enabled")
            }
        }
        .navigationTitle("Settings")
    }
}
