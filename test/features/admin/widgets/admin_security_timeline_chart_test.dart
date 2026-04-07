import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_filter_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_security_timeline_chart.dart';
import 'package:budgie_breeding_tracker/features/statistics/widgets/chart_states.dart';

import '../../../helpers/test_localization.dart';

void main() {
  group('AdminSecurityTimelineChart', () {
    testWidgets('shows loading state', (tester) async {
      final completer = Completer<List<DailyDataPoint>>();
      addTearDown(() {
        if (!completer.isCompleted) completer.complete([]);
      });

      await pumpLocalizedApp(
        tester,
        ProviderScope(
          overrides: [
            securityEventTrendProvider.overrideWith(
              (_) => completer.future,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AdminSecurityTimelineChart()),
          ),
        ),
        settle: false,
      );

      await tester.pump(); // Single frame — keeps loading state visible
      expect(find.byType(ChartLoading), findsOneWidget);
    });

    testWidgets('shows chart when data provided', (tester) async {
      final data = [
        DailyDataPoint(date: DateTime(2025, 1, 1), count: 3),
        DailyDataPoint(date: DateTime(2025, 1, 2), count: 5),
        DailyDataPoint(date: DateTime(2025, 1, 3), count: 2),
      ];

      await pumpLocalizedApp(
        tester,
        ProviderScope(
          overrides: [
            securityEventTrendProvider.overrideWith((_) async => data),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AdminSecurityTimelineChart()),
          ),
        ),
      );

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('shows nothing (ChartEmpty) when data is empty', (tester) async {
      await pumpLocalizedApp(
        tester,
        ProviderScope(
          overrides: [
            securityEventTrendProvider.overrideWith((_) async => <DailyDataPoint>[]),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AdminSecurityTimelineChart()),
          ),
        ),
      );

      expect(find.byType(ChartEmpty), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);
    });

    testWidgets('shows ChartError with retry on error', (tester) async {
      await pumpLocalizedApp(
        tester,
        ProviderScope(
          overrides: [
            securityEventTrendProvider.overrideWith(
              (_) => Future.error(Exception('network error')),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: AdminSecurityTimelineChart()),
          ),
        ),
      );

      expect(find.byType(ChartError), findsOneWidget);
    });
  });
}
