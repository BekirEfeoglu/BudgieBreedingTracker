import 'package:flutter/foundation.dart' show immutable;

@immutable
class HomeWidgetDashboardSnapshot {
  final int eggTurningCount;
  final int activeBreedingsCount;
  final String nextTurningLabel;
  final String lastUpdatedLabel;
  final DateTime lastUpdatedAt;

  const HomeWidgetDashboardSnapshot({
    required this.eggTurningCount,
    required this.activeBreedingsCount,
    required this.nextTurningLabel,
    required this.lastUpdatedLabel,
    required this.lastUpdatedAt,
  });

  bool get hasWorkToday => eggTurningCount > 0 || activeBreedingsCount > 0;

  /// Native iOS widget reads this as `last_updated_epoch_seconds`. Used to
  /// detect stale data older than its freshness window.
  int get lastUpdatedEpochSeconds =>
      lastUpdatedAt.toUtc().millisecondsSinceEpoch ~/ 1000;

  // lastUpdatedLabel/lastUpdatedAt are display-only and change on every
  // recompute (relative-time string, DateTime.now()) even when the
  // underlying dashboard content is unchanged. Excluding them keeps the
  // ref.listen dedup guard in home_screen.dart effective — otherwise it
  // would sync the native widget on every unrelated Drift table
  // invalidation, blowing through iOS WidgetKit's ~40/day budget (see
  // home-widget.md anti-pattern #1).
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeWidgetDashboardSnapshot &&
          runtimeType == other.runtimeType &&
          eggTurningCount == other.eggTurningCount &&
          activeBreedingsCount == other.activeBreedingsCount &&
          nextTurningLabel == other.nextTurningLabel;

  @override
  int get hashCode =>
      Object.hash(eggTurningCount, activeBreedingsCount, nextTurningLabel);
}
