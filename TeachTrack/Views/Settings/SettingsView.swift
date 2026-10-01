//
//  SettingsView.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/11/26.
//
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var storage: StorageCoordinator
    @State private var selectedLocation: DatabaseLocation = .phone
    @State private var requestedLocation: DatabaseLocation?
    @State private var showClearConfirmation = false
    @State private var showReplaceCloudConfirmation = false
    @State private var errorMessage: String?

    var body: some View {

        Form {
            TeachTrackHero(
                eyebrow: "Preferences",
                title: "Application",
                detail: "Your workspace settings and app information.",
                symbol: "slider.horizontal.3",
                color: TeachTrackDesign.sunflower
            )

            Section("About") {
                LabeledContent("Version", value: "1.01")
            }

            Section("Database Storage") {
                if CloudDatabaseStore.isConfigured {
                    Picker("Store Database", selection: $selectedLocation) {
                        ForEach(DatabaseLocation.allCases) { location in
                            Text(location.title).tag(location)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(storage.isWorking)
                    .accessibilityIdentifier("databaseLocationPicker")
                    .onChange(of: selectedLocation) { _, newValue in
                        if newValue != storage.location {
                            requestedLocation = newValue
                        }
                    }
                    Button("Check iCloud Connection") {
                        Task {
                            do { try await storage.checkCloudConnection() }
                            catch { errorMessage = error.localizedDescription }
                        }
                    }
                    .disabled(storage.isWorking)
                    .accessibilityIdentifier("checkCloudConnectionButton")
                } else {
                    LabeledContent("Store Database", value: "On This iPhone")
                    Text("iCloud storage requires a CloudKit container configured for this app.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if storage.isWorking {
                    HStack {
                        ProgressView()
                        Text(storage.status)
                    }
                } else if !storage.status.isEmpty {
                    Text(storage.status)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Text(storage.location == .cloud
                     ? "Changes are copied to iCloud when online. A working copy remains on this iPhone."
                     : "Your database is stored only on this iPhone.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Erase Data") {
                Button(role: .destructive) {
                    showClearConfirmation = true
                } label: {
                    Label("Clear Database", systemImage: "trash")
                }
                .disabled(storage.isWorking)
                .accessibilityIdentifier("clearDatabaseButton")
            }
        }
        .teachTrackScreen()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { selectedLocation = storage.location }
        .onReceive(storage.$location) { selectedLocation = $0 }
        .confirmationDialog(
            requestedLocation == .cloud ? "Copy Database to iCloud?" : "Move Database to This iPhone?",
            isPresented: Binding(
                get: { requestedLocation != nil },
                set: { if !$0 { requestedLocation = nil; selectedLocation = storage.location } }
            )
        ) {
            if requestedLocation == .cloud {
                Button("Copy to iCloud") { switchStorage(to: .cloud) }
            } else {
                Button("Copy to iPhone and Delete Cloud Copy", role: .destructive) {
                    switchStorage(to: .phone)
                }
            }
            Button("Cancel", role: .cancel) { selectedLocation = storage.location }
        } message: {
            Text(requestedLocation == .cloud
                 ? "The complete database will be copied to your private iCloud account."
                 : "The latest cloud data will be copied to this iPhone. The database copy in iCloud will then be deleted.")
        }
        .confirmationDialog(
            "Permanently Clear Database?",
            isPresented: $showClearConfirmation
        ) {
            Button("Delete All Data", role: .destructive) {
                Task {
                    do { try await storage.clearDatabase() }
                    catch { errorMessage = error.localizedDescription }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This deletes all organizations, groups, students, lessons, attendance, payments, and contacts. If iCloud storage is on, its cloud copy is deleted too. This cannot be undone.")
        }
        .confirmationDialog(
            "Replace Existing Cloud Copy?",
            isPresented: $showReplaceCloudConfirmation
        ) {
            Button("Replace Cloud Copy", role: .destructive) {
                Task {
                    do { try await storage.enableCloud(replaceExisting: true) }
                    catch { errorMessage = error.localizedDescription }
                    selectedLocation = storage.location
                }
            }
            Button("Cancel", role: .cancel) { selectedLocation = storage.location }
        } message: {
            Text("iCloud already has a Application database. Replacing it permanently removes that cloud copy and uploads the database from this iPhone.")
        }
        .alert("Storage Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }

    private func switchStorage(to location: DatabaseLocation) {
        requestedLocation = nil
        Task {
            do {
                if location == .cloud {
                    try await storage.enableCloud()
                } else {
                    try await storage.disableCloud()
                }
            } catch StorageCoordinator.StorageError.cloudCopyExists {
                showReplaceCloudConfirmation = true
            } catch {
                errorMessage = error.localizedDescription
            }
            selectedLocation = storage.location
        }
    }
}
