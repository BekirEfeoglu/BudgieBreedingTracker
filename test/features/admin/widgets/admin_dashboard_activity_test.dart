import 'package:flutter/material.dart' hide ErrorSummary;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_dashboard_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_dashboard_activity.dart';

import '../../../helpers/test_localization.dart';

Widget _wrapErrorSummary({
  AsyncValue<ErrorSummary> errorSummary = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [
      recentErrorsSummaryProvider.overrideWithValue(errorSummary),
    ],
    child: const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: DashboardErrorSummaryCard())),
    ),
  );
}

Widget _wrapActivityFeed({
  AsyncValue<List<UserActivity>> activities = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [
      recentUserActivityProvider.overrideWithValue(activities),
    ],
    child: const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: DashboardActivityFeedSection())),
    ),
  );
}

void main() {
  group('DashboardErrorSummaryCard', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrapErrorSummary());
      await tester.pump();
      expect(find.byType(DashboardErrorSummaryCard), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(_wrapErrorSummary());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows no errors message when totalErrors is 0', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapErrorSummary(
          errorSummary: const AsyncData(ErrorSummary(totalErrors: 0)),
        ),
      );
      expect(
        find.textContaining(l10n('admin.no_errors')),
        findsOneWidget,
      );
    });

    testWidgets('shows severity badges when errors exist', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpLocalizedApp(
        tester,
        _wrapErrorSummary(
          errorSummary: const AsyncData(ErrorSummary(
            totalErrors: 5,
            highSeverity: 2,
            mediumSeverity: 2,
            lowSeverity: 1,
          )),
        ),
      );
      expect(find.text('2 ${l10n('admin.severity_high')}'), findsOneWidget);
      expect(find.text('2 ${l10n('admin.severity_medium')}'), findsOneWidget);
      expect(find.text('1 ${l10n('admin.severity_low')}'), findsOneWidget);
    });

    testWidgets('shows error text on async error', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapErrorSummary(
          errorSummary: AsyncError(Exception('fail'), StackTrace.current),
        ),
      );
      expect(
        find.textContaining(l10n('common.data_load_error')),
        findsOneWidget,
      );
    });
  });

  group('DashboardActivityFeedSection', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrapActivityFeed());
      await tester.pump();
      expect(find.byType(DashboardActivityFeedSection), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(_wrapActivityFeed());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows no activity message when empty', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapActivityFeed(activities: const AsyncData([])),
      );
      expect(
        find.textContaining(l10n('admin.no_recent_activity')),
        findsOneWidget,
      );
    });

    testWidgets('shows activity rows when data present', (tester) async {
      final activities = [
        UserActivity(
          userId: 'u1',
          fullName: 'Test User',
          entityType: 'bird',
          count: 5,
          latestAt: DateTime.now(),
        ),
        UserActivity(
          userId: 'u2',
          fullName: 'Another User',
          entityType: 'egg',
          count: 3,
          latestAt: DateTime.now(),
        ),
      ];
      await pumpLocalizedApp(
        tester,
        _wrapActivityFeed(activities: AsyncData(activities)),
      );
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('Another User'), findsOneWidget);
    });

    testWidgets('shows header with title and subtitle', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapActivityFeed(activities: const AsyncData([])),
      );
      expect(
        find.textContaining(l10n('admin.recent_activities')),
        findsOneWidget,
      );
      expect(
        find.textContaining(l10n('admin.last_24_hours')),
        findsOneWidget,
      );
    });
  });
}
