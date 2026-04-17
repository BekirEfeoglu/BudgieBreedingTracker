import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_database_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_db_soft_delete_section.dart';

Widget _wrap(
  Widget child, {
  AsyncValue<List<SoftDeleteStats>> softDeleteStats = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [
      softDeleteStatsProvider(30).overrideWithValue(softDeleteStats),
    ],
    child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  );
}

void main() {
  group('DatabaseSoftDeleteSection', () {
    testWidgets('should_show_loading_when_data_is_loading', (tester) async {
      await tester.pumpWidget(
        _wrap(const DatabaseSoftDeleteSection()),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should_show_section_title', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DatabaseSoftDeleteSection(),
          softDeleteStats: const AsyncData([]),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('admin.soft_delete_cleanup')), findsOneWidget);
    });

    testWidgets('should_show_no_soft_deleted_when_all_zero', (tester) async {
      const stats = [
        SoftDeleteStats(tableName: 'birds', deletedCount: 0, olderThanDaysCount: 0),
      ];
      await tester.pumpWidget(
        _wrap(
          const DatabaseSoftDeleteSection(),
          softDeleteStats: const AsyncData(stats),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('admin.no_soft_deleted')), findsOneWidget);
    });

    testWidgets('should_show_table_names_when_deleted_records_exist',
        (tester) async {
      const stats = [
        SoftDeleteStats(tableName: 'birds', deletedCount: 5, olderThanDaysCount: 3),
        SoftDeleteStats(tableName: 'eggs', deletedCount: 2, olderThanDaysCount: 1),
      ];
      await tester.pumpWidget(
        _wrap(
          const DatabaseSoftDeleteSection(),
          softDeleteStats: const AsyncData(stats),
        ),
      );
      await tester.pump();
      expect(find.text('birds'), findsOneWidget);
      expect(find.text('eggs'), findsOneWidget);
    });

    testWidgets('should_show_cleanup_button_when_old_records_exist',
        (tester) async {
      const stats = [
        SoftDeleteStats(tableName: 'birds', deletedCount: 10, olderThanDaysCount: 5),
      ];
      await tester.pumpWidget(
        _wrap(
          const DatabaseSoftDeleteSection(),
          softDeleteStats: const AsyncData(stats),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('admin.clean_soft_deleted')), findsOneWidget);
    });

    testWidgets('should_show_dropdown_with_day_options', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DatabaseSoftDeleteSection(),
          softDeleteStats: const AsyncData([]),
        ),
      );
      await tester.pump();
      // Default 30 days should be visible in dropdown
      expect(
        find.text('30 ${l10n('admin.days_label')}'),
        findsOneWidget,
      );
    });

    testWidgets('should_show_error_when_provider_errors', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DatabaseSoftDeleteSection(),
          softDeleteStats: AsyncError(Exception('fail'), StackTrace.current),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('common.data_load_error')), findsOneWidget);
    });
  });
}
