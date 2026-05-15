import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_highlights_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/statistics_highlight_cards.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('PersonalRecordsCard renders record labels', (tester) async {
    await tester.pumpWidget(
      wrap(
        const PersonalRecordsCard(
          records: PersonalRecords(
            mostProductiveSeason: SeasonRecord(year: 2025, chickCount: 8),
            topPair: TopPairRecord(pairId: 'pair-1', chickCount: 6),
            longestLivedBird: LongevityRecord(
              birdId: 'bird-1',
              birdName: 'Mavi',
              daysLived: 1200,
            ),
          ),
        ),
      ),
    );

    expect(find.text(l10n('statistics.personal_records')), findsOneWidget);
    expect(find.text(l10n('statistics.record_best_season')), findsOneWidget);
    expect(find.text(l10n('statistics.record_top_pair')), findsOneWidget);
    expect(find.text(l10n('statistics.record_longest_lived')), findsOneWidget);
  });

  testWidgets('SeasonComparisonCard renders current and previous seasons', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const SeasonComparisonCard(
          comparison: SeasonComparison(
            previous: SeasonStats(
              year: 2024,
              totalEggs: 10,
              fertileEggs: 6,
              hatchedChicks: 4,
              liveChicks: 3,
            ),
            current: SeasonStats(
              year: 2025,
              totalEggs: 12,
              fertileEggs: 9,
              hatchedChicks: 7,
              liveChicks: 7,
            ),
          ),
        ),
      ),
    );

    expect(find.text(l10n('statistics.season_comparison')), findsOneWidget);
    expect(find.text('2024'), findsOneWidget);
    expect(find.text('2025'), findsOneWidget);
  });

  testWidgets('HealthTrendSummaryCard renders health trend labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const HealthTrendSummaryCard(
          trend: HealthTrendSummary(
            busiestMonthKey: '2025-01',
            busiestMonthRecordCount: 5,
            mostVisitedBirdName: 'Mavi',
            mostVisitedBirdRecordCount: 3,
            averageTreatmentDays: 4.5,
          ),
        ),
      ),
    );

    expect(find.text(l10n('statistics.health_trend')), findsOneWidget);
    expect(find.text(l10n('statistics.health_peak_month')), findsOneWidget);
    expect(find.text(l10n('statistics.health_most_visited')), findsOneWidget);
    expect(find.text(l10n('statistics.health_avg_treatment')), findsOneWidget);
  });
}
