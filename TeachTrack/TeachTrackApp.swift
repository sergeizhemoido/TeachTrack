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
        #if DEBUG
        let useAppStoreDemo = ProcessInfo.processInfo.arguments.contains("-AppStoreDemoData")
        #else
        let useAppStoreDemo = false
        #endif
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: useAppStoreDemo,
            cloudKitDatabase: .none
        )
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            #if DEBUG
            if useAppStoreDemo {
                try AppStoreDemoData.populate(ModelContext(container))
            }
            #endif
            return container
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
    @State private var isShowingSplash = true

    var body: some View {
        ZStack {
            if storage.isClearingDatabase {
                ProgressView("Deleting database…")
            } else {
                MainTabView()
                    .id(storage.generation)
                    .allowsHitTesting(!isShowingSplash)
                    .accessibilityHidden(isShowingSplash)
            }

            if isShowingSplash {
                LaunchWritingView {
                    withAnimation(.easeOut(duration: 0.15)) {
                        isShowingSplash = false
                    }
                }
                .transition(.opacity)
            }
        }
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

private struct LaunchWritingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var teacherProgress: CGFloat = 0
    @State private var organizerProgress: CGFloat = 0

    let onFinish: () -> Void

    private let ink = Color(red: 0.12, green: 0.28, blue: 0.57)
    private let paper = Color(red: 0.98, green: 0.97, blue: 0.94)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                paper

                Canvas { context, size in
                    var rules = Path()
                    for y in stride(from: CGFloat(0), through: size.height, by: 48) {
                        rules.move(to: CGPoint(x: 0, y: y))
                        rules.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    context.stroke(rules, with: .color(ink.opacity(0.10)), lineWidth: 1)
                }

                VStack(spacing: 2) {
                    writingLine("Teacher's", progress: teacherProgress)
                    writingLine("Organizer", progress: organizerProgress)
                }
                .font(.system(size: min(geometry.size.width * 0.14, 68), weight: .regular, design: .serif).italic())
                .foregroundStyle(ink)
                .shadow(color: ink.opacity(0.14), radius: 1, x: 0.5, y: 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Teacher's Organizer")
        .task {
            if reduceMotion {
                teacherProgress = 1
                organizerProgress = 1
            } else {
                withAnimation(.linear(duration: 0.75)) {
                    teacherProgress = 1
                }
                try? await Task.sleep(for: .seconds(0.78))
                guard !Task.isCancelled else { return }
                withAnimation(.linear(duration: 0.75)) {
                    organizerProgress = 1
                }
            }
            try? await Task.sleep(for: .seconds(reduceMotion ? 1.85 : 1.07))
            guard !Task.isCancelled else { return }
            onFinish()
        }
    }

    private func writingLine(_ title: String, progress: CGFloat) -> some View {
        Text(title)
            .fixedSize()
            .mask(alignment: .leading) {
                GeometryReader { proxy in
                    Rectangle()
                        .frame(width: proxy.size.width * progress)
                }
            }
    }
}
