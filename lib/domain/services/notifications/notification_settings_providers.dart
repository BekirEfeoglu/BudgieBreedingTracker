import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_toggle_settings.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';

// Re-export so existing importers still see NotificationToggleSettings.
export 'package:budgie_breeding_tracker/domain/services/notifications/notification_toggle_settings.dart';

NotificationToggleSettings _toggleSettingsFromModel(
  NotificationSettings? settings,
) {
  if (settings == null) return const NotificationToggleSettings();

  return NotificationToggleSettings(
    soundEnabled: settings.soundEnabled,
    vibrationEnabled: settings.vibrationEnabled,
    eggTurning: settings.eggTurningEnabled,
    incubation: settings.incubationReminderEnabled,
    chickCare: settings.feedingReminderEnabled,
    healthCheck: settings.healthCheckEnabled,
    banding: settings.bandingEnabled,
    cleanupDaysOld: settings.cleanupDaysOld,
  );
}

final notificationQuietHoursTimeZoneProvider =
    Provider<Future<String> Function()>((ref) {
      return () async {
        try {
          final timezoneInfo = await FlutterTimezone.getLocalTimezone();
          return timezoneInfo.identifier;
        } catch (e) {
          AppLogger.warning(
            '[NotificationToggleSettings] Timezone lookup failed: $e',
          );
          return 'UTC';
        }
      };
    });

/// Manages notification settings persisted in Drift (local SQLite).
///
/// Loads initial values through [NotificationRepository] and persists changes
/// through the same repository so sync metadata is recorded. When a category
/// is disabled, cancels pending scheduled notifications via
/// [NotificationService.cancelByIdRange].
class NotificationToggleSettingsNotifier
    extends Notifier<NotificationToggleSettings> {
  int _loadGeneration = 0;

  @override
  NotificationToggleSettings build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == 'anonymous') {
      return const NotificationToggleSettings();
    }

    final generation = ++_loadGeneration;
    unawaited(_loadSettings(userId, generation));
    return const NotificationToggleSettings();
  }

  /// Loads stored settings from the offline-first notification repository.
  Future<void> _loadSettings(String userId, int generation) async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      final settings = await repo.getSettings(userId);
      if (!ref.mounted) return;
      if (generation != _loadGeneration) return;
      if (ref.read(currentUserIdProvider) != userId) return;
      if (settings != null) {
        _applyLoadedSettings(_toggleSettingsFromModel(settings));
      }
    } catch (e, st) {
      AppLogger.warning('Failed to load notification settings: $e');
      Sentry.captureException(e, stackTrace: st);
    }
  }

  void _applyLoadedSettings(NotificationToggleSettings settings) {
    state = settings;
    _syncSoundAndVibrationToService();
  }

  /// Persists the current toggle state through the repository sync flow.
  Future<void> _persistSettings() async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == 'anonymous') return;
      final repo = ref.read(notificationRepositoryProvider);
      final existing = await repo.getSettings(userId);
      final model =
          (existing ??
                  NotificationSettings(id: const Uuid().v7(), userId: userId))
              .copyWith(
                soundEnabled: state.soundEnabled,
                vibrationEnabled: state.vibrationEnabled,
                eggTurningEnabled: state.eggTurning,
                incubationReminderEnabled: state.incubation,
                feedingReminderEnabled: state.chickCare,
                healthCheckEnabled: state.healthCheck,
                bandingEnabled: state.banding,
                cleanupDaysOld: state.cleanupDaysOld,
                updatedAt: DateTime.now(),
              );
      await repo.upsertSettings(model);
    } catch (e, st) {
      AppLogger.warning('Failed to persist notification settings: $e');
      Sentry.captureException(e, stackTrace: st);
    }
  }

  /// Syncs current sound/vibration preferences to NotificationService.
  void _syncSoundAndVibrationToService() {
    try {
      final service = ref.read(notificationServiceProvider);
      service.updateSoundAndVibration(
        soundEnabled: state.soundEnabled,
        vibrationEnabled: state.vibrationEnabled,
      );
    } catch (e) {
      AppLogger.warning('Failed to sync sound/vibration to service: $e');
    }
  }

  /// Cancels notifications in the given ID range when a category is disabled.
  Future<void> _cancelCategoryIfDisabled(
    bool value,
    int rangeStart,
    int rangeEnd,
    String categoryName,
  ) async {
    if (!value) {
      try {
        final notificationService = ref.read(notificationServiceProvider);
        final cancelled = await notificationService.cancelByIdRange(
          rangeStart,
          rangeEnd,
        );
        AppLogger.info(
          '[NotificationToggleSettings] $categoryName disabled — '
          '$cancelled notifications cancelled',
        );
      } catch (e, st) {
        AppLogger.warning('Failed to cancel $categoryName notifications: $e');
        Sentry.captureException(e, stackTrace: st);
      }
    }
  }

  /// Toggles all notification categories at once.
  ///
  /// When [value] is false, cancels all scheduled notifications across
  /// every category. When true, re-enables all categories.
  Future<void> setAll(bool value) async {
    state = state.copyWith(
      eggTurning: value,
      incubation: value,
      chickCare: value,
      healthCheck: value,
      banding: value,
    );
    await _persistSettings();

    if (!value) {
      try {
        final service = ref.read(notificationServiceProvider);
        await service.cancelAll();
        AppLogger.info(
          '[NotificationToggleSettings] All categories disabled — '
          'all notifications cancelled',
        );
      } catch (e, st) {
        AppLogger.warning('Failed to cancel all notifications: $e');
        Sentry.captureException(e, stackTrace: st);
      }
    }
  }

  /// Toggles the notification sound setting.
  Future<void> setSound(bool value) async {
    state = state.copyWith(soundEnabled: value);
    await _persistSettings();
    _syncSoundAndVibrationToService();
  }

  /// Toggles the notification vibration setting.
  Future<void> setVibration(bool value) async {
    state = state.copyWith(vibrationEnabled: value);
    await _persistSettings();
    _syncSoundAndVibrationToService();
  }

  /// Updates local Do Not Disturb hours and syncs them for server-side push.
  Future<void> setDndHours({
    required int startHour,
    required int endHour,
  }) async {
    final start = startHour.clamp(0, 23).toInt();
    final end = endHour.clamp(0, 23).toInt();
    await ref
        .read(notificationRateLimiterProvider)
        .setDndHours(startHour: start, endHour: end);

    final userId = ref.read(currentUserIdProvider);
    if (userId == 'anonymous') return;

    final timeZone = await ref.read(notificationQuietHoursTimeZoneProvider)();
    if (!ref.mounted) return;

    final quietHours = <String, dynamic>{
      'enabled': start != end,
      'startHour': start,
      'endHour': end,
      'timeZone': timeZone,
    };

    try {
      await ref
          .read(profileRepositoryProvider)
          .updateQuietHours(userId: userId, quietHours: quietHours);
    } catch (e, st) {
      AppLogger.warning(
        '[NotificationToggleSettings] Failed to sync quiet hours: $e',
      );
      Sentry.captureException(e, stackTrace: st);
    }
  }

  /// Toggles the egg turning notification setting.
  Future<void> setEggTurning(bool value) async {
    state = state.copyWith(eggTurning: value);
    await _persistSettings();
    await _cancelCategoryIfDisabled(
      value,
      NotificationScheduler.eggTurningBaseId,
      NotificationScheduler.eggTurningBaseId + 100000,
      'eggTurning',
    );
  }

  /// Toggles the incubation notification setting.
  Future<void> setIncubation(bool value) async {
    state = state.copyWith(incubation: value);
    await _persistSettings();
    await _cancelCategoryIfDisabled(
      value,
      NotificationScheduler.incubationBaseId,
      NotificationScheduler.incubationBaseId + 100000,
      'incubation',
    );
  }

  /// Toggles the chick care notification setting.
  Future<void> setChickCare(bool value) async {
    state = state.copyWith(chickCare: value);
    await _persistSettings();
    await _cancelCategoryIfDisabled(
      value,
      NotificationScheduler.chickCareBaseId,
      NotificationScheduler.chickCareBaseId + 100000,
      'chickCare',
    );
  }

  /// Toggles the health check notification setting.
  Future<void> setHealthCheck(bool value) async {
    state = state.copyWith(healthCheck: value);
    await _persistSettings();
    await _cancelCategoryIfDisabled(
      value,
      NotificationScheduler.healthCheckBaseId,
      NotificationScheduler.healthCheckBaseId + 100000,
      'healthCheck',
    );
  }

  /// Toggles the banding notification setting.
  Future<void> setBanding(bool value) async {
    state = state.copyWith(banding: value);
    await _persistSettings();
    await _cancelCategoryIfDisabled(
      value,
      NotificationScheduler.bandingBaseId,
      NotificationScheduler.bandingBaseId + 100000,
      'banding',
    );
  }

  /// Updates the number of days after which read notifications are cleaned up.
  Future<void> setCleanupDaysOld(int days) async {
    state = state.copyWith(cleanupDaysOld: days);
    await _persistSettings();
  }
}

/// Provider for [NotificationToggleSettings] with persistence.
///
/// Injects [NotificationService] so that disabling a category
/// can cancel pending scheduled notifications.
final notificationToggleSettingsProvider =
    NotifierProvider<
      NotificationToggleSettingsNotifier,
      NotificationToggleSettings
    >(NotificationToggleSettingsNotifier.new);

/// Loads notification toggle settings before scheduling side effects.
///
/// Feature flows should await this provider before creating local notification
/// schedules. Reading [notificationToggleSettingsProvider] directly can return
/// the default state while the persisted settings are still loading.
final notificationToggleSettingsReadyProvider =
    FutureProvider<NotificationToggleSettings>((ref) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == 'anonymous') return const NotificationToggleSettings();

      final repo = ref.watch(notificationRepositoryProvider);
      final model = await repo.getSettings(userId);
      final settings = _toggleSettingsFromModel(model);

      if (model != null &&
          ref.mounted &&
          ref.read(currentUserIdProvider) == userId) {
        ref
            .read(notificationToggleSettingsProvider.notifier)
            ._applyLoadedSettings(settings);
      }

      return settings;
    });
