import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_database_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_maintenance_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_db_storage_section.dart';

import '../../../helpers/test_localization.dart';

const _sampleUsages = [
  BucketUsage(bucketName: 'bird-photos', fileCount: 120, totalSizeBytes: 52428800),
  BucketUsage(bucketName: 'avatars', fileCount: 10, totalSizeBytes: 1048576),
];

Widget _wrapWithProvider(
  Widget child, {
  AsyncValue<List<BucketUsage>> usageData = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [
      storageUsageProvider.overrideWithValue(usageData),
    ],
    child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  );
}

void main() {
  group('DatabaseStorageSection', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapWithProvider(
          const DatabaseStorageSection(),
          usageData: const AsyncData([]),
        ),
      );
      expect(find.byType(DatabaseStorageSection), findsOneWidget);
    });

    testWidgets('shows storage_usage title', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapWithProvider(
          const DatabaseStorageSection(),
          usageData: const AsyncData([]),
        ),
      );
      expect(find.text(l10n('admin.storage_usage')), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapWithProvider(const DatabaseStorageSection()),
        settle: false,
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error text on error', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapWithProvider(
          const DatabaseStorageSection(),
          usageData: AsyncError(Exception('fail'), StackTrace.current),
        ),
      );
      expect(find.text(l10n('common.data_load_error')), findsNothing);
      // Error message includes the prefix and exception
      expect(find.textContaining('fail'), findsOneWidget);
    });

    testWidgets('shows bucket names when data loaded', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapWithProvider(
          const DatabaseStorageSection(),
          usageData: const AsyncData(_sampleUsages),
        ),
      );
      expect(find.text('bird-photos'), findsOneWidget);
      expect(find.text('avatars'), findsOneWidget);
    });

    testWidgets('shows file count for each bucket', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapWithProvider(
          const DatabaseStorageSection(),
          usageData: const AsyncData(_sampleUsages),
        ),
      );
      // file count format: "120 admin.file_count"
      expect(find.textContaining('120'), findsOneWidget);
      expect(find.textContaining('10'), findsOneWidget);
    });

    testWidgets('formats size in MB for large buckets', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrapWithProvider(
          const DatabaseStorageSection(),
          usageData: const AsyncData(_sampleUsages),
        ),
      );
      // 52428800 bytes = 50.0 MB
      expect(find.text('50.0 MB'), findsOneWidget);
      // 1048576 bytes = 1.0 MB
      expect(find.text('1.0 MB'), findsOneWidget);
    });
  });
}
