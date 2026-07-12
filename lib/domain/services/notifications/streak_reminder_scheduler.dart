import 'package:easy_localization/easy_localization.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:budgie_breeding_tracker/domain/services/notifications/notification_ids.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';

/// Schedules a single daily-streak reminder at 20:00 local, only for users
/// with an active streak (>= 3) who have the toggle enabled.
///
/// Called after each check-in ([runDailyCheckin]), so it always lands on the
/// NEXT day and self-cancels the moment the user opens the app again — the
/// reschedule overwrites the prior pending notification via a deterministic
/// ID, so it only ever fires on a day the user has NOT opened the app.
class StreakReminderScheduler {
  StreakReminderScheduler(this._service);

  final NotificationService _service;

  static const _reminderHour = 20;

  int get _id => NotificationIds.generate(
    NotificationIds.streakReminderBaseId,
    'streak-reminder',
    0,
  );

  /// Cancels the previously scheduled reminder, then — if [enabled] and
  /// [currentStreak] is at least 3 — schedules a single reminder for
  /// tomorrow at 20:00 local.
  Future<void> scheduleNext({
    required int currentStreak,
    required bool enabled,
  }) async {
    await _service.cancel(_id);
    if (!enabled || currentStreak < 3) return;

    // Field addition (not `.add(Duration(days: 1))`) so the calendar day
    // advances correctly across DST boundaries (datetime-format.md).
    final now = tz.TZDateTime.now(tz.local);
    final when = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + 1,
      _reminderHour,
    );

    await _service.scheduleNotification(
      id: _id,
      title: 'notifications.streak_reminder_title'.tr(),
      body: 'notifications.streak_reminder_body'.tr(
        namedArgs: {'count': '$currentStreak'},
      ),
      scheduledDate: when,
      channelId: NotificationService.streakChannelId,
      payload: 'streak:reminder',
    );
  }

  /// Cancels the streak reminder notification, if any is pending.
  Future<void> cancel() => _service.cancel(_id);
}
