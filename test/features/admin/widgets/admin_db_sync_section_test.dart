import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_database_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_db_sync_section.dart';

Widget _wrap(
  Widget child, {
  AsyncValue<SyncStatusSummary> syncStatus = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [
      syncStatusSummaryProvider.overrideWithValue(syncStatus),
    ],
    child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  );
}

void main() {
  group('DatabaseSyncStatusSection', () {
    testWidgets('should_show_loading_when_data_is_loading', (tester) async {
      await tester.pumpWidget(
        _wrap(const DatabaseSyncStatusSection()),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should_show_section_title', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DatabaseSyncStatusSection(),
          syncStatus: const AsyncData(SyncStatusSummary()),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('admin.sync_status')), findsOneWidget);
    });

    testWidgets('should_show_no_issues_when_all_counts_are_zero',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DatabaseSyncStatusSection(),
          syncStatus: const AsyncData(SyncStatusSummary()),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('admin.no_sync_issues')), findsOneWidget);
    });

    testWidgets('should_show_pending_count_when_pending_exists',
        (tester) async {
      const summary = SyncStatusSummary(pendingCount: 5);
      await tester.pumpWidget(
        _wrap(
          const DatabaseSyncStatusSection(),
          syncStatus: const AsyncData(summary),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('admin.pending_sync')), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('should_show_error_count_and_reset_button_when_errors_exist',
        (tester) async {
      const summary = SyncStatusSummary(errorCount: 3);
      await tester.pumpWidget(
        _wrap(
          const DatabaseSyncStatusSection(),
          syncStatus: const AsyncData(summary),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('admin.error_sync')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text(l10n('admin.reset_stuck')), findsOneWidget);
    });

    testWidgets('should_show_error_text_when_provider_errors',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DatabaseSyncStatusSection(),
          syncStatus: AsyncError(Exception('fail'), StackTrace.current),
        ),
      );
      await tester.pump();
      expect(
        find.textContaining(l10n('common.data_load_error')),
        findsOneWidget,
      );
    });

    testWidgets(
        'should_not_show_reset_button_when_only_pending_and_no_errors',
        (tester) async {
      const summary = SyncStatusSummary(pendingCount: 10, errorCount: 0);
      await tester.pumpWidget(
        _wrap(
          const DatabaseSyncStatusSection(),
          syncStatus: const AsyncData(summary),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('admin.reset_stuck')), findsNothing);
    });
  });
}
