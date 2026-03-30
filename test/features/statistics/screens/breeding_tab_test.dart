import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/screens/breeding_tab.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';

Widget _createSubject() {
  return ProviderScope(
    overrides: [
      // BreedingTab uses: monthlyBreedingOutcomesProvider (breedingPairs + eggs),
      // monthlyEggProductionProvider (eggs), monthlyFertilityRateProvider (eggs),
      // incubationDurationProvider (incubations stream).
      breedingPairsStreamProvider(
        'anonymous',
      ).overrideWith((_) => Stream.value([])),
      eggsStreamProvider('anonymous').overrideWith((_) => Stream.value([])),
      incubationsStreamProvider(
        'anonymous',
      ).overrideWith((_) => Stream.value([])),
    ],
    child: const MaterialApp(home: Scaffold(body: BreedingTab())),
  );
}

void main() {
  group('BreedingTab', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(BreedingTab), findsOneWidget);
    });

    testWidgets('shows RefreshIndicator', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('shows four ChartCard widgets', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(ChartCard), findsNWidgets(4));
    });

    testWidgets('shows species filter selector', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('statistics.filter_species')), findsOneWidget);
    });

    testWidgets('shows breeding success section', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('statistics.breeding_success')), findsOneWidget);
    });

    testWidgets('shows egg production section', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('statistics.egg_production')), findsOneWidget);
    });

    testWidgets('shows fertility trend section', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('statistics.fertility_trend')), findsOneWidget);
    });

    testWidgets('shows incubation duration section', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('statistics.incubation_duration')), findsOneWidget);
    });
  });
}
