import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/enums/sync_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart'
    show SyncErrorDetail;
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_orchestrator.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/sync_detail_sheet.dart';

import '../../../helpers/test_localization.dart';
import '../../../helpers/mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(<RestoredSyncRecordKey>[]);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildSubject({
    List<SyncErrorDetail> pending = const [],
    List<SyncErrorDetail> errors = const [],
    List<SyncConflict> conflicts = const [],
    SyncConflictRecoveryService? recoveryService,
    MockSyncOrchestrator? orchestrator,
    _FakeConflictNotifier? conflictNotifier,
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        pendingByTableProvider(
          'user-1',
        ).overrideWith((_) => Stream.value(pending)),
        syncErrorDetailsProvider(
          'user-1',
        ).overrideWith((_) => Stream.value(errors)),
        conflictHistoryProvider.overrideWith(
          () => conflictNotifier ?? _FakeConflictNotifier(conflicts),
        ),
        if (recoveryService != null)
          syncConflictRecoveryServiceProvider.overrideWithValue(
            recoveryService,
          ),
        if (orchestrator != null)
          syncOrchestratorProvider.overrideWithValue(orchestrator),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSyncDetailSheet(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  group('SyncDetailSheet', () {
    testWidgets('opens bottom sheet with title', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text(l10n('sync.error_details_title')), findsOneWidget);
    });

    testWidgets('shows close button', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    });

    testWidgets('shows empty state when no data', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text(l10n('sync.no_errors')), findsOneWidget);
      expect(find.byIcon(LucideIcons.checkCircle), findsOneWidget);
    });

    testWidgets('shows sync now button', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text(l10n('sync.sync_now_action')), findsOneWidget);
    });

    testWidgets('hides clear conflict button when no conflicts', (
      tester,
    ) async {
      await pumpLocalizedApp(tester, buildSubject());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text(l10n('sync.clear_conflict_history')), findsNothing);
    });

    testWidgets('shows clear conflict button when conflicts exist', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          conflicts: [
            SyncConflict(
              table: 'birds',
              recordId: 'r-1',
              detectedAt: DateTime.now(),
              description: 'Server overwrote local bird',
            ),
          ],
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text(l10n('sync.clear_conflict_history')), findsOneWidget);
      expect(find.text(l10n('sync.retry_local_action')), findsOneWidget);
    });

    testWidgets('hides local retry when all conflicts are resolved', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          conflicts: [
            SyncConflict(
              table: 'birds',
              recordId: 'r-1',
              detectedAt: DateTime.now(),
              description: 'Resolved local bird',
              hasLocalSnapshot: true,
              resolvedAt: DateTime.now(),
              conflictType: ConflictType.localOverwritten,
            ),
          ],
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text(l10n('sync.retry_local_action')), findsNothing);
      expect(find.text(l10n('sync.keep_remote_action')), findsNothing);
      expect(find.text(l10n('sync.conflict_local_restored')), findsOneWidget);
    });

    testWidgets('labels a remotely resolved conflict as server preserved', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          conflicts: [
            SyncConflict(
              table: 'birds',
              recordId: 'r-1',
              detectedAt: DateTime.now(),
              description: 'Resolved remote bird',
              hasLocalSnapshot: true,
              resolvedAt: DateTime.now(),
              conflictType: ConflictType.serverWins,
            ),
          ],
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text(l10n('sync.keep_remote_action')), findsNothing);
      expect(find.text(l10n('sync.retry_local_action')), findsNothing);
      expect(find.text(l10n('sync.conflict_server_wins')), findsOneWidget);
    });

    testWidgets(
      'keep remote resolves pending markers and reloads conflict history',
      (tester) async {
        final recovery = _MockConflictRecoveryService();
        final notifier = _FakeConflictNotifier([
          SyncConflict(
            table: 'birds',
            recordId: 'r-1',
            detectedAt: DateTime.utc(2026, 7, 17),
            description: 'Server overwrote local bird',
            hasLocalSnapshot: true,
          ),
        ]);
        when(() => recovery.keepRemote('user-1')).thenAnswer((_) async => 1);

        await pumpLocalizedApp(
          tester,
          buildSubject(
            conflicts: notifier.initial,
            recoveryService: recovery,
            conflictNotifier: notifier,
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text(l10n('sync.keep_remote_action')));
        await tester.pumpAndSettle();

        expect(find.text(l10n('sync.error_details_title')), findsNothing);
        expect(notifier.reloadCount, 1);
        verify(() => recovery.keepRemote('user-1')).called(1);
      },
    );

    testWidgets(
      'keeps sheet open when sync reports success but restored metadata remains',
      (tester) async {
        final recovery = _MockConflictRecoveryService();
        final orchestrator = MockSyncOrchestrator();
        final notifier = _FakeConflictNotifier([
          SyncConflict(
            table: 'birds',
            recordId: 'r-1',
            detectedAt: DateTime.utc(2026, 7, 17),
            description: 'Server overwrote local bird',
            hasLocalSnapshot: true,
          ),
        ]);
        when(() => recovery.retryLocal('user-1')).thenAnswer(
          (_) async => SyncConflictRetryResult(
            restored: 1,
            restoredRecords: [(tableName: 'birds', recordId: 'r-1')],
          ),
        );
        when(
          () => orchestrator.fullSync(),
        ).thenAnswer((_) async => SyncResult.success);
        when(
          () => recovery.areRestoredRecordsSynced(any()),
        ).thenAnswer((_) async => false);

        await pumpLocalizedApp(
          tester,
          buildSubject(
            conflicts: notifier.initial,
            recoveryService: recovery,
            orchestrator: orchestrator,
            conflictNotifier: notifier,
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text(l10n('sync.retry_local_action')));
        await tester.pumpAndSettle();

        expect(find.text(l10n('sync.error_details_title')), findsOneWidget);
        expect(find.text(l10n('sync.retry_local_success')), findsNothing);
        expect(find.text(l10n('sync.retry_local_queued')), findsOneWidget);
        expect(notifier.reloadCount, 1);
        verify(() => orchestrator.fullSync()).called(1);
        verify(() => recovery.areRestoredRecordsSynced(any())).called(1);
      },
    );

    testWidgets('shows pending section when pending records exist', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          pending: [const SyncErrorDetail(tableName: 'birds', errorCount: 3)],
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text(l10n('sync.pending_section')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows failed section when errors exist', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          errors: [
            const SyncErrorDetail(
              tableName: 'eggs',
              errorCount: 2,
              lastError: 'Network timeout',
            ),
          ],
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text(l10n('sync.failed_section')), findsOneWidget);
      expect(find.text('Network timeout'), findsOneWidget);
    });

    testWidgets('shows conflict description', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          conflicts: [
            SyncConflict(
              table: 'birds',
              recordId: 'r-1',
              detectedAt: DateTime.now(),
              description: 'Server overwrote local bird',
            ),
          ],
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Server overwrote local bird'), findsOneWidget);
      expect(find.text(l10n('sync.conflict_section')), findsOneWidget);
    });

    testWidgets('close button pops the bottom sheet', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();

      // Bottom sheet should be gone, title no longer visible
      expect(find.text(l10n('sync.error_details_title')), findsNothing);
    });

    testWidgets('shows both pending and failed sections together', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          pending: [const SyncErrorDetail(tableName: 'birds', errorCount: 3)],
          errors: [
            const SyncErrorDetail(
              tableName: 'eggs',
              errorCount: 2,
              lastError: 'Timeout',
            ),
          ],
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text(l10n('sync.pending_section')), findsOneWidget);
      expect(find.text(l10n('sync.failed_section')), findsOneWidget);
      expect(find.text('Timeout'), findsOneWidget);
    });

    testWidgets('shows multiple pending items', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          pending: [
            const SyncErrorDetail(tableName: 'birds', errorCount: 3),
            const SyncErrorDetail(tableName: 'eggs', errorCount: 5),
          ],
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text(l10n('sync.pending_section')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });
  });
}

class _FakeConflictNotifier extends ConflictHistoryNotifier {
  final List<SyncConflict> _initial;
  _FakeConflictNotifier(this._initial);

  List<SyncConflict> get initial => _initial;
  int reloadCount = 0;

  @override
  List<SyncConflict> build() => _initial;

  @override
  Future<void> reload() async {
    reloadCount++;
  }
}

class _MockConflictRecoveryService extends Mock
    implements SyncConflictRecoveryService {}
