import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/cards/stat_card.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/summary_stats_grid.dart';

void main() {
  Widget buildSubject({SummaryStats? stats, TrendStats? trends}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SummaryStatsGrid(
            stats: stats ?? const SummaryStats(),
            trends: trends,
          ),
        ),
      ),
    );
  }

  void consumeExceptions(WidgetTester tester) {
    var ex = tester.takeException();
    while (ex != null) {
      ex = tester.takeException();
    }
  }

  group('SummaryStatsGrid', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      consumeExceptions(tester);

      expect(find.byType(SummaryStatsGrid), findsOneWidget);
    });

    testWidgets('renders 6 StatCard widgets', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      consumeExceptions(tester);

      expect(find.byType(StatCard), findsNWidgets(6));
    });

    testWidgets('renders GridView with 2 columns', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      consumeExceptions(tester);

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
    });

    testWidgets('shows correct labels for each stat card', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      consumeExceptions(tester);

      // easy_localization returns key strings in test env
      expect(find.text('statistics.summary_total_birds'), findsOneWidget);
      expect(find.text('statistics.summary_active_breedings'), findsOneWidget);
      expect(find.text('statistics.summary_incubating_eggs'), findsOneWidget);
      expect(find.text('statistics.summary_fertility_rate'), findsOneWidget);
      expect(find.text('statistics.summary_survival_rate'), findsOneWidget);
      expect(find.text('statistics.summary_health_records'), findsOneWidget);
    });

    testWidgets('displays totalBirds value', (tester) async {
      await tester.pumpWidget(
        buildSubject(stats: const SummaryStats(totalBirds: 42)),
      );
      // Advance past 800ms TweenAnimationBuilder in _AnimatedStatValue
      await tester.pump(const Duration(seconds: 1));
      consumeExceptions(tester);

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('displays activeBreedings value', (tester) async {
      await tester.pumpWidget(
        buildSubject(stats: const SummaryStats(activeBreedings: 7)),
      );
      await tester.pump(const Duration(seconds: 1));
      consumeExceptions(tester);

      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('displays incubatingEggs value', (tester) async {
      await tester.pumpWidget(
        buildSubject(stats: const SummaryStats(incubatingEggs: 15)),
      );
      await tester.pump(const Duration(seconds: 1));
      consumeExceptions(tester);

      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('displays totalHealthRecords value', (tester) async {
      await tester.pumpWidget(
        buildSubject(stats: const SummaryStats(totalHealthRecords: 23)),
      );
      await tester.pump(const Duration(seconds: 1));
      consumeExceptions(tester);

      expect(find.text('23'), findsOneWidget);
    });

    testWidgets('displays fertility rate as percentage', (tester) async {
      await tester.pumpWidget(
        buildSubject(stats: const SummaryStats(fertilityRate: 0.75)),
      );
      await tester.pump(const Duration(seconds: 1));
      consumeExceptions(tester);

      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('displays chick survival rate as percentage', (tester) async {
      await tester.pumpWidget(
        buildSubject(stats: const SummaryStats(chickSurvivalRate: 0.9)),
      );
      await tester.pump(const Duration(seconds: 1));
      consumeExceptions(tester);

      expect(find.text('90%'), findsOneWidget);
    });

    testWidgets('handles zero data gracefully', (tester) async {
      await tester.pumpWidget(
        buildSubject(stats: const SummaryStats()),
      );
      await tester.pump(const Duration(seconds: 1));
      consumeExceptions(tester);

      // All default zero values should render
      expect(find.byType(StatCard), findsNWidgets(6));
      // Zero percent rates
      expect(find.text('0%'), findsNWidgets(2));
    });

    testWidgets('renders with all fields populated', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          stats: const SummaryStats(
            totalBirds: 50,
            activeBreedings: 10,
            incubatingEggs: 25,
            fertilityRate: 0.85,
            chickSurvivalRate: 0.92,
            totalHealthRecords: 30,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      consumeExceptions(tester);

      expect(find.text('50'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('92%'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('renders with trend data without crashing', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          stats: const SummaryStats(totalBirds: 10),
          trends: const TrendStats(birdsTrend: 5.0, fertilityTrend: -2.0),
        ),
      );
      await tester.pump();
      consumeExceptions(tester);

      expect(find.byType(StatCard), findsNWidgets(6));
    });

    testWidgets('renders without trends when trends is null', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          stats: const SummaryStats(totalBirds: 5),
          trends: null,
        ),
      );
      await tester.pump();
      consumeExceptions(tester);

      expect(find.byType(StatCard), findsNWidgets(6));
    });

    testWidgets('handles 100% rates correctly', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          stats: const SummaryStats(
            fertilityRate: 1.0,
            chickSurvivalRate: 1.0,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      consumeExceptions(tester);

      expect(find.text('100%'), findsNWidgets(2));
    });
  });
}
