import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/chicks_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/health_records_dao.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_highlights_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/screens/health_tab.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_card.dart';

class _MockChicksDao extends Mock implements ChicksDao {}

class _MockHealthRecordsDao extends Mock implements HealthRecordsDao {}

Widget _createSubject() {
  // HealthTab pulls chicks via `chicksDaoProvider.watchMonthlyHatched` and
  // health-record counts via `healthRecordsDaoProvider
  // .watchCountsByTypeInRange`. Without DAO overrides those StreamProviders
  // stay loading forever and pumpAndSettle times out.
  final chicksDao = _MockChicksDao();
  when(() => chicksDao.watchMonthlyHatched(any()))
      .thenAnswer((_) => Stream.value(<String, int>{}));
  final healthDao = _MockHealthRecordsDao();
  when(
    () => healthDao.watchCountsByTypeInRange(
      userId: any(named: 'userId'),
      from: any(named: 'from'),
      to: any(named: 'to'),
    ),
  ).thenAnswer((_) => Stream.value(<String, int>{}));

  return ProviderScope(
    overrides: [
      chicksDaoProvider.overrideWithValue(chicksDao),
      healthRecordsDaoProvider.overrideWithValue(healthDao),
      chicksStreamProvider('anonymous').overrideWith((_) => Stream.value([])),
      healthRecordsStreamProvider(
        'anonymous',
      ).overrideWith((_) => Stream.value([])),
      healthTrendSummaryProvider(
        'anonymous',
      ).overrideWithValue(const AsyncData(HealthTrendSummary())),
    ],
    child: const MaterialApp(home: Scaffold(body: HealthTab())),
  );
}

void main() {
  setUpAll(() {
    // mocktail needs a DateTime fallback for the `from`/`to` named args.
    registerFallbackValue(DateTime(2024));
  });

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

      expect(
        find.text(l10n('statistics.health_type_distribution')),
        findsOneWidget,
      );
    });
  });
}
