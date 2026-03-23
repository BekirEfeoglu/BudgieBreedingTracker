import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_ids.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_rate_limiter.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_toggle_settings.dart';

/// Chick care scheduling and immediate notification display.
///
/// Extracted from [NotificationScheduler] to keep each file within the
/// 300-line limit. Mixed into [NotificationScheduler].
mixin NotificationSchedulerReminders {
  /// The underlying notification service.
  NotificationService get notificationService;

  /// The rate limiter for immediate notifications.
  NotificationRateLimiter get rateLimiter;

  /// Schedules chick care reminders (feeding, weight check).
  ///
  /// Respects [NotificationToggleSettings.chickCare] toggle.
  Future<void> scheduleChickCareReminder({
    required String chickId,
    required String chickLabel,
    required DateTime startDate,
    required int intervalHours,
    required int durationDays,
    NotificationToggleSettings? settings,
    @visibleForTesting DateTime? now,
  }) async {
    if (settings != null && !settings.chickCare) {
      AppLogger.info(
        '[NotificationScheduler] Chick care disabled, skipping $chickLabel',
      );
      return;
    }

    if (intervalHours <= 0 || intervalHours > 24) {
      AppLogger.warning(
        '[NotificationScheduler] Invalid chick care intervalHours=$intervalHours '
        'for $chickLabel',
      );
      return;
    }

    final remindersPerDay = 24 ~/ intervalHours;
    if (remindersPerDay <= 0) {
      AppLogger.warning(
        '[NotificationScheduler] Invalid remindersPerDay=$remindersPerDay '
        'for $chickLabel',
      );
      return;
    }

    final now0 = now ?? DateTime.now();
    final futures = <Future<void>>[];
    var offset = 0;

    outer:
    for (var day = 0; day < durationDays; day++) {
      for (var r = 0; r < remindersPerDay; r++) {
        if (offset >= NotificationIds.idsPerEntitySlot) {
          break outer;
        }

        final scheduledDate = DateTime(
          startDate.year,
          startDate.month,
          startDate.day + day,
          intervalHours * r,
        );

        if (scheduledDate.isBefore(now0)) continue;

        final id = NotificationIds.generate(
          NotificationIds.chickCareBaseId,
          chickId,
          offset,
        );

        futures.add(
          notificationService.scheduleNotification(
            id: id,
            title: 'notifications.chick_care_title'.tr(),
            body: 'notifications.chick_care_body'.tr(args: [chickLabel]),
            scheduledDate: scheduledDate,
            channelId: NotificationService.chickCareChannelId,
            payload: 'chick_care:$chickId',
          ),
        );
        offset++;
      }
    }
    await Future.wait(futures);

    if (offset >= NotificationIds.idsPerEntitySlot) {
      AppLogger.warning(
        '[NotificationScheduler] Chick care reminders capped at '
        '${NotificationIds.idsPerEntitySlot} per chick ($chickLabel)',
      );
    }

    AppLogger.info(
      '[NotificationScheduler] Chick care reminders for $chickLabel',
    );
  }

  /// Shows an immediate notification with rate limiting.
  ///
  /// Checks [NotificationRateLimiter] before showing. Returns `true`
  /// if the notification was shown, `false` if rate-limited or in DND.
  Future<bool> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    required String type,
    required String userId,
    String channelId = 'default',
    String? payload,
  }) async {
    if (!rateLimiter.canSend(type, userId)) return false;

    await notificationService.showNotification(
      id: id,
      title: title,
      body: body,
      channelId: channelId,
      payload: payload,
    );
    rateLimiter.recordSent(type, userId);
    return true;
  }
}
