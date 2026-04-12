import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/notification_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_list_providers.dart';

class _MockNotificationRepository extends Mock
    implements NotificationRepository {}

AppNotification _notif({required String id, bool read = false}) {
  return AppNotification(id: id, title: 'Test', userId: 'user-1', read: read);
}

void main() {
  group('notificationTypeFromReference', () {
    test('maps known reference types to NotificationType values', () {
      expect(
        notificationTypeFromReference('egg_turning'),
        NotificationType.eggTurning,
      );
      expect(
        notificationTypeFromReference('temperature'),
        NotificationType.temperatureAlert,
      );
      expect(
        notificationTypeFromReference('humidity'),
        NotificationType.humidityAlert,
      );
      expect(
        notificationTypeFromReference('feeding'),
        NotificationType.feedingReminder,
      );
      expect(
        notificationTypeFromReference('incubation'),
        NotificationType.incubationReminder,
      );
      expect(
        notificationTypeFromReference('health_check'),
        NotificationType.healthCheck,
      );
    });

    test('falls back to custom for null or unknown references', () {
      expect(notificationTypeFromReference(null), NotificationType.custom);
      expect(notificationTypeFromReference('other'), NotificationType.custom);
    });
  });

  group('NotificationFilter', () {
    test('label is non-empty for all values', () {
      for (final filter in NotificationFilter.values) {
        expect(
          filter.label,
          isNotEmpty,
          reason: '${filter.name}.label is empty',
        );
      }
    });

    test('initial provider state is all', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(notificationFilterProvider),
        NotificationFilter.all,
      );
    });

    test('filter state can be changed to unread', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(notificationFilterProvider.notifier).state =
          NotificationFilter.unread;
      expect(
        container.read(notificationFilterProvider),
        NotificationFilter.unread,
      );
    });
  });

  group('filteredNotificationsProvider', () {
    final all = [
      _notif(id: 'a', read: false),
      _notif(id: 'b', read: true),
      _notif(id: 'c', read: false),
    ];

    test('all filter returns all notifications', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(filteredNotificationsProvider(all));
      expect(result, hasLength(3));
    });

    test('unread filter returns only unread notifications', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(notificationFilterProvider.notifier).state =
          NotificationFilter.unread;

      final result = container.read(filteredNotificationsProvider(all));
      expect(result, hasLength(2));
      expect(result.every((n) => !n.read), isTrue);
    });

    test('read filter returns only read notifications', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(notificationFilterProvider.notifier).state =
          NotificationFilter.read;

      final result = container.read(filteredNotificationsProvider(all));
      expect(result, hasLength(1));
      expect(result.first.id, 'b');
    });

    test('returns empty list when source is empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = container.read(filteredNotificationsProvider([]));
      expect(result, isEmpty);
    });
  });

  group('NotificationActions', () {
    late _MockNotificationRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = _MockNotificationRepository();
      container = ProviderContainer(
        overrides: [notificationRepositoryProvider.overrideWithValue(mockRepo)],
      );
    });

    tearDown(() => container.dispose());

    test('markAsRead calls repo.markAsRead', () async {
      when(() => mockRepo.markAsRead('notif-1')).thenAnswer((_) async {});

      final actions = container.read(notificationActionsProvider);
      await actions.markAsRead('notif-1');

      verify(() => mockRepo.markAsRead('notif-1')).called(1);
    });

    test('markAllAsRead calls repo.markAllAsRead', () async {
      when(() => mockRepo.markAllAsRead('user-1')).thenAnswer((_) async {});

      final actions = container.read(notificationActionsProvider);
      await actions.markAllAsRead('user-1');

      verify(() => mockRepo.markAllAsRead('user-1')).called(1);
    });

    test('delete calls repo.remove', () async {
      when(() => mockRepo.remove('notif-2')).thenAnswer((_) async {});

      final actions = container.read(notificationActionsProvider);
      await actions.delete('notif-2');

      verify(() => mockRepo.remove('notif-2')).called(1);
    });
  });
}
