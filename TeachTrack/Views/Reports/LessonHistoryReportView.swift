import SwiftUI
import SwiftData

struct LessonHistoryReportView: View {
    let range: ReportDateRange?

    init(range: ReportDateRange? = nil) {
        self.range = range
    }

    @Query(sort: \Lesson.startDate, order: .reverse)
    private var lessons: [Lesson]

    @State private var includeArchived = false

    private var visibleLessons: [Lesson] {
        ReportVisibility.lessons(
            lessons,
            includeArchived: includeArchived,
            range: range
        )
    }

    var body: some View {
        List {
            TeachTrackHero(
                eyebrow: "Teaching history",
                title: "Every lesson, in one place",
                detail: "Review completed and cancelled lessons, dates, and attendance. Upcoming lessons stay in Calendar.",
                symbol: "calendar.badge.clock",
                color: TeachTrackDesign.sunflower
            )

            Section("View Options") {
                Toggle("Include Archived Groups", isOn: $includeArchived)
            }

            Section("Past Lessons · \(visibleLessons.count)") {
                if visibleLessons.isEmpty {
                    ContentUnavailableView(
                        "No Lesson History",
                        systemImage: "calendar",
                        description: Text("Past lessons appear here.")
                    )
                }
                ForEach(visibleLessons, id: \.uuid) { lesson in
                    NavigationLink {
                        LessonDetailView(lesson: lesson)
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(lesson.group.name)
                                    .font(.system(.body, design: .rounded, weight: .semibold))
                                Spacer()
                                Text(lesson.status.rawValue.capitalized)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(lesson.status == .cancelled
                                        ? TeachTrackDesign.warning : TeachTrackDesign.positive)
                            }
                            Text(lesson.startDate, format: .dateTime)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(lesson.attendances.count) attendance records")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .teachTrackScreen()
        .navigationTitle("Lesson History")
    }
}
