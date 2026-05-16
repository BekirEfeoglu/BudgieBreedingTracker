import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_orchestrator.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/action_feedback_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/data_storage_section.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import '../../../helpers/mocks.dart';

/// A simple AutoSyncNotifier that doesn't touch SharedPreferences.
class _TestAutoSyncNotifier extends AutoSyncNotifier {
  final bool _initial;
  _TestAutoSyncNotifier(this._initial);

  @override
  bool build() => _initial;

  @override
  Future<void> toggle() async {
    state = !state;
  }
}

/// A simple WifiOnlySyncNotifier for testing.
class _TestWifiOnlySyncNotifier extends WifiOnlySyncNotifier {
  final bool _initial;
  _TestWifiOnlySyncNotifier(this._initial);

  @override
  bool build() => _initial;

  @override
  Future<void> toggle() async {
    state = !state;
  }
}

/// A simple LastSyncTimeNotifier for testing.
class _TestLastSyncTimeNotifier extends LastSyncTimeNotifier {
  final DateTime? _initial;
  _TestLastSyncTimeNotifier(this._initial);

  @override
  DateTime? build() => _initial;
}

class _TestBackgroundSyncNotifier extends SyncBackgroundEnabledNotifier {
  final bool _initial;
  _TestBackgroundSyncNotifier(this._initial);

  @override
  bool build() => _initial;

  @override
  Future<void> setEnabled(bool enabled) async {
    state = enabled;
  }
}

class _TestRealtimeSyncNotifier extends SyncRealtimeEnabledNotifier {
  final bool _initial;
  _TestRealtimeSyncNotifier(this._initial);

  @override
  bool build() => _initial;

  @override
  Future<void> setEnabled(bool enabled) async {
    state = enabled;
  }
}

class _TestConflictHistoryNotifier extends ConflictHistoryNotifier {
  final List<SyncConflict> _initial;
  _TestConflictHistoryNotifier(this._initial);

  @override
  List<SyncConflict> build() => _initial;
}

void main() {
  late MockSyncOrchestrator mockOrchestrator;
  late GoRouter router;

  setUp(() {
    mockOrchestrator = MockSyncOrchestrator();
    router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (_, __) => const Scaffold(
            body: SingleChildScrollView(child: DataStorageSection()),
          ),
        ),
        GoRoute(
          path: '/backup',
          builder: (_, __) => const Scaffold(body: Text('Backup')),
        ),
      ],
    );
  });

  Widget createSubject({
    DateTime? lastSyncTime,
    bool autoSync = true,
    bool wifiOnlySync = false,
    bool backgroundSync = false,
    bool realtimeSync = false,
    int pendingCount = 0,
    int errorCount = 0,
    int staleWarningCount = 0,
    int conflictCount = 0,
    int cacheSize = 1024,
  }) {
    final conflicts = List<SyncConflict>.generate(
      conflictCount,
      (index) => SyncConflict(
        table: 'birds',
        recordId: 'bird-$index',
        detectedAt: DateTime.now(),
        description: 'Conflict $index',
      ),
    );

    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        syncOrchestratorProvider.overrideWithValue(mockOrchestrator),
        autoSyncProvider.overrideWith(() => _TestAutoSyncNotifier(autoSync)),
        wifiOnlySyncProvider.overrideWith(
          () => _TestWifiOnlySyncNotifier(wifiOnlySync),
        ),
        syncBackgroundEnabledProvider.overrideWith(
          () => _TestBackgroundSyncNotifier(backgroundSync),
        ),
        syncRealtimeEnabledProvider.overrideWith(
          () => _TestRealtimeSyncNotifier(realtimeSync),
        ),
        pendingSyncCountProvider.overrideWith(
          (ref) => Stream.value(pendingCount),
        ),
        syncErrorDetailsProvider.overrideWith(
          (ref, userId) => Stream.value([
            if (errorCount > 0)
              SyncErrorDetail(tableName: 'birds', errorCount: errorCount),
          ]),
        ),
        pendingDeletionSyncErrorsProvider.overrideWith(
          (ref) async => List<SyncMetadata>.generate(
            staleWarningCount,
            (index) => SyncMetadata(
              id: 'stale-$index',
              table: 'birds',
              userId: 'user-1',
              status: SyncStatus.error,
            ),
          ),
        ),
        conflictHistoryProvider.overrideWith(
          () => _TestConflictHistoryNotifier(conflicts),
        ),
        cacheSizeProvider.overrideWith((ref) => Future.value(cacheSize)),
        lastSyncTimeProvider.overrideWith(
          () => _TestLastSyncTimeNotifier(lastSyncTime),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  /// Finds the sync action tile by its stable Key (immune to tile reordering).
  Finder findSyncTile() => find.byKey(DataStorageSection.syncActionKey);

  group('DataStorageSection', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump(); // Let FutureProvider resolve

      expect(find.byType(DataStorageSection), findsOneWidget);
      expect(find.byType(ListTile), findsAtLeast(4));
    });

    testWidgets('shows loading indicator during sync', (tester) async {
      final completer = Completer<SyncResult>();
      when(
        () => mockOrchestrator.forceFullSync(),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(createSubject());
      await tester.pump();

      // Before tap: no loading indicator in the section
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Tap sync tile
      await tester.tap(findSyncTile());
      await tester.pump();

      // Should now show loading indicator
      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));

      // Complete the future
      completer.complete(SyncResult.success);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('shows success SnackBar on sync success', (tester) async {
      ActionFeedbackService.resetForTesting();
      final received = <ActionFeedback>[];
      final sub = ActionFeedbackService.stream.listen(received.add);
      addTearDown(sub.cancel);

      when(
        () => mockOrchestrator.forceFullSync(),
      ).thenAnswer((_) async => SyncResult.success);

      await tester.pumpWidget(createSubject());
      await tester.pump();

      // Tap sync button
      await tester.tap(findSyncTile());
      await tester.pump(); // trigger setState
      await tester.pump(); // let future resolve
      await tester.pump(const Duration(milliseconds: 100));

      // Success goes through ActionFeedbackService, not SnackBar
      expect(received, hasLength(1));
      expect(received.first.type, ActionFeedbackType.success);
    });

    testWidgets('shows error SnackBar on sync error', (tester) async {
      when(
        () => mockOrchestrator.forceFullSync(),
      ).thenAnswer((_) async => SyncResult.error);

      await tester.pumpWidget(createSubject());
      await tester.pump();

      // Tap sync button
      await tester.tap(findSyncTile());
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should show SnackBar
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('renders with last sync time', (tester) async {
      final syncTime = DateTime.now().subtract(const Duration(minutes: 5));

      await tester.pumpWidget(createSubject(lastSyncTime: syncTime));
      await tester.pump();

      // Widget renders without errors with a last sync time set
      expect(find.byType(DataStorageSection), findsOneWidget);
    });

    testWidgets('renders without last sync time', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(DataStorageSection), findsOneWidget);
    });

    testWidgets('shows sync health report summary with key signals', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(
          backgroundSync: true,
          realtimeSync: false,
          pendingCount: 4,
          errorCount: 2,
          staleWarningCount: 1,
          conflictCount: 3,
        ),
      );
      await tester.pump();

      expect(find.text(l10n('settings.sync_health_report')), findsOneWidget);
      expect(
        find.textContaining(l10n('settings.pending_sync_count')),
        findsAtLeast(1),
      );
      expect(
        find.textContaining(l10n('settings.sync_error_count')),
        findsAtLeast(1),
      );
      expect(
        find.textContaining(l10n('settings.sync_stale_warning_count')),
        findsOneWidget,
      );
      expect(
        find.textContaining(l10n('settings.sync_conflict_count')),
        findsOneWidget,
      );
      expect(
        find.textContaining(l10n('settings.background_sync')),
        findsAtLeast(1),
      );
      expect(
        find.textContaining(l10n('settings.realtime_sync')),
        findsAtLeast(1),
      );
    });

    testWidgets('sync button disabled during active sync', (tester) async {
      final completer = Completer<SyncResult>();
      when(
        () => mockOrchestrator.forceFullSync(),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(createSubject());
      await tester.pump();

      // First tap - starts sync
      await tester.tap(findSyncTile());
      await tester.pump();

      // Second tap - should not trigger another call (tile is disabled)
      await tester.tap(findSyncTile());
      await tester.pump();

      verify(() => mockOrchestrator.forceFullSync()).called(1);

      // Complete and clean up
      completer.complete(SyncResult.success);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
