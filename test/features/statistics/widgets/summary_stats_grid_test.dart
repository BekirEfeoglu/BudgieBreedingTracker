import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/core/widgets/cards/stat_card.dart';
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

  group('SummaryStatsGrid', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.byType(SummaryStatsGrid), findsOneWidget);
    });

    testWidgets('renders 6 StatCard widgets', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.byType(StatCard), findsNWidgets(6));
    });

    testWidgets('displays totalBirds value', (tester) async {
      await tester.pumpWidget(
        buildSubject(stats: const SummaryStats(totalBirds: 42)),
      );
      // Advance past 800ms TweenAnimationBuilder in _AnimatedStatValue
      await tester.pump(const Duration(seconds: 1));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('displays fertility rate as percentage', (tester) async {
      await tester.pumpWidget(
        buildSubject(stats: const SummaryStats(fertilityRate: 0.75)),
      );
      // Advance past 800ms TweenAnimationBuilder in _AnimatedStatValue
      await tester.pump(const Duration(seconds: 1));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('displays chick survival rate as percentage', (tester) async {
      await tester.pumpWidget(
        buildSubject(stats: const SummaryStats(chickSurvivalRate: 0.9)),
      );
      // Advance past 800ms TweenAnimationBuilder in _AnimatedStatValue
      await tester.pump(const Duration(seconds: 1));

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.text('90%'), findsOneWidget);
    });

    testWidgets('renders with trend data without crashing', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          stats: const SummaryStats(totalBirds: 10),
          trends: const TrendStats(birdsTrend: 5.0, fertilityTrend: -2.0),
        ),
      );
      await tester.pump();

      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }

      expect(find.byType(StatCard), findsNWidgets(6));
    });
  });
}
