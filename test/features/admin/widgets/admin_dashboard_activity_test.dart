import 'package:flutter/material.dart' hide ErrorSummary;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/enums/admin_enums.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_dashboard_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_dashboard_activity.dart';

Widget _wrap(
  Widget child, {
  AsyncValue<ErrorSummary> errorSummary = const AsyncLoading(),
  AsyncValue<List<UserActivity>> userActivity = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [
      recentErrorsSummaryProvider.overrideWithValue(errorSummary),
      recentUserActivityProvider.overrideWithValue(userActivity),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1200,
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );
}

/// Suppresses RenderFlex overflow errors caused by long l10n keys in tests.
void _suppressOverflowErrors() {
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final isOverflow = details.exceptionAsString().contains('overflowed');
    if (!isOverflow) {
      originalOnError?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = originalOnError);
}

void main() {
  group('DashboardErrorSummaryCard', () {
    testWidgets('should_show_loading_when_data_is_loading', (tester) async {
      await tester.pumpWidget(
        _wrap(const DashboardErrorSummaryCard()),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should_show_no_errors_message_when_totalErrors_is_zero',
        (tester) async {
      const summary = ErrorSummary(totalErrors: 0);
      await tester.pumpWidget(
        _wrap(
          const DashboardErrorSummaryCard(),
          errorSummary: const AsyncData(summary),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('admin.no_errors')), findsOneWidget);
    });

    testWidgets('should_show_severity_badges_when_errors_exist',
        (tester) async {
      _suppressOverflowErrors();
      const summary = ErrorSummary(
        totalErrors: 5,
        highSeverity: 2,
        mediumSeverity: 2,
        lowSeverity: 1,
      );
      await tester.pumpWidget(
        _wrap(
          const DashboardErrorSummaryCard(),
          errorSummary: const AsyncData(summary),
        ),
      );
      await tester.pump();
      expect(
        find.text('2 ${l10n('admin.severity_high')}'),
        findsOneWidget,
      );
      expect(
        find.text('2 ${l10n('admin.severity_medium')}'),
        findsOneWidget,
      );
      expect(
        find.text('1 ${l10n('admin.severity_low')}'),
        findsOneWidget,
      );
    });

    testWidgets('should_show_error_text_when_provider_errors',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DashboardErrorSummaryCard(),
          errorSummary: AsyncError(Exception('fail'), StackTrace.current),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('common.data_load_error')), findsOneWidget);
    });

    testWidgets('should_show_recent_event_rows_when_events_exist',
        (tester) async {
      _suppressOverflowErrors();
      final event = SecurityEvent(
        id: 'e1',
        eventType: SecurityEventType.failedLogin,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      final summary = ErrorSummary(
        totalErrors: 1,
        highSeverity: 1,
        recentEvents: [event],
      );
      await tester.pumpWidget(
        _wrap(
          const DashboardErrorSummaryCard(),
          errorSummary: AsyncData(summary),
        ),
      );
      await tester.pump();
      // Event type name is displayed
      expect(find.text('failedLogin'), findsOneWidget);
    });
  });

  group('DashboardActivityFeedSection', () {
    testWidgets('should_show_loading_when_activity_is_loading',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const DashboardActivityFeedSection()),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should_show_no_recent_activity_when_empty', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DashboardActivityFeedSection(),
          userActivity: const AsyncData([]),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('admin.no_recent_activity')), findsOneWidget);
    });

    testWidgets('should_show_activity_rows_when_data_exists', (tester) async {
      final activities = [
        UserActivity(
          userId: 'u1',
          fullName: 'Alice Test',
          entityType: 'bird',
          count: 3,
          latestAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];
      await tester.pumpWidget(
        _wrap(
          const DashboardActivityFeedSection(),
          userActivity: AsyncData(activities),
        ),
      );
      await tester.pump();
      expect(find.text('Alice Test'), findsOneWidget);
    });

    testWidgets('should_show_user_id_prefix_when_fullName_is_empty',
        (tester) async {
      final activities = [
        UserActivity(
          userId: 'abcdefgh-1234',
          fullName: '',
          entityType: 'egg',
          count: 1,
          latestAt: DateTime.now(),
        ),
      ];
      await tester.pumpWidget(
        _wrap(
          const DashboardActivityFeedSection(),
          userActivity: AsyncData(activities),
        ),
      );
      await tester.pump();
      expect(find.text('abcdefgh'), findsOneWidget);
    });

    testWidgets('should_show_section_title', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DashboardActivityFeedSection(),
          userActivity: const AsyncData([]),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('admin.recent_activities')), findsOneWidget);
    });
  });
}
