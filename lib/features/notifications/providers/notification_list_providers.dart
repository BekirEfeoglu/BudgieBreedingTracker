import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';

/// Filter options for notification list.
enum NotificationFilter {
  all,
  unread,
  read;

  String get label => switch (this) {
    NotificationFilter.all => 'notifications.filter_all'.tr(),
    NotificationFilter.unread => 'notifications.filter_unread'.tr(),
    NotificationFilter.read => 'notifications.filter_read'.tr(),
  };
}

/// Stream of all notifications for a given user.
final notificationsStreamProvider =
    StreamProvider.family<List<AppNotification>, String>((ref, userId) {
      final repo = ref.watch(notificationRepositoryProvider);
      return repo.watchAll(userId);
    });

/// Stream of unread notifications for a given user.
final unreadNotificationsProvider =
    StreamProvider.family<List<AppNotification>, String>((ref, userId) {
      final repo = ref.watch(notificationRepositoryProvider);
      return repo.watchUnread(userId);
    });

/// Notifier for notification list filter state.
class NotificationFilterNotifier extends Notifier<NotificationFilter> {
  @override
  NotificationFilter build() => NotificationFilter.all;
}

/// Current filter state for notification list.
final notificationFilterProvider =
    NotifierProvider<NotificationFilterNotifier, NotificationFilter>(
      NotificationFilterNotifier.new,
    );

/// Filtered notifications based on current filter.
final filteredNotificationsProvider =
    Provider.family<List<AppNotification>, List<AppNotification>>((
      ref,
      allNotifications,
    ) {
      final filter = ref.watch(notificationFilterProvider);
      return switch (filter) {
        NotificationFilter.all => allNotifications,
        NotificationFilter.unread =>
          allNotifications.where((n) => !n.read).toList(),
        NotificationFilter.read =>
          allNotifications.where((n) => n.read).toList(),
      };
    });

/// Actions for managing notifications (mark read, delete).
final notificationActionsProvider = Provider<NotificationActions>((ref) {
  return NotificationActions(ref);
});

/// Encapsulates notification action operations.
class NotificationActions {
  final Ref _ref;

  NotificationActions(this._ref);

  /// Marks a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    try {
      final repo = _ref.read(notificationRepositoryProvider);
      await repo.markAsRead(notificationId);
    } catch (e) {
      AppLogger.error('[NotificationActions]', e, StackTrace.current);
    }
  }

  /// Marks all notifications as read for a user.
  Future<void> markAllAsRead(String userId) async {
    try {
      final repo = _ref.read(notificationRepositoryProvider);
      await repo.markAllAsRead(userId);
    } catch (e) {
      AppLogger.error('[NotificationActions]', e, StackTrace.current);
    }
  }

  /// Deletes a notification.
  Future<void> delete(String notificationId) async {
    try {
      final repo = _ref.read(notificationRepositoryProvider);
      await repo.remove(notificationId);
    } catch (e) {
      AppLogger.error('[NotificationActions]', e, StackTrace.current);
      rethrow;
    }
  }
}

/// Returns the icon for a notification type.
NotificationType notificationTypeFromReference(String? referenceType) {
  if (referenceType == null) return NotificationType.custom;
  return switch (referenceType) {
    'egg_turning' => NotificationType.eggTurning,
    'temperature' => NotificationType.temperatureAlert,
    'humidity' => NotificationType.humidityAlert,
    'feeding' => NotificationType.feedingReminder,
    'incubation' => NotificationType.incubationReminder,
    'health_check' => NotificationType.healthCheck,
    _ => NotificationType.custom,
  };
}
