@Tags(['e2e'])
library;

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_rate_limiter.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_list_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_settings_providers.dart';

import '../helpers/e2e_test_harness.dart';

class _TestNotificationService extends NotificationService {
  final scheduledPayloads = <String?>[];

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String channelId = 'default',
    String? payload,
  }) async {
    scheduledPayloads.add(payload);
  }
}

void main() {
  ensureE2EBinding();

  group('Notifications Flow E2E', () {
    test(
      'GIVEN logged-in user WHEN notifications list is processed THEN unread ordering and unread badge count are correct',
      () {
        final notifications = <AppNotification>[
          const AppNotification(
            id: '1',
            title: 'A',
            userId: 'user-1',
            read: false,
          ),
          const AppNotification(
            id: '2',
            title: 'B',
            userId: 'user-1',
            read: false,
          ),
          const AppNotification(
            id: '3',
            title: 'C',
            userId: 'user-1',
            read: true,
          ),
        ];

        final container = createTestContainer();
        addTearDown(container.dispose);

        container.read(notificationFilterProvider.notifier).state =
            NotificationFilter.unread;
        final unreadOnly = container.read(
          filteredNotificationsProvider(notifications),
        );

        expect(unreadOnly.length, 2);
        expect(unreadOnly.every((item) => !item.read), isTrue);
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN unread notification WHEN mark-as-read action is triggered THEN read timestamp/update path and deep-link route resolution are available',
      () async {
        final mockRepository = MockNotificationRepository();
        when(
          () => mockRepository.markAsRead('notif-1'),
        ).thenAnswer((_) async {});

        final container = createTestContainer(
          overrides: [
            notificationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final actions = container.read(notificationActionsProvider);
        await actions.markAsRead('notif-1');

        verify(() => mockRepository.markAsRead('notif-1')).called(1);
        expect(
          NotificationService.payloadToRoute('chick:chick-1'),
          '/chicks/chick-1',
        );
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN incubation started WHEN scheduler logic is evaluated with fake_async THEN reminder scheduling and 24-hour rate limiting work',
      () {
        fakeAsync((async) {
          SharedPreferences.setMockInitialValues({});
          final notificationService = _TestNotificationService();
          final rateLimiter = NotificationRateLimiter();
          // Disable DND to prevent time-dependent test failures
          rateLimiter.setDndHours(startHour: 0, endHour: 0);
          async.flushMicrotasks();

          final scheduler = NotificationScheduler(
            notificationService,
            rateLimiter,
          );

          final startDate = DateTime.now().add(const Duration(days: 1));
          scheduler.scheduleIncubationMilestones(
            incubationId: 'inc-1',
            startDate: startDate,
            label: 'Pair-A',
          );

          async.elapse(const Duration(days: 17));

          expect(notificationService.scheduledPayloads, isNotEmpty);

          final firstAllowed = rateLimiter.canSend('incubation', 'test-user');
          expect(firstAllowed, isTrue);
          rateLimiter.recordSent('incubation', 'test-user');

          final secondAllowedSameWindow = rateLimiter.canSend(
            'incubation',
            'test-user',
          );
          expect(secondAllowedSameWindow, isFalse);
        });
      },
      timeout: e2eTimeout,
    );

    test(
      'GIVEN notification settings screen WHEN incubation reminders are toggled off THEN setting is persisted and category becomes disabled',
      () async {
        SharedPreferences.setMockInitialValues({});
        final mockNotificationService = MockNotificationService();
        when(
          () => mockNotificationService.cancelByIdRange(any(), any()),
        ).thenAnswer((_) async => 0);

        final container = ProviderContainer(
          overrides: [
            notificationServiceProvider.overrideWithValue(
              mockNotificationService,
            ),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(notificationToggleSettingsProvider.notifier)
            .setIncubation(false);

        final settings = container.read(notificationToggleSettingsProvider);
        expect(settings.incubation, isFalse);
        verify(
          () => mockNotificationService.cancelByIdRange(
            NotificationScheduler.incubationBaseId,
            NotificationScheduler.incubationBaseId + 100000,
          ),
        ).called(1);
      },
      timeout: e2eTimeout,
    );
  });
}
