import SwiftUI
import WidgetKit

// MARK: - Shared keys / configuration

private enum WidgetKeys {
  static let appGroupId = "group.com.budgiebreeding.tracker"
  static let eggTurningCount = "egg_turning_count"
  static let activeBreedingsCount = "active_breedings_count"
  static let nextTurningLabel = "next_turning_label"
  static let hasWorkToday = "has_work_today"
  static let lastUpdatedLabel = "last_updated_label"
  static let lastUpdatedEpochSeconds = "last_updated_epoch_seconds"
}

private enum DeepLink {
  static let scheme = "io.supabase.budgiebreeding"
  static let home = URL(string: "\(scheme)://home")!
  static let eggs = URL(string: "\(scheme)://eggs")!
  static let breedings = URL(string: "\(scheme)://breeding")!
  static let calendar = URL(string: "\(scheme)://calendar")!
}

private enum WidgetCopy {
  /// Two-hour freshness window before we mark data as stale.
  static let staleThreshold: TimeInterval = 2 * 60 * 60

  static func t(_ key: String) -> String {
    NSLocalizedString(key, bundle: .main, comment: "")
  }

  static func t(_ key: String, _ args: CVarArg...) -> String {
    String(format: NSLocalizedString(key, bundle: .main, comment: ""), arguments: args)
  }
}

// MARK: - Timeline entry

struct BudgieDashboardEntry: TimelineEntry {
  let date: Date
  let eggTurningCount: Int
  let activeBreedingsCount: Int
  let nextTurningLabel: String
  let hasWorkToday: Bool
  let lastUpdatedLabel: String
  let lastUpdatedAt: Date?
  let relevance: TimelineEntryRelevance?

  var isStale: Bool {
    guard let lastUpdatedAt else { return false }
    return Date().timeIntervalSince(lastUpdatedAt) > WidgetCopy.staleThreshold
  }
}

// MARK: - Provider

struct BudgieDashboardProvider: TimelineProvider {
  func placeholder(in context: Context) -> BudgieDashboardEntry {
    // Sample-shaped placeholder so the iOS widget gallery and Smart Stack
    // previews show plausible, legible content instead of skeleton bars.
    sampleEntry()
  }

  func getSnapshot(in context: Context, completion: @escaping (BudgieDashboardEntry) -> Void) {
    // When the system is rendering a gallery / Smart Stack preview, return a
    // sample entry so users can see what the widget will look like before
    // they install it (UserDefaults may be empty on a fresh install).
    if context.isPreview {
      completion(sampleEntry())
    } else {
      completion(readEntry())
    }
  }

  func getTimeline(
    in context: Context,
    completion: @escaping (Timeline<BudgieDashboardEntry>) -> Void
  ) {
    let entry = readEntry()
    completion(Timeline(entries: [entry], policy: .after(nextRefreshDate())))
  }

  private func sampleEntry() -> BudgieDashboardEntry {
    BudgieDashboardEntry(
      date: Date(),
      eggTurningCount: 4,
      activeBreedingsCount: 2,
      nextTurningLabel: "14:30",
      hasWorkToday: true,
      lastUpdatedLabel: "09:05",
      lastUpdatedAt: Date().addingTimeInterval(-600),
      relevance: TimelineEntryRelevance(score: 60)
    )
  }

  private func readEntry() -> BudgieDashboardEntry {
    let defaults = UserDefaults(suiteName: WidgetKeys.appGroupId)
    let epoch = defaults?.double(forKey: WidgetKeys.lastUpdatedEpochSeconds) ?? 0
    let lastUpdatedAt: Date? = epoch > 0 ? Date(timeIntervalSince1970: epoch) : nil
    let hasWorkToday = defaults?.bool(forKey: WidgetKeys.hasWorkToday) ?? false
    let eggTurningCount = defaults?.integer(forKey: WidgetKeys.eggTurningCount) ?? 0

    // Smart Stack relevance: prioritise widget when there is work today or eggs to turn.
    let relevanceScore: Float
    if hasWorkToday && eggTurningCount > 0 {
      relevanceScore = 90
    } else if hasWorkToday {
      relevanceScore = 70
    } else {
      relevanceScore = 30
    }
    let relevance = TimelineEntryRelevance(score: relevanceScore)

    return BudgieDashboardEntry(
      date: Date(),
      eggTurningCount: eggTurningCount,
      activeBreedingsCount: defaults?.integer(forKey: WidgetKeys.activeBreedingsCount) ?? 0,
      nextTurningLabel: defaults?.string(forKey: WidgetKeys.nextTurningLabel) ?? "",
      hasWorkToday: hasWorkToday,
      lastUpdatedLabel: defaults?.string(forKey: WidgetKeys.lastUpdatedLabel)
        ?? WidgetCopy.t("placeholder.no_time"),
      lastUpdatedAt: lastUpdatedAt,
      relevance: relevance
    )
  }

  private func nextRefreshDate() -> Date {
    Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
  }
}

// MARK: - Color tokens (light + dark adaptive)

private enum BrandColors {
  static let ink = Color("WidgetInk", bundle: .main, fallback: Color.primary)
  static let blue = Color("WidgetBlue", bundle: .main, fallback: Color(red: 0.10, green: 0.31, blue: 0.74))
  static let teal = Color("WidgetTeal", bundle: .main, fallback: Color(red: 0.02, green: 0.48, blue: 0.46))
  static let orange = Color("WidgetOrange", bundle: .main, fallback: Color(red: 0.78, green: 0.34, blue: 0.04))
  static let green = Color("WidgetGreen", bundle: .main, fallback: Color(red: 0.04, green: 0.46, blue: 0.22))
}

private extension Color {
  init(_ named: String, bundle: Bundle?, fallback: Color) {
    #if canImport(UIKit)
    if let uiColor = UIColor(named: named, in: bundle, compatibleWith: nil) {
      self = Color(uiColor: uiColor)
    } else {
      self = fallback
    }
    #else
    self = fallback
    #endif
  }
}

// MARK: - Home Screen widget views

struct BudgieDashboardWidgetView: View {
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var colorScheme

  var entry: BudgieDashboardProvider.Entry

  @ViewBuilder
  var body: some View {
    if #available(iOS 17.0, *) {
      content
        .containerBackground(for: .widget) { widgetBackground }
    } else {
      content
        .background(widgetBackground)
    }
  }

  private var content: some View {
    Group {
      switch family {
      case .systemMedium: mediumContent
      case .systemLarge:  largeContent
      default:            smallContent
      }
    }
    .widgetURL(DeepLink.home)
  }

  private var widgetBackground: some View {
    let stops: [Color] = colorScheme == .dark
      ? [
          Color(red: 0.05, green: 0.07, blue: 0.13),
          Color(red: 0.07, green: 0.13, blue: 0.18),
          Color(red: 0.06, green: 0.09, blue: 0.22),
        ]
      : [
          Color(red: 0.98, green: 0.99, blue: 1.00),
          Color(red: 0.90, green: 0.96, blue: 0.98),
          Color(red: 0.91, green: 0.93, blue: 1.00),
        ]
    return LinearGradient(colors: stops, startPoint: .topLeading, endPoint: .bottomTrailing)
  }

  // MARK: small

  private var smallContent: some View {
    VStack(alignment: .leading, spacing: 8) {
      HeaderView(style: .compact)
      Spacer(minLength: 0)
      Text("\(entry.eggTurningCount)")
        .font(.system(size: 34, weight: .bold, design: .rounded))
        .foregroundStyle(BrandColors.ink)
      Text(WidgetCopy.t("metric.eggs.caption"))
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.72)
      StatusPill(text: shortStatusText, isActive: entry.hasWorkToday)
      if entry.isStale { StaleBadge() }
    }
  }

  // MARK: medium

  private var mediumContent: some View {
    VStack(alignment: .leading, spacing: 11) {
      HStack(alignment: .center, spacing: 10) {
        HeaderView(style: .regular)
        Spacer(minLength: 8)
        StatusPill(text: shortStatusText, isActive: entry.hasWorkToday)
      }
      HStack(spacing: 10) {
        linkable(DeepLink.eggs) {
          MetricCard(
            value: entry.eggTurningCount,
            title: WidgetCopy.t("metric.eggs.title"),
            subtitle: WidgetCopy.t("metric.eggs.subtitle"),
            systemImage: "arrow.triangle.2.circlepath",
            isPrimary: true
          )
        }
        linkable(DeepLink.breedings) {
          MetricCard(
            value: entry.activeBreedingsCount,
            title: WidgetCopy.t("metric.breedings.title"),
            subtitle: WidgetCopy.t("metric.breedings.subtitle"),
            systemImage: "heart.text.square",
            isPrimary: false
          )
        }
      }
      FooterView(
        statusText: statusText,
        lastUpdatedLabel: entry.lastUpdatedLabel,
        isStale: entry.isStale
      )
    }
  }

  // MARK: large

  private var largeContent: some View {
    VStack(alignment: .leading, spacing: 14) {
      HeaderView(style: .regular)
      HStack(spacing: 10) {
        linkable(DeepLink.eggs) {
          MetricCard(
            value: entry.eggTurningCount,
            title: WidgetCopy.t("metric.eggs.title"),
            subtitle: WidgetCopy.t("metric.eggs.subtitle"),
            systemImage: "arrow.triangle.2.circlepath",
            isPrimary: true
          )
        }
        linkable(DeepLink.breedings) {
          MetricCard(
            value: entry.activeBreedingsCount,
            title: WidgetCopy.t("metric.breedings.title"),
            subtitle: WidgetCopy.t("metric.breedings.subtitle"),
            systemImage: "heart.text.square",
            isPrimary: false
          )
        }
      }
      VStack(alignment: .leading, spacing: 8) {
        Text(WidgetCopy.t("section.daily_status"))
          .font(.caption)
          .fontWeight(.semibold)
          .foregroundStyle(.secondary)
        linkable(DeepLink.calendar) {
          StatusRow(
            title: WidgetCopy.t(entry.hasWorkToday ? "status.needs_attention" : "status.routine_clean"),
            subtitle: statusText,
            systemImage: entry.hasWorkToday ? "bell.badge" : "checkmark.seal"
          )
        }
        StatusRow(
          title: WidgetCopy.t("section.last_update"),
          subtitle: entry.lastUpdatedLabel,
          systemImage: entry.isStale ? "exclamationmark.triangle.fill" : "clock"
        )
        if entry.isStale {
          Text(WidgetCopy.t("section.stale.description"))
            .font(.caption2)
            .foregroundStyle(BrandColors.orange)
        }
      }
    }
  }

  // MARK: helpers

  @ViewBuilder
  private func linkable<Content: View>(_ url: URL, @ViewBuilder content: () -> Content) -> some View {
    if #available(iOS 17.0, *) {
      Link(destination: url) { content() }
    } else {
      content()
    }
  }

  private var statusText: String {
    if entry.hasWorkToday && !entry.nextTurningLabel.isEmpty {
      return WidgetCopy.t("status.next_turning", entry.nextTurningLabel)
    }
    if entry.hasWorkToday { return WidgetCopy.t("status.has_work") }
    return WidgetCopy.t("status.no_work")
  }

  private var shortStatusText: String {
    if entry.hasWorkToday && !entry.nextTurningLabel.isEmpty {
      return entry.nextTurningLabel
    }
    return WidgetCopy.t(entry.hasWorkToday ? "status.short.has_work" : "status.short.no_work")
  }
}

// MARK: - Reusable subviews (home screen)

private struct MetricCard: View {
  let value: Int
  let title: String
  let subtitle: String
  let systemImage: String
  let isPrimary: Bool

  var body: some View {
    HStack(spacing: 9) {
      ZStack {
        Circle().fill(accentColor.opacity(0.12))
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
    .background(cardFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(cardStroke, lineWidth: 1)
    }
  }

  private var cardFill: Color {
    Color.primary.opacity(0.06)
  }
  private var cardStroke: Color {
    Color.primary.opacity(0.10)
  }
  private var accentColor: Color {
    isPrimary ? BrandColors.blue : BrandColors.teal
  }
}

private struct HeaderView: View {
  enum Style { case compact, regular }
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

  private var logoSize: CGFloat { style == .compact ? 24 : 32 }
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
    .background(Color.primary.opacity(0.08), in: Capsule())
  }
}

private struct StaleBadge: View {
  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 9, weight: .bold))
      Text(WidgetCopy.t("section.stale"))
        .font(.caption2)
        .fontWeight(.semibold)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
    .foregroundStyle(BrandColors.orange)
  }
}

private struct FooterView: View {
  let statusText: String
  let lastUpdatedLabel: String
  let isStale: Bool

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: isStale ? "exclamationmark.triangle.fill" : "sparkles")
        .font(.caption2)
        .foregroundStyle(isStale ? BrandColors.orange : BrandColors.blue)
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
        .foregroundStyle(isStale ? BrandColors.orange : .secondary)
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
        .background(Color.primary.opacity(0.08), in: Circle())
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
    .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
  }
}

// MARK: - Lock Screen / Accessory views (iOS 16+)

@available(iOS 16.0, *)
struct BudgieAccessoryWidgetView: View {
  @Environment(\.widgetFamily) private var family
  var entry: BudgieDashboardProvider.Entry

  @ViewBuilder
  var body: some View {
    let inner = Group {
      switch family {
      case .accessoryCircular:    circular
      case .accessoryRectangular: rectangular
      case .accessoryInline:      inline
      default:                    inline
      }
    }
    .widgetURL(DeepLink.eggs)

    if #available(iOS 17.0, *) {
      inner.containerBackground(for: .widget) { Color.clear }
    } else {
      inner
    }
  }

  private var circular: some View {
    ZStack {
      AccessoryWidgetBackground()
      VStack(spacing: 0) {
        Image(systemName: "arrow.triangle.2.circlepath")
          .font(.system(size: 10, weight: .bold))
        Text("\(entry.eggTurningCount)")
          .font(.system(size: 18, weight: .bold, design: .rounded))
          .minimumScaleFactor(0.7)
          .lineLimit(1)
      }
      .padding(2)
    }
    .accessibilityLabel(
      "\(entry.eggTurningCount) \(WidgetCopy.t("accessory.eggs.unit"))"
    )
  }

  private var rectangular: some View {
    HStack(spacing: 8) {
      Image(systemName: entry.hasWorkToday ? "bell.badge.fill" : "checkmark.seal.fill")
        .font(.system(size: 16, weight: .semibold))
        .widgetAccentable()
      VStack(alignment: .leading, spacing: 1) {
        Text("\(entry.eggTurningCount) \(WidgetCopy.t("accessory.eggs.unit"))")
          .font(.system(size: 14, weight: .semibold, design: .rounded))
          .lineLimit(1)
        Text(rectangularSubtitle)
          .font(.system(size: 11))
          .lineLimit(1)
          .minimumScaleFactor(0.7)
      }
      Spacer(minLength: 0)
    }
  }

  private var rectangularSubtitle: String {
    if entry.hasWorkToday && !entry.nextTurningLabel.isEmpty {
      return WidgetCopy.t("status.next_turning", entry.nextTurningLabel)
    }
    return WidgetCopy.t(entry.hasWorkToday ? "status.has_work" : "status.no_work")
  }

  private var inline: some View {
    let label: String
    if entry.eggTurningCount > 0 {
      label = "\(entry.eggTurningCount) \(WidgetCopy.t("accessory.eggs.unit"))"
    } else {
      label = WidgetCopy.t("accessory.routine_clean")
    }
    return Label(label, systemImage: "arrow.triangle.2.circlepath")
  }
}

// MARK: - Widget configuration

@main
struct BudgieDashboardWidget: Widget {
  let kind = "BudgieDashboardWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: BudgieDashboardProvider()) { entry in
      RootWidgetView(entry: entry)
    }
    .configurationDisplayName(LocalizedStringKey("widget.display_name"))
    .description(LocalizedStringKey("widget.description"))
    .supportedFamilies(supportedFamilies)
  }

  private var supportedFamilies: [WidgetFamily] {
    if #available(iOS 16.0, *) {
      return [
        .systemSmall, .systemMedium, .systemLarge,
        .accessoryCircular, .accessoryRectangular, .accessoryInline,
      ]
    } else {
      return [.systemSmall, .systemMedium, .systemLarge]
    }
  }
}

/// Dispatches between home-screen and lock-screen views based on the current
/// widget family so we register a single Widget (avoids WidgetBundle pitfalls)
/// while still supporting all six families.
private struct RootWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: BudgieDashboardProvider.Entry

  var body: some View {
    if #available(iOS 16.0, *), isAccessoryFamily {
      BudgieAccessoryWidgetView(entry: entry)
    } else {
      BudgieDashboardWidgetView(entry: entry)
    }
  }

  private var isAccessoryFamily: Bool {
    guard #available(iOS 16.0, *) else { return false }
    switch family {
    case .accessoryCircular, .accessoryRectangular, .accessoryInline:
      return true
    default:
      return false
    }
  }
}

// MARK: - Previews

struct BudgieDashboardWidgetView_Previews: PreviewProvider {
  static var previews: some View {
    let sample = BudgieDashboardEntry(
      date: Date(),
      eggTurningCount: 4,
      activeBreedingsCount: 2,
      nextTurningLabel: "14:30",
      hasWorkToday: true,
      lastUpdatedLabel: "09:05",
      lastUpdatedAt: Date().addingTimeInterval(-600),
      relevance: TimelineEntryRelevance(score: 80)
    )
    Group {
      BudgieDashboardWidgetView(entry: sample)
        .previewContext(WidgetPreviewContext(family: .systemSmall))
      BudgieDashboardWidgetView(entry: sample)
        .previewContext(WidgetPreviewContext(family: .systemMedium))
      BudgieDashboardWidgetView(entry: sample)
        .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
  }
}
