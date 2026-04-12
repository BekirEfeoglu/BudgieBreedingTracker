part of 'notification_processor.dart';

/// Generates a stable notification ID for an [EventReminder].
///
/// Uses a 500000+ range to avoid collision with scheduler ranges.
int _eventReminderNotificationId(EventReminder reminder) {
  return NotificationScheduler.notificationId(500000, reminder.id, 0);
}

/// Generates a stable notification ID for a [NotificationSchedule].
///
/// Uses a 600000+ range.
int _scheduleNotificationId(NotificationSchedule schedule) {
  return NotificationScheduler.notificationId(600000, schedule.id, 0);
}

/// Maps [NotificationType] to an Android notification channel ID.
String _channelForType(NotificationType type) {
  return switch (type) {
    NotificationType.eggTurning => NotificationService.eggTurningChannelId,
    NotificationType.incubationReminder =>
      NotificationService.incubationChannelId,
    NotificationType.feedingReminder => NotificationService.chickCareChannelId,
    NotificationType.healthCheck => NotificationService.healthCheckChannelId,
    _ => 'default',
  };
}

/// Builds a payload string for a notification schedule.
String? _payloadForSchedule(NotificationSchedule schedule) {
  if (schedule.relatedEntityId == null) return null;
  return '${schedule.type.name}:${schedule.relatedEntityId}';
}

/// Formats reminder body text with localization.
String _formatReminderBody(EventReminder reminder, String eventTitle) {
  if (reminder.minutesBefore >= 60) {
    final hours = reminder.minutesBefore ~/ 60;
    return 'notifications.reminder_hours_before'.tr(
      args: [eventTitle, '$hours'],
    );
  }
  return 'notifications.reminder_minutes_before'.tr(
    args: [eventTitle, '${reminder.minutesBefore}'],
  );
}

/// Calculates the next occurrence after [now] for a recurring schedule.
DateTime _nextOccurrenceAfter({
  required DateTime base,
  required int intervalMinutes,
  required DateTime now,
}) {
  var next = base.add(Duration(minutes: intervalMinutes));
  while (!next.isAfter(now)) {
    next = next.add(Duration(minutes: intervalMinutes));
  }
  return next;
}

/// Loads notification toggle settings from the DAO.
Future<NotificationSettings?> _loadToggleSettings(
  Ref ref,
  String userId,
) async {
  try {
    final dao = ref.read(notificationSettingsDaoProvider);
    return await dao.getByUser(userId);
  } catch (e) {
    AppLogger.warning('[NotificationProcessor] Failed to load toggle settings: $e');
    return null;
  }
}

/// Checks if the given [NotificationType] is enabled per user settings.
bool _isTypeEnabled(NotificationType type, NotificationSettings settings) {
  return switch (type) {
    NotificationType.eggTurning => settings.eggTurningEnabled,
    NotificationType.incubationReminder => settings.incubationReminderEnabled,
    NotificationType.feedingReminder => settings.feedingReminderEnabled,
    NotificationType.healthCheck => settings.healthCheckEnabled,
    NotificationType.temperatureAlert => settings.temperatureAlertEnabled,
    NotificationType.humidityAlert => settings.humidityAlertEnabled,
    _ => true, // custom/unknown types are always enabled
  };
}
