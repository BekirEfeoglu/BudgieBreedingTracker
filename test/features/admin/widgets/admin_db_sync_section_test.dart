import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_database_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_maintenance_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_db_sync_section.dart';

import '../../../helpers/test_localization.dart';

const _healthySummary = SyncStatusSummary(
  pendingCount: 0,
  errorCount: 0,
);

const _issuesSummary = SyncStatusSummary(
  pendingCount: 5,
  errorCount: 3,
);

Widget _wrapWithProvider(
  Widget child, {
  AsyncValue<SyncStatusSummary> summaryData = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [
      syncStatusSummaryProvider.overrideWithValue(summaryData),
    ],
    child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  );
}

void main() {
  group('DatabaseSyncStatusSection', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapWithProvider(
          const DatabaseSyncStatusSection(),
          summaryData: const AsyncData(_healthySummary),
        ),
      );
      expect(find.byType(DatabaseSyncStatusSection), findsOneWidget);
    });

    testWidgets('shows sync_status title', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapWithProvider(
          const DatabaseSyncStatusSection(),
          summaryData: const AsyncData(_healthySummary),
        ),
      );
      expect(find.text(l10n('admin.sync_status')), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapWithProvider(const DatabaseSyncStatusSection()),
        settle: false,
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows no_sync_issues when healthy', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapWithProvider(
          const DatabaseSyncStatusSection(),
          summaryData: const AsyncData(_healthySummary),
        ),
      );
      expect(find.text(l10n('admin.no_sync_issues')), findsOneWidget);
    });

    testWidgets('shows pending and error counts when issues exist', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapWithProvider(
          const DatabaseSyncStatusSection(),
          summaryData: const AsyncData(_issuesSummary),
        ),
      );
      expect(find.text(l10n('admin.pending_sync')), findsOneWidget);
      expect(find.text(l10n('admin.error_sync')), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows reset_stuck button when errors exist', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapWithProvider(
          const DatabaseSyncStatusSection(),
          summaryData: const AsyncData(_issuesSummary),
        ),
      );
      expect(find.text(l10n('admin.reset_stuck')), findsOneWidget);
    });

    testWidgets('does not show reset button when no errors', (tester) async {
      const pendingOnly = SyncStatusSummary(pendingCount: 2, errorCount: 0);
      await pumpLocalizedApp(
        tester,
        _wrapWithProvider(
          const DatabaseSyncStatusSection(),
          summaryData: const AsyncData(pendingOnly),
        ),
      );
      expect(find.text(l10n('admin.reset_stuck')), findsNothing);
    });
  });
}
