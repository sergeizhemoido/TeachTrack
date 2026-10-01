import SwiftUI

enum TeachTrackDesign {
    static let accent = Color.accentColor
    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let muted = Color(uiColor: .secondaryLabel)
    static let blue = Color(red: 0.23, green: 0.40, blue: 0.76)
    static let sky = Color(red: 0.16, green: 0.53, blue: 0.75)
    static let coral = Color(red: 0.86, green: 0.38, blue: 0.38)
    static let studentGreen = Color(red: 0.18, green: 0.56, blue: 0.32)
    static let sunflower = Color(red: 0.70, green: 0.51, blue: 0.08)
    static let amber = Color(red: 0.77, green: 0.45, blue: 0.12)
    static let violet = Color(red: 0.51, green: 0.37, blue: 0.72)
    static let mint = Color(red: 0.12, green: 0.55, blue: 0.49)
    static let positive = Color(red: 0.12, green: 0.55, blue: 0.40)
    static let warning = Color(red: 0.80, green: 0.39, blue: 0.16)
}

extension OrganizationType {
    var displaySymbol: String {
        switch self {
        case .school: "building.2.fill"
        case .kindergarten: "house.fill"
        case .privateClient: "person.crop.circle.fill"
        }
    }

    var displayColor: Color {
        switch self {
        case .school: TeachTrackDesign.blue
        case .kindergarten: TeachTrackDesign.amber
        case .privateClient: TeachTrackDesign.violet
        }
    }
}

private struct TeachTrackScreenStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(TeachTrackDesign.canvas)
            .listStyle(.insetGrouped)
            .environment(\.defaultMinListRowHeight, 54)
    }
}

extension View {
    func teachTrackScreen() -> some View {
        modifier(TeachTrackScreenStyle())
    }
}

struct TeachTrackHero: View {
    let eyebrow: String
    let title: String
    let detail: String
    let symbol: String
    var color: Color = TeachTrackDesign.accent

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(eyebrow.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(color)

                Text(title)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)

                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: symbol)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 52, height: 52)
                .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 16))
                .accessibilityHidden(true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(TeachTrackDesign.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(LinearGradient(
                            colors: [color.opacity(0.18), color.opacity(0.035)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(color.opacity(0.13), lineWidth: 1)
        }
        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 12, trailing: 16))
        .listRowBackground(Color.clear)
    }
}

struct TeachTrackIconRow: View {
    let title: String
    let detail: String?
    let symbol: String
    var color: Color = TeachTrackDesign.accent

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.11), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 3)
    }
}

struct TeachTrackMetric: View {
    let title: String
    let value: String
    let symbol: String
    var color: Color = TeachTrackDesign.accent
    var valueID: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.11), in: RoundedRectangle(cornerRadius: 11))
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .minimumScaleFactor(0.75)
                .lineLimit(1)
                .foregroundStyle(.primary)
                .accessibilityIdentifier(valueID ?? "metric-\(title)")
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(TeachTrackDesign.surface, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct TeachTrackEmptyState: View {
    let title: String
    let detail: String
    let symbol: String
    var color: Color = TeachTrackDesign.accent

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 58, height: 58)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
                .accessibilityHidden(true)
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .semibold))
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(TeachTrackDesign.surface, in: RoundedRectangle(cornerRadius: 20))
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
        .listRowBackground(Color.clear)
    }
}
