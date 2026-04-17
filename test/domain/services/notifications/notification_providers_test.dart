import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_rate_limiter.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler.dart';
import 'package:budgie_breeding_tracker/router/app_router.dart';

class _MockGoRouter extends Mock implements GoRouter {}

final _drainPendingProvider = Provider<void>((ref) {
  processPendingPayloads(ref);
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    _drainPendingQueue();
  });

  group('notificationServiceProvider', () {
    test(
      'routes notification payload to GoRouter when router is available',
      () {
        final router = _MockGoRouter();
        when(() => router.push(any())).thenAnswer((_) async => null);

        final container = ProviderContainer(
          overrides: [routerProvider.overrideWithValue(router)],
        );
        addTearDown(container.dispose);

        final service = container.read(notificationServiceProvider);
        service.onNotificationTap?.call('bird:bird-42');

        verify(() => router.push('/birds/bird-42')).called(1);
      },
    );

    test('ignores null payload and does not queue', () {
      final router = _MockGoRouter();
      when(() => router.push(any())).thenThrow(StateError('not ready'));

      final container = ProviderContainer(
        overrides: [routerProvider.overrideWithValue(router)],
      );
      addTearDown(container.dispose);

      final service = container.read(notificationServiceProvider);
      // null payload → payloadToRoute returns null → no route → no queue
      service.onNotificationTap?.call(null);

      verifyNever(() => router.push(any()));
    });

    test('does not queue non-routable payload', () {
      final router = _MockGoRouter();
      when(() => router.push(any())).thenThrow(StateError('not ready'));

      final container = ProviderContainer(
        overrides: [routerProvider.overrideWithValue(router)],
      );
      addTearDown(container.dispose);

      final service = container.read(notificationServiceProvider);
      // 'unknown:id' → payloadToRoute returns null → no route → no queue
      service.onNotificationTap?.call('unknown:id');

      verifyNever(() => router.push(any()));
    });

    test('queues payload when router push fails and drains it later', () {
      final failingRouter = _MockGoRouter();
      when(
        () => failingRouter.push(any()),
      ).thenThrow(StateError('router not ready'));

      final queueContainer = ProviderContainer(
        overrides: [routerProvider.overrideWithValue(failingRouter)],
      );
      addTearDown(queueContainer.dispose);

      final service = queueContainer.read(notificationServiceProvider);
      service.onNotificationTap?.call('bird:queued-1');

      final readyRouter = _MockGoRouter();
      when(() => readyRouter.push(any())).thenAnswer((_) async => null);

      final drainContainer = ProviderContainer(
        overrides: [routerProvider.overrideWithValue(readyRouter)],
      );
      addTearDown(drainContainer.dispose);

      drainContainer.read(_drainPendingProvider);
      drainContainer.read(_drainPendingProvider);

      verify(() => readyRouter.push('/birds/queued-1')).called(1);
    });

    test('drains multiple queued payloads in order', () {
      final failingRouter = _MockGoRouter();
      when(() => failingRouter.push(any())).thenThrow(StateError('not ready'));

      final queueContainer = ProviderContainer(
        overrides: [routerProvider.overrideWithValue(failingRouter)],
      );
      addTearDown(queueContainer.dispose);

      final service = queueContainer.read(notificationServiceProvider);
      service.onNotificationTap?.call('bird:b1');
      service.onNotificationTap?.call('chick:c1');
      service.onNotificationTap?.call('breeding:p1');

      final readyRouter = _MockGoRouter();
      when(() => readyRouter.push(any())).thenAnswer((_) async => null);

      final drainContainer = ProviderContainer(
        overrides: [routerProvider.overrideWithValue(readyRouter)],
      );
      addTearDown(drainContainer.dispose);

      drainContainer.read(_drainPendingProvider);

      verify(() => readyRouter.push('/birds/b1')).called(1);
      verify(() => readyRouter.push('/chicks/c1')).called(1);
      verify(() => readyRouter.push('/breeding/p1')).called(1);
    });

    test('processPendingPayloads is no-op when queue is empty', () {
      final router = _MockGoRouter();
      when(() => router.push(any())).thenAnswer((_) async => null);

      final container = ProviderContainer(
        overrides: [routerProvider.overrideWithValue(router)],
      );
      addTearDown(container.dispose);

      container.read(_drainPendingProvider);

      verifyNever(() => router.push(any()));
    });
  });

  group('notificationPermissionGrantedProvider', () {
    test('initial state is true (optimistic default)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(notificationPermissionGrantedProvider), isTrue);
    });

    test('state can be set to false when permission is denied', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(notificationPermissionGrantedProvider.notifier).state =
          false;

      expect(container.read(notificationPermissionGrantedProvider), isFalse);
    });

    test('state can transition from false to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(notificationPermissionGrantedProvider.notifier).state =
          false;
      expect(container.read(notificationPermissionGrantedProvider), isFalse);

      container.read(notificationPermissionGrantedProvider.notifier).state =
          true;
      expect(container.read(notificationPermissionGrantedProvider), isTrue);
    });

    test('listeners are notified on state change', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final states = <bool>[];
      container.listen<bool>(
        notificationPermissionGrantedProvider,
        (_, next) => states.add(next),
      );

      container.read(notificationPermissionGrantedProvider.notifier).state =
          false;
      container.read(notificationPermissionGrantedProvider.notifier).state =
          true;

      expect(states, [false, true]);
    });
  });

  group('provider wiring', () {
    test('notificationSchedulerProvider composes service + limiter', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final scheduler = container.read(notificationSchedulerProvider);
      expect(scheduler, isA<NotificationScheduler>());
    });

    test(
      'rateLimiterReadyProvider completes after loading preferences',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await container.read(rateLimiterReadyProvider.future);

        expect(
          container.read(notificationRateLimiterProvider),
          isA<NotificationRateLimiter>(),
        );
      },
    );
  });
}

void _drainPendingQueue() {
  final router = _MockGoRouter();
  when(() => router.push(any())).thenAnswer((_) async => null);

  final container = ProviderContainer(
    overrides: [routerProvider.overrideWithValue(router)],
  );
  addTearDown(container.dispose);
  try {
    container.read(_drainPendingProvider);
  } finally {
  }
}
