import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/network_status_provider.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/retry_scheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_orchestrator.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('syncStatusProvider', () {
    test('returns offline when network is offline', () async {
      final container = ProviderContainer(
        overrides: [
          networkStatusProvider.overrideWith((_) => Stream.value(false)),
        ],
      );
      addTearDown(container.dispose);
      container.listen(networkStatusProvider, (_, __) {});
      await container.read(networkStatusProvider.future);

      expect(container.read(syncStatusProvider), SyncDisplayStatus.offline);
    });

    test('returns syncing when online and sync in progress', () async {
      final container = ProviderContainer(
        overrides: [
          networkStatusProvider.overrideWith((_) => Stream.value(true)),
        ],
      );
      addTearDown(container.dispose);
      container.listen(networkStatusProvider, (_, __) {});
      await container.read(networkStatusProvider.future);
      container.read(isSyncingProvider.notifier).state = true;

      expect(container.read(syncStatusProvider), SyncDisplayStatus.syncing);
    });

    test(
      'returns error when online, not syncing, and syncError=true',
      () async {
        final container = ProviderContainer(
          overrides: [
            networkStatusProvider.overrideWith((_) => Stream.value(true)),
          ],
        );
        addTearDown(container.dispose);
        container.listen(networkStatusProvider, (_, __) {});
        await container.read(networkStatusProvider.future);
        container.read(syncErrorProvider.notifier).state = true;

        expect(container.read(syncStatusProvider), SyncDisplayStatus.error);
      },
    );

    test('returns synced when online and no sync/error flags', () async {
      final container = ProviderContainer(
        overrides: [
          networkStatusProvider.overrideWith((_) => Stream.value(true)),
        ],
      );
      addTearDown(container.dispose);
      container.listen(networkStatusProvider, (_, __) {});
      await container.read(networkStatusProvider.future);

      expect(container.read(syncStatusProvider), SyncDisplayStatus.synced);
    });
  });

  group('triggerManualSync', () {
    test('retries failed records then runs forceFullSync', () async {
      final mock = MockSyncOrchestrator();
      when(() => mock.retryFailedRecords('user-1')).thenAnswer((_) async {});
      when(
        () => mock.forceFullSync(),
      ).thenAnswer((_) async => SyncResult.success);

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          syncOrchestratorProvider.overrideWithValue(mock),
        ],
      );
      addTearDown(container.dispose);

      final manualSyncProvider = FutureProvider<SyncResult>(
        (ref) => triggerManualSync(ref),
      );
      final result = await container.read(manualSyncProvider.future);

      expect(result, SyncResult.success);
      verify(() => mock.retryFailedRecords('user-1')).called(1);
      verify(() => mock.forceFullSync()).called(1);
      expect(container.read(syncErrorProvider), isFalse);
    });

    test('still runs forceFullSync if retry step throws', () async {
      final mock = MockSyncOrchestrator();
      when(
        () => mock.retryFailedRecords('user-1'),
      ).thenThrow(Exception('retry failed'));
      when(
        () => mock.forceFullSync(),
      ).thenAnswer((_) async => SyncResult.error);

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          syncOrchestratorProvider.overrideWithValue(mock),
        ],
      );
      addTearDown(container.dispose);

      final manualSyncProvider = FutureProvider<SyncResult>(
        (ref) => triggerManualSync(ref),
      );
      final result = await container.read(manualSyncProvider.future);
      expect(result, SyncResult.error);
      verify(() => mock.forceFullSync()).called(1);
    });
  });

  group('lastSyncTimeProvider', () {
    test('loads persisted timestamp from SharedPreferences', () async {
      final expected = DateTime(2026, 4, 1, 10, 30);
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyLastSyncedAt: expected.toIso8601String(),
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(lastSyncTimeProvider), isNull);

      await waitUntil(
        () => container.read(lastSyncTimeProvider) == expected,
        maxAttempts: 120,
        interval: const Duration(milliseconds: 5),
      );

      expect(container.read(lastSyncTimeProvider), expected);
    });

    test('keeps null when persisted timestamp is invalid', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyLastSyncedAt: 'not-a-date',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(lastSyncTimeProvider), isNull);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(container.read(lastSyncTimeProvider), isNull);
    });
  });

  group('sync metadata aggregation providers', () {
    late MockSyncMetadataDao mockDao;

    setUp(() {
      mockDao = MockSyncMetadataDao();
    });

    test('pendingSyncCountProvider returns 0 for anonymous user', () async {
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('anonymous'),
          syncMetadataDaoProvider.overrideWithValue(mockDao),
        ],
      );
      addTearDown(container.dispose);

      container.listen(pendingSyncCountProvider, (_, __) {});
      final result = await container.read(pendingSyncCountProvider.future);

      expect(result, 0);
      verifyNever(() => mockDao.watchPendingCount(any()));
    });

    test(
      'pendingSyncCountProvider delegates to DAO for authenticated user',
      () async {
        when(
          () => mockDao.watchPendingCount('user-1'),
        ).thenAnswer((_) => Stream.value(3));

        final container = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            syncMetadataDaoProvider.overrideWithValue(mockDao),
          ],
        );
        addTearDown(container.dispose);

        container.listen(pendingSyncCountProvider, (_, __) {});
        final result = await container.read(pendingSyncCountProvider.future);

        expect(result, 3);
        verify(() => mockDao.watchPendingCount('user-1')).called(1);
      },
    );

    test('staleErrorCountProvider returns 0 for anonymous user', () async {
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('anonymous'),
          syncMetadataDaoProvider.overrideWithValue(mockDao),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(staleErrorCountProvider.future);

      expect(result, 0);
      verifyNever(() => mockDao.countStaleErrors(any(), any(), any()));
    });

    test(
      'staleErrorCountProvider delegates expected thresholds to DAO',
      () async {
        when(
          () => mockDao.countStaleErrors(
            'user-1',
            const Duration(hours: 24),
            RetryScheduler.maxRetries,
          ),
        ).thenAnswer((_) async => 2);

        final container = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            syncMetadataDaoProvider.overrideWithValue(mockDao),
          ],
        );
        addTearDown(container.dispose);

        final result = await container.read(staleErrorCountProvider.future);

        expect(result, 2);
        verify(
          () => mockDao.countStaleErrors(
            'user-1',
            const Duration(hours: 24),
            RetryScheduler.maxRetries,
          ),
        ).called(1);
      },
    );

    test(
      'syncErrorDetailsProvider returns empty list for anonymous family input',
      () async {
        final container = ProviderContainer(
          overrides: [syncMetadataDaoProvider.overrideWithValue(mockDao)],
        );
        addTearDown(container.dispose);

        container.listen(syncErrorDetailsProvider('anonymous'), (_, __) {});
        final result = await container.read(
          syncErrorDetailsProvider('anonymous').future,
        );

        expect(result, isEmpty);
        verifyNever(() => mockDao.watchErrorsByTable(any()));
      },
    );

    test(
      'syncErrorDetailsProvider delegates grouped error stream to DAO',
      () async {
        final details = [
          SyncErrorDetail(
            tableName: 'birds',
            errorCount: 2,
            lastError: 'timeout',
            lastAttempt: DateTime(2026, 4, 1, 12),
          ),
        ];
        when(
          () => mockDao.watchErrorsByTable('user-1'),
        ).thenAnswer((_) => Stream.value(details));

        final container = ProviderContainer(
          overrides: [syncMetadataDaoProvider.overrideWithValue(mockDao)],
        );
        addTearDown(container.dispose);

        container.listen(syncErrorDetailsProvider('user-1'), (_, __) {});
        final result = await container.read(
          syncErrorDetailsProvider('user-1').future,
        );

        expect(result, hasLength(1));
        expect(result.single.tableName, 'birds');
        expect(result.single.errorCount, 2);
        expect(result.single.lastError, 'timeout');
        verify(() => mockDao.watchErrorsByTable('user-1')).called(1);
      },
    );

    test(
      'pendingByTableProvider returns empty list for anonymous family input',
      () async {
        final container = ProviderContainer(
          overrides: [syncMetadataDaoProvider.overrideWithValue(mockDao)],
        );
        addTearDown(container.dispose);

        container.listen(pendingByTableProvider('anonymous'), (_, __) {});
        final result = await container.read(
          pendingByTableProvider('anonymous').future,
        );

        expect(result, isEmpty);
        verifyNever(() => mockDao.watchPendingByTable(any()));
      },
    );

    test(
      'pendingByTableProvider delegates grouped pending stream to DAO',
      () async {
        final details = [
          const SyncErrorDetail(tableName: 'eggs', errorCount: 4),
        ];
        when(
          () => mockDao.watchPendingByTable('user-1'),
        ).thenAnswer((_) => Stream.value(details));

        final container = ProviderContainer(
          overrides: [syncMetadataDaoProvider.overrideWithValue(mockDao)],
        );
        addTearDown(container.dispose);

        container.listen(pendingByTableProvider('user-1'), (_, __) {});
        final result = await container.read(
          pendingByTableProvider('user-1').future,
        );

        expect(result, hasLength(1));
        expect(result.single.tableName, 'eggs');
        expect(result.single.errorCount, 4);
        verify(() => mockDao.watchPendingByTable('user-1')).called(1);
      },
    );
  });
}
