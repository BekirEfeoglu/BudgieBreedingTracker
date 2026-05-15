import SwiftUI
import WidgetKit

private enum WidgetKeys {
  static let appGroupId = "group.com.budgiebreeding.tracker"
  static let eggTurningCount = "egg_turning_count"
  static let activeBreedingsCount = "active_breedings_count"
  static let nextTurningLabel = "next_turning_label"
  static let hasWorkToday = "has_work_today"
  static let lastUpdatedLabel = "last_updated_label"
}

struct BudgieDashboardEntry: TimelineEntry {
  let date: Date
  let eggTurningCount: Int
  let activeBreedingsCount: Int
  let nextTurningLabel: String
  let hasWorkToday: Bool
  let lastUpdatedLabel: String
}

struct BudgieDashboardProvider: TimelineProvider {
  func placeholder(in context: Context) -> BudgieDashboardEntry {
    BudgieDashboardEntry(
      date: Date(),
      eggTurningCount: 0,
      activeBreedingsCount: 0,
      nextTurningLabel: "",
      hasWorkToday: false,
      lastUpdatedLabel: "--:--"
    )
  }

  func getSnapshot(
    in context: Context,
    completion: @escaping (BudgieDashboardEntry) -> Void
  ) {
    completion(readEntry())
  }

  func getTimeline(
    in context: Context,
    completion: @escaping (Timeline<BudgieDashboardEntry>) -> Void
  ) {
    completion(Timeline(entries: [readEntry()], policy: .after(nextRefreshDate())))
  }

  private func readEntry() -> BudgieDashboardEntry {
    let defaults = UserDefaults(suiteName: WidgetKeys.appGroupId)
    return BudgieDashboardEntry(
      date: Date(),
      eggTurningCount: defaults?.integer(forKey: WidgetKeys.eggTurningCount) ?? 0,
      activeBreedingsCount: defaults?.integer(forKey: WidgetKeys.activeBreedingsCount) ?? 0,
      nextTurningLabel: defaults?.string(forKey: WidgetKeys.nextTurningLabel) ?? "",
      hasWorkToday: defaults?.bool(forKey: WidgetKeys.hasWorkToday) ?? false,
      lastUpdatedLabel: defaults?.string(forKey: WidgetKeys.lastUpdatedLabel) ?? "--:--"
    )
  }

  private func nextRefreshDate() -> Date {
    Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
  }
}

struct BudgieDashboardWidgetView: View {
  @Environment(\.widgetFamily) private var family

  var entry: BudgieDashboardProvider.Entry

  @ViewBuilder
  var body: some View {
    if #available(iOS 17.0, *) {
      content
        .containerBackground(for: .widget) {
          widgetBackground
        }
    } else {
      content
        .background(widgetBackground)
    }
  }

  private var content: some View {
    Group {
      switch family {
      case .systemMedium:
        mediumContent
      case .systemLarge:
        largeContent
      default:
        smallContent
      }
    }
    .widgetURL(URL(string: "io.supabase.budgiebreeding://home"))
  }

  private var widgetBackground: some View {
    LinearGradient(
      colors: [
        Color(red: 0.98, green: 0.99, blue: 1.0),
        Color(red: 0.90, green: 0.96, blue: 0.98),
        Color(red: 0.91, green: 0.93, blue: 1.0),
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  private var smallContent: some View {
    VStack(alignment: .leading, spacing: 8) {
      HeaderView(style: .compact)
      Spacer(minLength: 0)
      Text("\(entry.eggTurningCount)")
        .font(.system(size: 34, weight: .bold, design: .rounded))
        .foregroundStyle(BrandColors.ink)
      Text("çevrilecek yumurta")
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.72)
      StatusPill(text: shortStatusText, isActive: entry.hasWorkToday)
    }
  }

  private var mediumContent: some View {
    VStack(alignment: .leading, spacing: 11) {
      HStack(alignment: .center, spacing: 10) {
        HeaderView(style: .regular)
        Spacer(minLength: 8)
        StatusPill(text: shortStatusText, isActive: entry.hasWorkToday)
      }
      HStack(spacing: 10) {
        MetricCard(
          value: entry.eggTurningCount,
          title: "Yumurta",
          subtitle: "bugün çevrilecek",
          systemImage: "arrow.triangle.2.circlepath",
          isPrimary: true
        )
        MetricCard(
          value: entry.activeBreedingsCount,
          title: "Üreme",
          subtitle: "aktif süreç",
          systemImage: "heart.text.square",
          isPrimary: false
        )
      }
      FooterView(statusText: statusText, lastUpdatedLabel: entry.lastUpdatedLabel)
    }
  }

  private var largeContent: some View {
    VStack(alignment: .leading, spacing: 14) {
      HeaderView(style: .regular)
      HStack(spacing: 10) {
        MetricCard(
          value: entry.eggTurningCount,
          title: "Yumurta",
          subtitle: "bugün çevrilecek",
          systemImage: "arrow.triangle.2.circlepath",
          isPrimary: true
        )
        MetricCard(
          value: entry.activeBreedingsCount,
          title: "Üreme",
          subtitle: "aktif süreç",
          systemImage: "heart.text.square",
          isPrimary: false
        )
      }
      VStack(alignment: .leading, spacing: 8) {
        Text("Günlük durum")
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)
        StatusRow(
          title: entry.hasWorkToday ? "Takip gerekiyor" : "Rutin temiz",
          subtitle: statusText,
          systemImage: entry.hasWorkToday ? "bell.badge" : "checkmark.seal"
        )
        StatusRow(
          title: "Son güncelleme",
          subtitle: entry.lastUpdatedLabel,
          systemImage: "clock"
        )
      }
    }
  }

  private var statusText: String {
    if entry.hasWorkToday && !entry.nextTurningLabel.isEmpty {
      return "Sonraki çevirme \(entry.nextTurningLabel)"
    }
    if entry.hasWorkToday {
      return "Bugün kontrol var"
    }
    return "Bugün rutin yok"
  }

  private var shortStatusText: String {
    if entry.hasWorkToday && !entry.nextTurningLabel.isEmpty {
      return entry.nextTurningLabel
    }
    return entry.hasWorkToday ? "Kontrol" : "Temiz"
  }
}

private struct MetricCard: View {
  let value: Int
  let title: String
  let subtitle: String
  let systemImage: String
  let isPrimary: Bool

  var body: some View {
    HStack(spacing: 9) {
      ZStack {
        Circle()
          .fill(accentColor.opacity(0.12))
        Image(systemName: systemImage)
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(accentColor)
      }
      .frame(width: 34, height: 34)

      VStack(alignment: .leading, spacing: 0) {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
          Text("\(value)")
            .font(.system(size: 25, weight: .bold, design: .rounded))
            .foregroundStyle(BrandColors.ink)
          Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(BrandColors.ink.opacity(0.82))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        Text(subtitle)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .minimumScaleFactor(0.72)
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 9)
    .padding(.vertical, 8)
    .background(.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(.white.opacity(0.72), lineWidth: 1)
    }
  }

  private var accentColor: Color {
    isPrimary ? BrandColors.blue : BrandColors.teal
  }
}

private struct HeaderView: View {
  enum Style {
    case compact
    case regular
  }

  let style: Style

  var body: some View {
    HStack(spacing: style == .compact ? 6 : 9) {
      Image("AppLogo")
        .resizable()
        .scaledToFit()
        .frame(width: logoSize, height: logoSize)
        .clipShape(RoundedRectangle(cornerRadius: style == .compact ? 7 : 9, style: .continuous))
      Text("BudgieBreedingTracker")
        .font(.system(size: style == .compact ? 12 : 17, weight: .bold, design: .rounded))
        .foregroundStyle(BrandColors.ink)
        .lineLimit(1)
        .minimumScaleFactor(0.62)
    }
  }

  private var logoSize: CGFloat {
    style == .compact ? 24 : 32
  }
}

private struct StatusPill: View {
  let text: String
  let isActive: Bool

  var body: some View {
    HStack(spacing: 5) {
      Image(systemName: isActive ? "bell.badge.fill" : "checkmark.circle.fill")
        .font(.caption2)
      Text(text)
        .font(.caption2)
        .fontWeight(.semibold)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
    .foregroundStyle(isActive ? BrandColors.orange : BrandColors.green)
    .padding(.horizontal, 7)
    .padding(.vertical, 5)
    .background(.white.opacity(0.70), in: Capsule())
  }
}

private struct FooterView: View {
  let statusText: String
  let lastUpdatedLabel: String

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "sparkles")
        .font(.caption2)
        .foregroundStyle(BrandColors.blue)
      Text(statusText)
        .font(.caption2)
        .fontWeight(.semibold)
        .foregroundStyle(BrandColors.ink.opacity(0.78))
        .lineLimit(1)
        .minimumScaleFactor(0.72)
      Spacer(minLength: 6)
      Text(lastUpdatedLabel)
        .font(.caption2)
        .fontWeight(.medium)
        .foregroundStyle(.secondary)
    }
  }
}

private struct StatusRow: View {
  let title: String
  let subtitle: String
  let systemImage: String

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: systemImage)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(BrandColors.blue)
        .frame(width: 24, height: 24)
        .background(Color.white.opacity(0.66), in: Circle())
      VStack(alignment: .leading, spacing: 1) {
        Text(title)
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)
        Text(subtitle)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
      Spacer(minLength: 0)
    }
    .padding(10)
    .background(.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
  }
}

private enum BrandColors {
  static let ink = Color(red: 0.07, green: 0.10, blue: 0.18)
  static let blue = Color(red: 0.10, green: 0.31, blue: 0.74)
  static let teal = Color(red: 0.02, green: 0.48, blue: 0.46)
  static let orange = Color(red: 0.78, green: 0.34, blue: 0.04)
  static let green = Color(red: 0.04, green: 0.46, blue: 0.22)
}

@main
struct BudgieDashboardWidget: Widget {
  let kind = "BudgieDashboardWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: BudgieDashboardProvider()) { entry in
      BudgieDashboardWidgetView(entry: entry)
    }
    .configurationDisplayName("BudgieBreedingTracker")
    .description("Yumurta çevirme, aktif üreme ve günlük bakım özetini ana ekranda gösterir.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

struct BudgieDashboardWidgetView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      BudgieDashboardWidgetView(
        entry: BudgieDashboardEntry(
          date: Date(),
          eggTurningCount: 4,
          activeBreedingsCount: 2,
          nextTurningLabel: "14:30",
          hasWorkToday: true,
          lastUpdatedLabel: "09:05"
        )
      )
      .previewContext(WidgetPreviewContext(family: .systemSmall))

      BudgieDashboardWidgetView(
        entry: BudgieDashboardEntry(
          date: Date(),
          eggTurningCount: 4,
          activeBreedingsCount: 2,
          nextTurningLabel: "14:30",
          hasWorkToday: true,
          lastUpdatedLabel: "09:05"
        )
      )
      .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
  }
}
