import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/domain/services/sync/sync_orchestrator.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/action_feedback_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/data_storage_section.dart';

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
    int cacheSize = 1024,
  }) {
    return ProviderScope(
      overrides: [
        syncOrchestratorProvider.overrideWithValue(mockOrchestrator),
        autoSyncProvider.overrideWith(() => _TestAutoSyncNotifier(autoSync)),
        wifiOnlySyncProvider.overrideWith(
          () => _TestWifiOnlySyncNotifier(wifiOnlySync),
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
