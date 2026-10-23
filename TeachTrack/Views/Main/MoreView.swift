import SwiftUI

struct MoreView: View {
    var body: some View {
        List {
            TeachTrackHero(
                eyebrow: "Workspace",
                title: "More to explore",
                detail: "Reports and preferences for your teaching business.",
                symbol: "square.grid.2x2.fill",
                color: TeachTrackDesign.sunflower
            )

            NavigationLink {
                ReportsView()
            } label: {
                TeachTrackIconRow(
                    title: "Reports",
                    detail: "Lessons, attendance, and finances",
                    symbol: "chart.bar",
                    color: TeachTrackDesign.blue
                )
            }

            NavigationLink {
                SettingsView()
            } label: {
                TeachTrackIconRow(
                    title: "Settings",
                    detail: "Storage and app preferences",
                    symbol: "gearshape",
                    color: TeachTrackDesign.violet
                )
            }
        }
        .teachTrackScreen()
        .navigationTitle("More")
        .navigationBarTitleDisplayMode(.inline)
    }
}
