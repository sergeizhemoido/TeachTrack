//
//  TeachTrackApp.swift
//  TeachTrack
//
//  Created by Sergei Zhemoido on 6/9/26.
//

import SwiftUI
import SwiftData

@main
struct TeachTrackApp: App {
    @StateObject private var storage = StorageCoordinator()

    // CloudKit uses a separate, explicitly managed archive. Keep this live
    // SwiftData store local even after the CloudKit entitlement is configured.
    private static let dataContainer: ModelContainer = {
        let schema = Schema([
            Organization.self,
            Group.self,
            Student.self,
            Contact.self,
            Enrollment.self,
            ScheduleRule.self,
            ScheduleException.self,
            Lesson.self,
            Attendance.self,
            AttendanceRevision.self,
            Transaction.self,
            StudentNote.self,
            LessonNote.self
        ])
        let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to open the TeachTrack database: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            StorageRootView()
                .environmentObject(storage)
        }
        .modelContainer(Self.dataContainer)
    }
}

private struct StorageRootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var storage: StorageCoordinator

    var body: some View {
        MainTabView()
            .id(storage.generation)
            .task {
                storage.connect(context)
                await storage.refresh()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task { await storage.refresh() }
                }
            }
    }
}
