import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_database_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_maintenance_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_db_soft_delete_section.dart';

import '../../../helpers/test_localization.dart';

const _sampleStats = [
  SoftDeleteStats(tableName: 'birds', deletedCount: 5, olderThanDaysCount: 3),
  SoftDeleteStats(tableName: 'eggs', deletedCount: 2, olderThanDaysCount: 0),
];

const _emptyStats = [
  SoftDeleteStats(tableName: 'birds', deletedCount: 0, olderThanDaysCount: 0),
];

Widget _wrapWithProvider(
  Widget child, {
  AsyncValue<List<SoftDeleteStats>> statsData = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [
      softDeleteStatsProvider(30).overrideWithValue(statsData),
      softDeleteStatsProvider(60).overrideWithValue(statsData),
      softDeleteStatsProvider(90).overrideWithValue(statsData),
    ],
    child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  );
}

void main() {
  group('DatabaseSoftDeleteSection', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapWithProvider(
          const DatabaseSoftDeleteSection(),
          statsData: const AsyncData([]),
        ),
      );
      expect(find.byType(DatabaseSoftDeleteSection), findsOneWidget);
    });

    testWidgets('shows soft_delete_cleanup title', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapWithProvider(
          const DatabaseSoftDeleteSection(),
          statsData: const AsyncData([]),
        ),
      );
      expect(find.text(l10n('admin.soft_delete_cleanup')), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapWithProvider(const DatabaseSoftDeleteSection()),
        settle: false,
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows no_soft_deleted when all counts are zero', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapWithProvider(
          const DatabaseSoftDeleteSection(),
          statsData: const AsyncData(_emptyStats),
        ),
      );
      expect(find.text(l10n('admin.no_soft_deleted')), findsOneWidget);
    });

    testWidgets('shows table rows when soft-deleted records exist', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapWithProvider(
          const DatabaseSoftDeleteSection(),
          statsData: const AsyncData(_sampleStats),
        ),
      );
      expect(find.text('birds'), findsOneWidget);
      expect(find.text('eggs'), findsOneWidget);
    });

    testWidgets('shows clean button when old records exist', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapWithProvider(
          const DatabaseSoftDeleteSection(),
          statsData: const AsyncData(_sampleStats),
        ),
      );
      expect(find.text(l10n('admin.clean_soft_deleted')), findsOneWidget);
    });

    testWidgets('shows dropdown for day selection', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapWithProvider(
          const DatabaseSoftDeleteSection(),
          statsData: const AsyncData([]),
        ),
      );
      expect(find.byType(DropdownButton<int>), findsOneWidget);
    });
  });
}
