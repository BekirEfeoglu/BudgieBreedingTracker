import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/sync_status_tile.dart';

// NotifierProvider cannot use overrideWithValue — subclass the exact Notifier.
class _FakeIsSyncing extends IsSyncingNotifier {
  _FakeIsSyncing(this._value);
  final bool _value;
  @override
  bool build() => _value;
}

class _FakeLastSyncTime extends LastSyncTimeNotifier {
  _FakeLastSyncTime(this._value);
  final DateTime? _value;
  @override
  DateTime? build() => _value;
}

Widget _createSubject({
  SyncDisplayStatus status = SyncDisplayStatus.synced,
  DateTime? lastSync,
  bool isSyncing = false,
  int pendingCount = 0,
  int staleCount = 0,
}) {
  return ProviderScope(
    overrides: [
      syncStatusProvider.overrideWithValue(status),
      lastSyncTimeProvider.overrideWith(() => _FakeLastSyncTime(lastSync)),
      isSyncingProvider.overrideWith(() => _FakeIsSyncing(isSyncing)),
      pendingSyncCountProvider.overrideWithValue(AsyncData(pendingCount)),
      staleErrorCountProvider.overrideWithValue(AsyncData(staleCount)),
    ],
    child: const MaterialApp(home: Scaffold(body: SyncStatusTile())),
  );
}

void main() {
  group('SyncStatusTile', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(SyncStatusTile), findsOneWidget);
    });

    testWidgets('shows sync_status label', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.text(l10n('profile.sync_status')), findsOneWidget);
    });

    testWidgets('shows IconButton when not syncing', (tester) async {
      await tester.pumpWidget(_createSubject(isSyncing: false));
      await tester.pump();

      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when syncing', (tester) async {
      await tester.pumpWidget(
        _createSubject(isSyncing: true, status: SyncDisplayStatus.syncing),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows syncing subtitle when status is syncing', (
      tester,
    ) async {
      await tester.pumpWidget(
        _createSubject(isSyncing: true, status: SyncDisplayStatus.syncing),
      );
      await tester.pump();

      expect(find.text(l10n('sync.syncing')), findsOneWidget);
    });

    testWidgets('shows offline subtitle when status is offline', (
      tester,
    ) async {
      await tester.pumpWidget(
        _createSubject(status: SyncDisplayStatus.offline),
      );
      await tester.pump();

      expect(find.text(l10n('sync.offline')), findsOneWidget);
    });

    testWidgets('shows error subtitle when status is error', (tester) async {
      await tester.pumpWidget(_createSubject(status: SyncDisplayStatus.error));
      await tester.pump();

      expect(find.text(l10n('profile.sync_error')), findsOneWidget);
    });

    testWidgets('shows never-synced text when lastSync is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _createSubject(status: SyncDisplayStatus.synced, lastSync: null),
      );
      await tester.pump();

      expect(find.text(l10n('profile.sync_never')), findsOneWidget);
    });

    testWidgets('shows stale error count when staleCount > 0', (tester) async {
      await tester.pumpWidget(_createSubject(staleCount: 3));
      await tester.pump();

      // 'sync.stale_errors' with args: ['3']
      expect(find.textContaining(l10nContains('sync.stale_errors')), findsOneWidget);
    });

    testWidgets('does NOT show stale error count when staleCount is 0', (
      tester,
    ) async {
      await tester.pumpWidget(_createSubject(staleCount: 0));
      await tester.pump();

      expect(find.textContaining(l10nContains('sync.stale_errors')), findsNothing);
    });
  });
}
