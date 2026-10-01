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
            Section {
                Toggle("Include Archived Groups", isOn: $includeArchived)
            } footer: {
                Text("Upcoming lessons are shown in Calendar, not in history.")
            }
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
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lesson.group.name)
                        Text(lesson.startDate, format: .dateTime)
                            .font(.subheadline)
                        Text("\(lesson.status.rawValue.capitalized) · \(lesson.attendances.count) attendance records")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .teachTrackScreen()
        .navigationTitle("Lesson History")
    }
}
