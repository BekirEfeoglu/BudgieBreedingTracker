import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_database_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_db_storage_section.dart';

Widget _wrap(
  Widget child, {
  AsyncValue<List<BucketUsage>> storageUsage = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [
      storageUsageProvider.overrideWithValue(storageUsage),
    ],
    child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  );
}

void main() {
  group('DatabaseStorageSection', () {
    testWidgets('should_show_loading_when_data_is_loading', (tester) async {
      await tester.pumpWidget(
        _wrap(const DatabaseStorageSection()),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should_show_section_title', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DatabaseStorageSection(),
          storageUsage: const AsyncData([]),
        ),
      );
      await tester.pump();
      expect(find.text(l10n('admin.storage_usage')), findsOneWidget);
    });

    testWidgets('should_show_bucket_name_and_file_count', (tester) async {
      const usage = [
        BucketUsage(bucketName: 'photos', fileCount: 42, totalSizeBytes: 1024),
      ];
      await tester.pumpWidget(
        _wrap(
          const DatabaseStorageSection(),
          storageUsage: const AsyncData(usage),
        ),
      );
      await tester.pump();
      expect(find.text('photos'), findsOneWidget);
      expect(
        find.text('42 ${l10n('admin.file_count')}'),
        findsOneWidget,
      );
    });

    testWidgets('should_format_size_in_KB', (tester) async {
      const usage = [
        BucketUsage(
          bucketName: 'avatars',
          fileCount: 10,
          totalSizeBytes: 2048,
        ),
      ];
      await tester.pumpWidget(
        _wrap(
          const DatabaseStorageSection(),
          storageUsage: const AsyncData(usage),
        ),
      );
      await tester.pump();
      expect(find.text('2.0 KB'), findsOneWidget);
    });

    testWidgets('should_format_size_in_MB', (tester) async {
      const usage = [
        BucketUsage(
          bucketName: 'media',
          fileCount: 5,
          totalSizeBytes: 5 * 1024 * 1024,
        ),
      ];
      await tester.pumpWidget(
        _wrap(
          const DatabaseStorageSection(),
          storageUsage: const AsyncData(usage),
        ),
      );
      await tester.pump();
      expect(find.text('5.0 MB'), findsOneWidget);
    });

    testWidgets('should_format_size_in_GB', (tester) async {
      const usage = [
        BucketUsage(
          bucketName: 'backups',
          fileCount: 2,
          totalSizeBytes: 2 * 1024 * 1024 * 1024,
        ),
      ];
      await tester.pumpWidget(
        _wrap(
          const DatabaseStorageSection(),
          storageUsage: const AsyncData(usage),
        ),
      );
      await tester.pump();
      expect(find.text('2.0 GB'), findsOneWidget);
    });

    testWidgets('should_show_error_when_provider_errors', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DatabaseStorageSection(),
          storageUsage: AsyncError(Exception('fail'), StackTrace.current),
        ),
      );
      await tester.pump();
      expect(
        find.textContaining(l10n('common.data_load_error')),
        findsOneWidget,
      );
    });
  });
}
