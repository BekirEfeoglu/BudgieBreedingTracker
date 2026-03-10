import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/models/event_reminder_model.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/data/models/notification_schedule_model.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';

/// Processes pending [EventReminder] and [NotificationSchedule] records.
///
/// Checks for unsent event reminders and unprocessed notification schedules,
/// then triggers the appropriate notification via [NotificationService].
/// Should be called periodically (e.g. during sync or app resume).
class NotificationProcessor {
  NotificationProcessor(this._ref);

  final Ref _ref;
  static const _tag = '[NotificationProcessor]';
  final Set<String> _scheduledByProcessor = <String>{};

  /// Processes all pending items (event reminders + notification schedules)
  /// and cleans up old read notifications.
  Future<void> processAll() async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == 'anonymous') return;

    await Future.wait([
      processEventReminders(userId),
      processNotificationSchedules(userId),
      _cleanupOldNotifications(userId),
    ]);
  }

  /// Deletes old read notifications to prevent DB bloat.
  ///
  /// Reads `cleanupDaysOld` from [NotificationSettings] (default 30 days).
  Future<void> _cleanupOldNotifications(String userId) async {
    try {
      final notificationsDao = _ref.read(notificationsDaoProvider);
      final settingsDao = _ref.read(notificationSettingsDaoProvider);
      final settings = await settingsDao.getByUser(userId);
      final daysOld = settings?.cleanupDaysOld ?? 30;
      final deleted = await notificationsDao.deleteOldRead(
        userId,
        daysOld: daysOld,
      );
      if (deleted > 0) {
        AppLogger.info('$_tag Cleaned up $deleted old read notifications');
      }
    } catch (e, st) {
      AppLogger.warning('$_tag Old notification cleanup failed: $e');
      Sentry.captureException(e, stackTrace: st);
    }
  }

  /// Finds unsent [EventReminder]s whose trigger time has arrived
  /// and fires notifications for them.
  Future<void> processEventReminders(String userId) async {
    try {
      final eventRemindersDao = _ref.read(eventRemindersDaoProvider);
      final eventsDao = _ref.read(eventsDaoProvider);
      final scheduler = _ref.read(notificationSchedulerProvider);
      final now = DateTime.now();

      final unsentCount = await eventRemindersDao.countUnsent(userId);
      if (unsentCount == 0) return;

      final unsent = await eventRemindersDao.getUnsent(userId);

      AppLogger.info(
        '$_tag Processing ${unsent.length} unsent event reminders',
      );

      for (final reminder in unsent) {
        try {
          final event = await eventsDao.getById(reminder.eventId);
          if (event == null) {
            AppLogger.warning(
              '$_tag Event ${reminder.eventId} not found for reminder ${reminder.id}',
            );
            // Event was deleted; mark reminder as sent to avoid reprocessing.
            await eventRemindersDao.markSent(reminder.id);
            continue;
          }

          final triggerTime = event.eventDate.subtract(
            Duration(minutes: reminder.minutesBefore),
          );

          if (triggerTime.isAfter(now)) {
            // Not yet time — schedule it for the future
            final service = _ref.read(notificationServiceProvider);
            final notificationId = _eventReminderNotificationId(reminder);
            await service.scheduleNotification(
              id: notificationId,
              title: event.title,
              body: _formatReminderBody(reminder, event.title),
              scheduledDate: triggerTime,
              channelId: 'default',
              payload: 'event_reminder:${event.id}',
            );
            await eventRemindersDao.markSent(reminder.id);
          } else if (now.difference(triggerTime).inHours < 24) {
            // Trigger time has passed but within 24h — show immediately
            final shown = await scheduler.showImmediateNotification(
              id: _eventReminderNotificationId(reminder),
              title: event.title,
              body: _formatReminderBody(reminder, event.title),
              type: 'event_reminder',
              userId: userId,
              payload: 'event_reminder:${event.id}',
            );
            if (shown) {
              await eventRemindersDao.markSent(reminder.id);
            }
          } else {
            // Too old — just mark as sent to prevent reprocessing
            await eventRemindersDao.markSent(reminder.id);
          }
        } catch (e, st) {
          AppLogger.warning(
            '$_tag Failed to process reminder ${reminder.id}: $e',
          );
          Sentry.captureException(e, stackTrace: st);
        }
      }
    } catch (e, st) {
      AppLogger.error('$_tag processEventReminders failed', e, st);
      Sentry.captureException(e, stackTrace: st);
    }
  }

  /// Finds pending [NotificationSchedule] records and fires/schedules them.
  ///
  /// Respects per-category toggle settings from [NotificationSettings].
  Future<void> processNotificationSchedules(String userId) async {
    try {
      final schedulesDao = _ref.read(notificationSchedulesDaoProvider);
      final service = _ref.read(notificationServiceProvider);
      final scheduler = _ref.read(notificationSchedulerProvider);
      final now = DateTime.now();

      final pendingCount = await schedulesDao.countPending(userId);
      if (pendingCount == 0) return;

      final pending = await schedulesDao.getPending(userId);

      // Load toggle settings to respect per-category preferences
      final settings = await _loadToggleSettings(userId);

      AppLogger.info(
        '$_tag Processing ${pending.length} pending notification schedules',
      );

      for (final schedule in pending) {
        try {
          var processed = false;

          // Skip if the category toggle is disabled
          if (settings != null && !_isTypeEnabled(schedule.type, settings)) {
            _scheduledByProcessor.remove(schedule.id);
            await schedulesDao.markProcessed(schedule.id);
            continue;
          }

          if (schedule.scheduledAt.isAfter(now)) {
            // Future — schedule once per processor lifetime.
            if (!_scheduledByProcessor.contains(schedule.id)) {
              final notificationId = _scheduleNotificationId(schedule);
              await service.scheduleNotification(
                id: notificationId,
                title: schedule.title,
                body: schedule.message ?? '',
                scheduledDate: schedule.scheduledAt,
                channelId: _channelForType(schedule.type),
                payload: _payloadForSchedule(schedule),
              );
              _scheduledByProcessor.add(schedule.id);
            }
          } else if (now.difference(schedule.scheduledAt).inHours < 24) {
            final wasScheduledByProcessor = _scheduledByProcessor.remove(
              schedule.id,
            );
            bool shown = false;

            if (wasScheduledByProcessor) {
              // Already scheduled via plugin for this runtime. Assume delivery
              // happened and avoid duplicate immediate notifications.
              shown = true;
            } else {
              // Past but recent — show immediately
              shown = await scheduler.showImmediateNotification(
                id: _scheduleNotificationId(schedule),
                title: schedule.title,
                body: schedule.message ?? '',
                type: schedule.type.name,
                userId: userId,
                channelId: _channelForType(schedule.type),
                payload: _payloadForSchedule(schedule),
              );
            }

            if (shown) {
              await schedulesDao.markProcessed(schedule.id);
              processed = true;
            }
          } else {
            // Too old — mark processed
            _scheduledByProcessor.remove(schedule.id);
            await schedulesDao.markProcessed(schedule.id);
            processed = true;
          }

          // Handle recurring schedules
          if (processed &&
              schedule.isRecurring &&
              schedule.intervalMinutes != null &&
              schedule.intervalMinutes! > 0) {
            final nextAt = _nextOccurrenceAfter(
              base: schedule.scheduledAt,
              intervalMinutes: schedule.intervalMinutes!,
              now: now,
            );
            final nextSchedule = schedule.copyWith(
              scheduledAt: nextAt,
              processedAt: null,
            );
            await schedulesDao.insertItem(nextSchedule);
          }
        } catch (e, st) {
          AppLogger.warning(
            '$_tag Failed to process schedule ${schedule.id}: $e',
          );
          Sentry.captureException(e, stackTrace: st);
        }
      }
    } catch (e, st) {
      AppLogger.error('$_tag processNotificationSchedules failed', e, st);
      Sentry.captureException(e, stackTrace: st);
    }
  }

  /// Generates a stable notification ID for an event reminder.
  int _eventReminderNotificationId(EventReminder reminder) {
    // Use a 500000+ range to avoid collision with scheduler ranges
    return NotificationScheduler.notificationId(500000, reminder.id, 0);
  }

  /// Generates a stable notification ID for a notification schedule.
  int _scheduleNotificationId(NotificationSchedule schedule) {
    // Use a 600000+ range
    return NotificationScheduler.notificationId(600000, schedule.id, 0);
  }

  /// Maps [NotificationType] to an Android notification channel ID.
  String _channelForType(NotificationType type) {
    return switch (type) {
      NotificationType.eggTurning => NotificationService.eggTurningChannelId,
      NotificationType.incubationReminder =>
        NotificationService.incubationChannelId,
      NotificationType.feedingReminder =>
        NotificationService.chickCareChannelId,
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
  Future<NotificationSettings?> _loadToggleSettings(String userId) async {
    try {
      final dao = _ref.read(notificationSettingsDaoProvider);
      return await dao.getByUser(userId);
    } catch (e) {
      AppLogger.warning('$_tag Failed to load toggle settings: $e');
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
}

/// Provider for [NotificationProcessor].
final notificationProcessorProvider = Provider<NotificationProcessor>((ref) {
  return NotificationProcessor(ref);
});
