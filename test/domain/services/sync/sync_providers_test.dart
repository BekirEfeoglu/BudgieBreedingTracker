import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/domain/services/sync/network_status_provider.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_orchestrator.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

import '../../../helpers/mocks.dart';

void main() {
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
}
