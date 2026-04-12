import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';
import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/screens/overview_tab.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/summary_stats_grid.dart';

Widget _createSubject() {
  return ProviderScope(
    overrides: [
      // Override underlying stream providers with empty data so all
      // computed statistics providers resolve to AsyncData immediately.
      birdsStreamProvider('anonymous').overrideWith((_) => Stream.value([])),
      breedingPairsStreamProvider(
        'anonymous',
      ).overrideWith((_) => Stream.value([])),
      eggsStreamProvider('anonymous').overrideWith((_) => Stream.value([])),
      chicksStreamProvider('anonymous').overrideWith((_) => Stream.value([])),
      birdCountProvider('anonymous').overrideWith((_) => Stream.value(0)),
      activeBreedingCountProvider(
        'anonymous',
      ).overrideWith((_) => Stream.value(0)),
      healthRecordCountProvider(
        'anonymous',
      ).overrideWith((_) => Stream.value(0)),
    ],
    child: const MaterialApp(home: Scaffold(body: OverviewTab())),
  );
}

void main() {
  group('OverviewTab', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(OverviewTab), findsOneWidget);
    });

    testWidgets('shows RefreshIndicator', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('shows SummaryStatsGrid with zero stats', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(SummaryStatsGrid), findsOneWidget);
    });

    testWidgets('shows gender distribution chart section', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('statistics.gender_distribution')), findsOneWidget);
    });

    testWidgets('shows species distribution section', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('statistics.species_distribution')), findsOneWidget);
    });

    testWidgets('shows color mutation chart section', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('statistics.color_mutation')), findsOneWidget);
    });

    testWidgets('shows age distribution chart section', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('statistics.age_distribution')), findsOneWidget);
    });

    testWidgets('shows four ChartCard widgets for distributions', (
      tester,
    ) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(ChartCard), findsNWidgets(4));
    });
  });
}
