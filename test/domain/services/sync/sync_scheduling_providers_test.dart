import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_orchestrator.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_settings_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/network_status_provider.dart';

import '../../../helpers/mocks.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('periodicSyncProvider', () {
    test('skips when userId is anonymous', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [currentUserIdProvider.overrideWithValue('anonymous')],
        );

        // Should not throw — provider returns early for anonymous
        container.read(periodicSyncProvider);

        // Advance past jitter window — nothing should happen
        async.elapse(const Duration(minutes: 1));
        container.dispose();
      });
    });

    test('skips when autoSync is disabled', () {
      fakeAsync((async) {
        final mock = MockSyncOrchestrator();

        final container = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            autoSyncProvider.overrideWith(() => _AutoSyncFalse()),
            syncOrchestratorProvider.overrideWithValue(mock),
          ],
        );

        container.read(periodicSyncProvider);

        // Advance past jitter + periodic interval
        async.elapse(const Duration(minutes: 20));

        // No sync calls because autoSync is disabled
        verifyNever(() => mock.fullSync());
        verifyNever(() => mock.retryFailedRecords(any()));

        container.dispose();
      });
    });

    test('disposes timer on container dispose without errors', () {
      fakeAsync((async) {
        final mock = MockSyncOrchestrator();
        when(() => mock.fullSync()).thenAnswer((_) async => SyncResult.success);

        final container = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            autoSyncProvider.overrideWith(() => _AutoSyncTrue()),
            wifiOnlySyncProvider.overrideWith(() => _WifiOnlyFalse()),
            syncOrchestratorProvider.overrideWithValue(mock),
          ],
        );

        // Read the provider to start the timer
        container.read(periodicSyncProvider);

        // Advance past jitter to let initial timer fire
        async.elapse(const Duration(seconds: 61));

        // Disposing cancels the periodic timer — no errors
        container.dispose();

        // Advance more — no callbacks should fire after dispose
        async.elapse(const Duration(minutes: 30));
      });
    });

    test(
      'cancels timers when userId transitions from signed-in to anonymous',
      () {
        fakeAsync((async) {
          final mock = MockSyncOrchestrator();
          when(
            () => mock.fullSync(),
          ).thenAnswer((_) async => SyncResult.success);
          when(
            () => mock.retryFailedRecords(any()),
          ).thenAnswer((_) async {});

          // Build the container with userId='user-1'; flip via
          // updateOverrides to simulate a sign-out mid-test.
          final sharedOverrides = [
            autoSyncProvider.overrideWith(() => _AutoSyncTrue()),
            wifiOnlySyncProvider.overrideWith(() => _WifiOnlyFalse()),
            syncOrchestratorProvider.overrideWithValue(mock),
          ];
          final container = ProviderContainer(
            overrides: [
              currentUserIdProvider.overrideWithValue('user-1'),
              ...sharedOverrides,
            ],
          );
          addTearDown(container.dispose);

          container.read(periodicSyncProvider);

          // Let the jitter window pass so we know timers are actually armed.
          async.elapse(const Duration(seconds: 61));
          clearInteractions(mock);

          // Sign out: flip userId to 'anonymous' via updateOverrides.
          // The explicit ref.listen in the provider cancels both timers
          // immediately, and the Riverpod rebuild disposes the instance.
          container.updateOverrides([
            currentUserIdProvider.overrideWithValue('anonymous'),
            ...sharedOverrides,
          ]);
          container.read(periodicSyncProvider);
          // Let any microtasks drain.
          async.elapse(const Duration(milliseconds: 1));

          // Advance well past the 15-minute periodic interval — no sync
          // callbacks should fire now that the user is anonymous.
          async.elapse(const Duration(minutes: 60));

          verifyNever(() => mock.fullSync());
          verifyNever(() => mock.retryFailedRecords(any()));
        });
      },
    );
  });

  group('networkAwareSyncProvider', () {
    test('skips when userId is anonymous', () {
      final controller = StreamController<bool>.broadcast();
      addTearDown(controller.close);

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('anonymous'),
          networkStatusProvider.overrideWith((_) => controller.stream),
        ],
      );
      addTearDown(container.dispose);

      // Should complete without error — returns early for anonymous
      container.read(networkAwareSyncProvider);
    });

    test('triggers forceFullSync on offline-to-online transition', () async {
      final mock = MockSyncOrchestrator();
      when(
        () => mock.forceFullSync(),
      ).thenAnswer((_) async => SyncResult.success);

      final controller = StreamController<bool>();
      addTearDown(controller.close);

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          syncOrchestratorProvider.overrideWithValue(mock),
          autoSyncProvider.overrideWith(() => _AutoSyncTrue()),
          wifiOnlySyncProvider.overrideWith(() => _WifiOnlyFalse()),
          networkStatusProvider.overrideWith((_) => controller.stream),
        ],
      );
      addTearDown(container.dispose);

      // Subscribe to providers so listeners fire
      container.listen(networkStatusProvider, (_, __) {});
      container.read(networkAwareSyncProvider);

      // Simulate offline
      controller.add(false);
      await Future<void>.delayed(Duration.zero);

      // Simulate online
      controller.add(true);
      await Future<void>.delayed(Duration.zero);

      verify(() => mock.forceFullSync()).called(1);
    });

    test('clears syncError after successful offline-to-online sync', () async {
      final mock = MockSyncOrchestrator();
      when(
        () => mock.forceFullSync(),
      ).thenAnswer((_) async => SyncResult.success);

      final controller = StreamController<bool>();
      addTearDown(controller.close);

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          syncOrchestratorProvider.overrideWithValue(mock),
          autoSyncProvider.overrideWith(() => _AutoSyncTrue()),
          wifiOnlySyncProvider.overrideWith(() => _WifiOnlyFalse()),
          networkStatusProvider.overrideWith((_) => controller.stream),
        ],
      );
      addTearDown(container.dispose);

      container.read(syncErrorProvider.notifier).state = true;
      container.listen(networkStatusProvider, (_, __) {});
      container.read(networkAwareSyncProvider);

      controller.add(false);
      await Future<void>.delayed(Duration.zero);
      controller.add(true);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(syncErrorProvider), isFalse);
    });

    test(
      'keeps syncError when offline-to-online sync is not successful',
      () async {
        final mock = MockSyncOrchestrator();
        when(
          () => mock.forceFullSync(),
        ).thenAnswer((_) async => SyncResult.error);

        final controller = StreamController<bool>();
        addTearDown(controller.close);

        final container = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            syncOrchestratorProvider.overrideWithValue(mock),
            autoSyncProvider.overrideWith(() => _AutoSyncTrue()),
            wifiOnlySyncProvider.overrideWith(() => _WifiOnlyFalse()),
            networkStatusProvider.overrideWith((_) => controller.stream),
          ],
        );
        addTearDown(container.dispose);

        container.read(syncErrorProvider.notifier).state = true;
        container.listen(networkStatusProvider, (_, __) {});
        container.read(networkAwareSyncProvider);

        controller.add(false);
        await Future<void>.delayed(Duration.zero);
        controller.add(true);
        await Future<void>.delayed(Duration.zero);

        expect(container.read(syncErrorProvider), isTrue);
      },
    );

    test('skips sync when already syncing', () async {
      final mock = MockSyncOrchestrator();

      final controller = StreamController<bool>();
      addTearDown(controller.close);

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          syncOrchestratorProvider.overrideWithValue(mock),
          autoSyncProvider.overrideWith(() => _AutoSyncTrue()),
          wifiOnlySyncProvider.overrideWith(() => _WifiOnlyFalse()),
          networkStatusProvider.overrideWith((_) => controller.stream),
        ],
      );
      addTearDown(container.dispose);

      // Mark as already syncing
      container.read(isSyncingProvider.notifier).state = true;

      container.listen(networkStatusProvider, (_, __) {});
      container.read(networkAwareSyncProvider);

      // Simulate offline -> online
      controller.add(false);
      await Future<void>.delayed(Duration.zero);
      controller.add(true);
      await Future<void>.delayed(Duration.zero);

      // forceFullSync should NOT be called because isSyncing is true
      verifyNever(() => mock.forceFullSync());
    });

    test('does not sync when autoSync is disabled', () async {
      final mock = MockSyncOrchestrator();

      final controller = StreamController<bool>();
      addTearDown(controller.close);

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          syncOrchestratorProvider.overrideWithValue(mock),
          autoSyncProvider.overrideWith(() => _AutoSyncFalse()),
          wifiOnlySyncProvider.overrideWith(() => _WifiOnlyFalse()),
          networkStatusProvider.overrideWith((_) => controller.stream),
        ],
      );
      addTearDown(container.dispose);

      container.listen(networkStatusProvider, (_, __) {});
      container.read(networkAwareSyncProvider);

      // Simulate offline -> online
      controller.add(false);
      await Future<void>.delayed(Duration.zero);
      controller.add(true);
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => mock.forceFullSync());
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

      final provider = FutureProvider<SyncResult>(
        (ref) => triggerManualSync(ref),
      );
      final result = await container.read(provider.future);

      expect(result, SyncResult.success);
      verify(() => mock.retryFailedRecords('user-1')).called(1);
      verify(() => mock.forceFullSync()).called(1);
    });

    test('returns SyncResult.success on success', () async {
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

      final provider = FutureProvider<SyncResult>(
        (ref) => triggerManualSync(ref),
      );
      final result = await container.read(provider.future);

      expect(result, SyncResult.success);
    });

    test('clears sync error on success', () async {
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

      // Set syncError to true before manual sync
      container.read(syncErrorProvider.notifier).state = true;
      expect(container.read(syncErrorProvider), isTrue);

      final provider = FutureProvider<SyncResult>(
        (ref) => triggerManualSync(ref),
      );
      await container.read(provider.future);

      expect(container.read(syncErrorProvider), isFalse);
    });

    test('handles retry failure gracefully', () async {
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

      final provider = FutureProvider<SyncResult>(
        (ref) => triggerManualSync(ref),
      );
      final result = await container.read(provider.future);

      // Should still complete (not throw) even if retry fails
      expect(result, SyncResult.error);
      verify(() => mock.forceFullSync()).called(1);
    });

    test(
      'keeps sync error set when manual sync result is not success',
      () async {
        final mock = MockSyncOrchestrator();
        when(() => mock.retryFailedRecords('user-1')).thenAnswer((_) async {});
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

        container.read(syncErrorProvider.notifier).state = true;

        final provider = FutureProvider<SyncResult>(
          (ref) => triggerManualSync(ref),
        );
        final result = await container.read(provider.future);

        expect(result, SyncResult.error);
        expect(container.read(syncErrorProvider), isTrue);
      },
    );
  });
}

// ── Test Helpers ──

class _AutoSyncTrue extends AutoSyncNotifier {
  @override
  bool build() => true;
}

class _AutoSyncFalse extends AutoSyncNotifier {
  @override
  bool build() => false;
}

class _WifiOnlyFalse extends WifiOnlySyncNotifier {
  @override
  bool build() => false;
}
