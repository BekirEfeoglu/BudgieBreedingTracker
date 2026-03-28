import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/sync/sync_conflict_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/data_storage_dialogs.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';

void main() {
  group('formatBytes', () {
    test('formats bytes below 1 KB', () {
      expect(formatBytes(500), '500 B');
    });

    test('formats bytes in KB range', () {
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(1536), '1.5 KB');
    });

    test('formats bytes in MB range', () {
      expect(formatBytes(1024 * 1024), '1.0 MB');
      expect(formatBytes(1024 * 1024 * 5 + 1024 * 512), '5.5 MB');
    });

    test('handles zero bytes', () {
      expect(formatBytes(0), '0 B');
    });
  });

  group('formatTimeSince', () {
    test('returns just now for less than 1 minute', () {
      final result = formatTimeSince(DateTime.now());
      expect(result, 'settings.just_now');
    });

    test('returns minutes ago for less than 1 hour', () {
      final time = DateTime.now().subtract(const Duration(minutes: 30));
      final result = formatTimeSince(time);
      expect(result, contains('settings.minutes_ago'));
    });

    test('returns hours ago for less than 24 hours', () {
      final time = DateTime.now().subtract(const Duration(hours: 5));
      final result = formatTimeSince(time);
      expect(result, contains('settings.hours_ago'));
    });

    test('returns days ago for 24+ hours', () {
      final time = DateTime.now().subtract(const Duration(days: 3));
      final result = formatTimeSince(time);
      expect(result, contains('settings.days_ago'));
    });
  });

  group('StorageInfoRow', () {
    testWidgets('renders label and value', (tester) async {
      final theme = ThemeData.light();

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: StorageInfoRow(
              label: 'Database',
              value: '2.5 MB',
              icon: const Icon(Icons.storage),
              theme: theme,
            ),
          ),
        ),
      );

      expect(find.text('Database'), findsOneWidget);
      expect(find.text('2.5 MB'), findsOneWidget);
    });

    testWidgets('shows calculating text when value is null', (tester) async {
      final theme = ThemeData.light();

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: StorageInfoRow(
              label: 'Cache',
              icon: const Icon(Icons.storage),
              theme: theme,
            ),
          ),
        ),
      );

      expect(find.text('Cache'), findsOneWidget);
      expect(find.text('settings.storage_calculating'), findsOneWidget);
    });

    testWidgets('renders icon widget', (tester) async {
      final theme = ThemeData.light();

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: StorageInfoRow(
              label: 'Images',
              value: '10.0 MB',
              icon: const Icon(Icons.image, key: Key('test-icon')),
              theme: theme,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('test-icon')), findsOneWidget);
    });
  });

  group('showStorageInfoDialog', () {
    testWidgets('displays storage info dialog with three rows', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cacheSizeProvider.overrideWith((ref) async => 2048),
            databaseSizeProvider.overrideWith((ref) async => 1024 * 1024),
            imageStorageSizeProvider.overrideWith((ref) async => 5 * 1024),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showStorageInfoDialog(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Dialog title
      expect(find.text('settings.storage_info'), findsOneWidget);
      // Three StorageInfoRow widgets
      expect(find.byType(StorageInfoRow), findsNWidgets(3));
      // Close button
      expect(find.text('common.close'), findsOneWidget);
    });

    testWidgets('close button dismisses dialog', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cacheSizeProvider.overrideWith((ref) async => 0),
            databaseSizeProvider.overrideWith((ref) async => 0),
            imageStorageSizeProvider.overrideWith((ref) async => 0),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showStorageInfoDialog(context),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('common.close'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('showConflictHistoryDialog', () {
    testWidgets('shows empty conflicts message', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            conflictHistoryProvider.overrideWith(
              () => _TestConflictHistoryNotifier([]),
            ),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                return ElevatedButton(
                  onPressed: () {
                    showConflictHistoryDialog(context, ref, []);
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('sync.conflict_history'), findsOneWidget);
      expect(find.text('sync.no_conflicts'), findsOneWidget);
    });

    testWidgets('shows conflict entries', (tester) async {
      final conflicts = [
        SyncConflict(
          table: 'birds',
          recordId: 'id-1',
          detectedAt: DateTime.now().subtract(const Duration(minutes: 5)),
          description: 'Conflict on bird record',
        ),
        SyncConflict(
          table: 'eggs',
          recordId: 'id-2',
          detectedAt: DateTime.now().subtract(const Duration(hours: 2)),
          description: 'Conflict on egg record',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            conflictHistoryProvider.overrideWith(
              () => _TestConflictHistoryNotifier(conflicts),
            ),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                return ElevatedButton(
                  onPressed: () {
                    showConflictHistoryDialog(context, ref, conflicts);
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Conflict on bird record'), findsOneWidget);
      expect(find.text('Conflict on egg record'), findsOneWidget);
    });

    testWidgets('delete button clears conflicts and closes dialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            conflictHistoryProvider.overrideWith(
              () => _TestConflictHistoryNotifier([]),
            ),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                return ElevatedButton(
                  onPressed: () {
                    showConflictHistoryDialog(context, ref, []);
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('common.delete'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('close button dismisses conflict dialog', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            conflictHistoryProvider.overrideWith(
              () => _TestConflictHistoryNotifier([]),
            ),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                return ElevatedButton(
                  onPressed: () {
                    showConflictHistoryDialog(context, ref, []);
                  },
                  child: const Text('Open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('common.close'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}

/// Test-only ConflictHistoryNotifier that returns given list.
class _TestConflictHistoryNotifier extends ConflictHistoryNotifier {
  final List<SyncConflict> _initial;
  _TestConflictHistoryNotifier(this._initial);

  @override
  List<SyncConflict> build() => _initial;

  @override
  void clear() {
    state = [];
  }
}
