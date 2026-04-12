import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/screens/health_tab.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';

Widget _createSubject() {
  return ProviderScope(
    overrides: [
      // HealthTab uses: monthlyHatchedChicksProvider (chicks),
      // chickSurvivalProvider (chicks), healthRecordTypeDistributionProvider
      // (health records stream + statsPeriodProvider).
      chicksStreamProvider('anonymous').overrideWith((_) => Stream.value([])),
      healthRecordsStreamProvider(
        'anonymous',
      ).overrideWith((_) => Stream.value([])),
    ],
    child: const MaterialApp(home: Scaffold(body: HealthTab())),
  );
}

void main() {
  group('HealthTab', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(HealthTab), findsOneWidget);
    });

    testWidgets('shows RefreshIndicator', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('shows three ChartCard widgets', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(ChartCard), findsNWidgets(3));
    });

    testWidgets('shows monthly trend section', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('statistics.monthly_trend')), findsOneWidget);
    });

    testWidgets('shows chick survival section', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('statistics.chick_survival')), findsOneWidget);
    });

    testWidgets('shows health record type distribution section', (
      tester,
    ) async {
      await tester.pumpWidget(_createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('statistics.health_type_distribution')), findsOneWidget);
    });
  });
}
