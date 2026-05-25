import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_orchestrator.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/shared/widgets/offline_banner.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockSyncOrchestrator mockOrchestrator;

  setUp(() {
    mockOrchestrator = MockSyncOrchestrator();
    when(
      () => mockOrchestrator.forceFullSync(),
    ).thenAnswer((_) async => SyncResult.success);
  });

  SyncMetadata staleError(String id) {
    return SyncMetadata(
      id: id,
      table: 'birds',
      userId: 'user-1',
      recordId: 'record-$id',
      status: SyncStatus.error,
      retryCount: 7,
      createdAt: DateTime(2026, 5, 15),
    );
  }

  Widget subject({
    required SyncDisplayStatus status,
    int pendingCount = 0,
    List<SyncMetadata> pendingDeletionWarnings = const [],
    int conflictCount = 0,
  }) {
    return ProviderScope(
      overrides: [
        syncStatusProvider.overrideWithValue(status),
        syncOrchestratorProvider.overrideWithValue(mockOrchestrator),
        pendingSyncCountProvider.overrideWith(
          (ref) => Stream.value(pendingCount),
        ),
        pendingDeletionSyncErrorsProvider.overrideWith(
          (ref) async => pendingDeletionWarnings,
        ),
        currentUserIdProvider.overrideWith((ref) => 'user-1'),
        persistedConflictCountProvider.overrideWith(
          (ref, userId) => Stream.value(conflictCount),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: OfflineBanner(child: Text('content'))),
      ),
    );
  }

  group('OfflineBanner', () {
    testWidgets('stays hidden when synced and no stale warnings', (
      tester,
    ) async {
      await tester.pumpWidget(subject(status: SyncDisplayStatus.synced));
      await tester.pump();

      expect(find.text(l10n('sync.offline_banner')), findsNothing);
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('shows offline banner and pending count', (tester) async {
      await tester.pumpWidget(
        subject(status: SyncDisplayStatus.offline, pendingCount: 3),
      );
      await tester.pump();

      expect(find.text(l10n('sync.offline_banner')), findsOneWidget);
      expect(find.text(l10n('sync.pending_changes_count')), findsOneWidget);
      expect(find.text(l10n('sync.retry_action')), findsNothing);
    });

    testWidgets('shows error banner with retry action', (tester) async {
      await tester.pumpWidget(subject(status: SyncDisplayStatus.error));
      await tester.pump();

      expect(find.text(l10n('sync.error_banner')), findsOneWidget);
      expect(find.text(l10n('sync.retry_action')), findsOneWidget);
    });

    testWidgets('retry action forces full sync', (tester) async {
      await tester.pumpWidget(subject(status: SyncDisplayStatus.error));
      await tester.pump();

      await tester.tap(find.text(l10n('sync.retry_action')));
      await tester.pump();

      verify(() => mockOrchestrator.forceFullSync()).called(1);
    });

    testWidgets('shows stale pre-warning before cleanup window', (
      tester,
    ) async {
      await tester.pumpWidget(
        subject(
          status: SyncDisplayStatus.synced,
          pendingDeletionWarnings: [staleError('1')],
        ),
      );
      await tester.pump();

      expect(find.text(l10n('sync.pending_deletion_warning')), findsOneWidget);
      expect(find.text(l10n('sync.retry_action')), findsOneWidget);
    });

    testWidgets('shows aggregate conflict banner when conflicts exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        subject(status: SyncDisplayStatus.synced, conflictCount: 3),
      );
      await tester.pump();

      expect(find.text(l10n('sync.conflict_banner_title')), findsOneWidget);
    });

    testWidgets('hides conflict banner when conflictCount is zero', (
      tester,
    ) async {
      await tester.pumpWidget(
        subject(status: SyncDisplayStatus.synced, conflictCount: 0),
      );
      await tester.pump();

      expect(find.text(l10n('sync.conflict_banner_title')), findsNothing);
    });
  });
}
