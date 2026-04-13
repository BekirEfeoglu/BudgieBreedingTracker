import 'dart:async';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_actions_provider.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_database_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_database_maintenance.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DatabaseSyncStatusSection', () {
    testWidgets('renders loading state', (tester) async {
      final completer = Completer<SyncStatusSummary>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusSummaryProvider.overrideWith(
              (ref) => completer.future,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseSyncStatusSection()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders success message when no sync issues', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusSummaryProvider.overrideWith(
              (ref) async => const SyncStatusSummary(
                pendingCount: 0,
                errorCount: 0,
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseSyncStatusSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('admin.no_sync_issues')), findsOneWidget);
    });

    testWidgets('renders pending count when there are pending items', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusSummaryProvider.overrideWith(
              (ref) async => const SyncStatusSummary(
                pendingCount: 5,
                errorCount: 0,
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseSyncStatusSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
      expect(find.text(l10n('admin.pending_sync')), findsOneWidget);
    });

    testWidgets('renders error count and reset button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusSummaryProvider.overrideWith(
              (ref) async => const SyncStatusSummary(
                pendingCount: 0,
                errorCount: 3,
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseSyncStatusSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      expect(find.text(l10n('admin.error_sync')), findsOneWidget);
      expect(find.text(l10n('admin.reset_stuck')), findsOneWidget);
    });

    testWidgets('renders error state on provider failure', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusSummaryProvider.overrideWith(
              (ref) async => throw Exception('network error'),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseSyncStatusSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('network error'), findsOneWidget);
    });

    testWidgets('renders sync_status section title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusSummaryProvider.overrideWith(
              (ref) async => const SyncStatusSummary(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseSyncStatusSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('admin.sync_status')), findsOneWidget);
    });

    testWidgets('renders Card widget', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusSummaryProvider.overrideWith(
              (ref) async => const SyncStatusSummary(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseSyncStatusSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows both pending and error counts together', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusSummaryProvider.overrideWith(
              (ref) async => const SyncStatusSummary(
                pendingCount: 2,
                errorCount: 7,
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseSyncStatusSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text(l10n('admin.pending_sync')), findsOneWidget);
      expect(find.text(l10n('admin.error_sync')), findsOneWidget);
      expect(find.text(l10n('admin.reset_stuck')), findsOneWidget);
    });

    testWidgets('reset button shows confirmation dialog', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            syncStatusSummaryProvider.overrideWith(
              (ref) async => const SyncStatusSummary(
                pendingCount: 0,
                errorCount: 1,
              ),
            ),
            adminActionsProvider.overrideWith(AdminActionsNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseSyncStatusSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n('admin.reset_stuck')));
      await tester.pumpAndSettle();

      // A confirmation dialog should appear
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('DatabaseSoftDeleteSection', () {
    testWidgets('renders loading state', (tester) async {
      final completer = Completer<List<SoftDeleteStats>>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            softDeleteStatsProvider(30).overrideWith(
              (ref) => completer.future,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseSoftDeleteSection()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders no soft-deleted message when all zero', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            softDeleteStatsProvider(30).overrideWith(
              (ref) async => const [
                SoftDeleteStats(
                  tableName: 'birds',
                  deletedCount: 0,
                  olderThanDaysCount: 0,
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseSoftDeleteSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('admin.no_soft_deleted')), findsOneWidget);
    });

    testWidgets('renders table names and counts when records exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            softDeleteStatsProvider(30).overrideWith(
              (ref) async => const [
                SoftDeleteStats(
                  tableName: 'birds',
                  deletedCount: 5,
                  olderThanDaysCount: 3,
                ),
                SoftDeleteStats(
                  tableName: 'eggs',
                  deletedCount: 2,
                  olderThanDaysCount: 1,
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseSoftDeleteSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('birds'), findsOneWidget);
      expect(find.text('eggs'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('renders cleanup button when old records exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            softDeleteStatsProvider(30).overrideWith(
              (ref) async => const [
                SoftDeleteStats(
                  tableName: 'birds',
                  deletedCount: 1,
                  olderThanDaysCount: 1,
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseSoftDeleteSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('admin.clean_soft_deleted')), findsOneWidget);
    });

    testWidgets('cleanup button shows confirmation dialog', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            softDeleteStatsProvider(30).overrideWith(
              (ref) async => const [
                SoftDeleteStats(
                  tableName: 'birds',
                  deletedCount: 1,
                  olderThanDaysCount: 1,
                ),
              ],
            ),
            adminActionsProvider.overrideWith(AdminActionsNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseSoftDeleteSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n('admin.clean_soft_deleted')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('renders section title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            softDeleteStatsProvider(30).overrideWith(
              (ref) async => const [],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseSoftDeleteSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('admin.soft_delete_cleanup')), findsOneWidget);
    });

    testWidgets('renders error state on provider failure', (tester) async {
      // Use ProviderContainer to verify the override works, then pass via
      // UncontrolledProviderScope so the widget picks it up.
      final container = ProviderContainer(
        overrides: [
          softDeleteStatsProvider(30).overrideWith(
            (ref) async => throw StateError('query failed'),
          ),
        ],
        retry: (_, __) => null,
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: DatabaseSoftDeleteSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Error text renders as bodySmall containing the l10n key
      expect(find.textContaining('common.data_load_error'), findsOneWidget);
    });

    testWidgets('renders Card widget', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            softDeleteStatsProvider(30).overrideWith(
              (ref) async => const [],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseSoftDeleteSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('DatabaseStorageSection', () {
    testWidgets('renders loading state', (tester) async {
      final completer = Completer<List<BucketUsage>>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageUsageProvider.overrideWith(
              (ref) => completer.future,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseStorageSection()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders bucket names and file counts', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageUsageProvider.overrideWith(
              (ref) async => const [
                BucketUsage(
                  bucketName: 'bird-photos',
                  fileCount: 42,
                  totalSizeBytes: 1048576,
                ),
                BucketUsage(
                  bucketName: 'avatars',
                  fileCount: 10,
                  totalSizeBytes: 512,
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseStorageSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('bird-photos'), findsOneWidget);
      expect(find.text('avatars'), findsOneWidget);
      expect(find.textContaining('42'), findsOneWidget);
      expect(find.textContaining('10'), findsOneWidget);
    });

    testWidgets('renders section title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageUsageProvider.overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseStorageSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('admin.storage_usage')), findsOneWidget);
    });

    testWidgets('renders error state on provider failure', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageUsageProvider.overrideWith(
              (ref) async => throw Exception('storage error'),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseStorageSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('storage error'), findsOneWidget);
    });

    testWidgets('renders Card widget', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageUsageProvider.overrideWith((ref) async => const []),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseStorageSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('formats size in MB', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageUsageProvider.overrideWith(
              (ref) async => const [
                BucketUsage(
                  bucketName: 'photos',
                  fileCount: 1,
                  totalSizeBytes: 2 * 1024 * 1024,
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseStorageSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2.0 MB'), findsOneWidget);
    });

    testWidgets('formats size in KB', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageUsageProvider.overrideWith(
              (ref) async => const [
                BucketUsage(
                  bucketName: 'small',
                  fileCount: 1,
                  totalSizeBytes: 2048,
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseStorageSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2.0 KB'), findsOneWidget);
    });

    testWidgets('formats size in bytes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageUsageProvider.overrideWith(
              (ref) async => const [
                BucketUsage(
                  bucketName: 'tiny',
                  fileCount: 1,
                  totalSizeBytes: 500,
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseStorageSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('500 B'), findsOneWidget);
    });

    testWidgets('formats size in GB', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageUsageProvider.overrideWith(
              (ref) async => const [
                BucketUsage(
                  bucketName: 'large',
                  fileCount: 1,
                  totalSizeBytes: 3 * 1024 * 1024 * 1024,
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: DatabaseStorageSection()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3.0 GB'), findsOneWidget);
    });
  });
}
