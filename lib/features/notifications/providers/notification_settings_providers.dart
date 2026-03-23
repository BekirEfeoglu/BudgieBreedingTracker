import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_toggle_settings.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

// Re-export so existing importers still see NotificationToggleSettings.
export 'package:budgie_breeding_tracker/domain/services/notifications/notification_toggle_settings.dart';

/// Manages notification settings persisted in Drift (local SQLite).
///
/// Loads initial values from [NotificationSettingsDao] and persists
/// changes immediately. When a category is disabled, cancels all
/// pending scheduled notifications via [NotificationService.cancelByIdRange].
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
    unawaited(_loadFromDao(userId, generation));
    return const NotificationToggleSettings();
  }

  /// Loads stored settings from the Drift DAO.
  Future<void> _loadFromDao(String userId, int generation) async {
    try {
      final dao = ref.read(notificationSettingsDaoProvider);
      final settings = await dao.getByUser(userId);
      if (!ref.mounted) return;
      if (generation != _loadGeneration) return;
      if (ref.read(currentUserIdProvider) != userId) return;
      if (settings != null) {
        state = NotificationToggleSettings(
          soundEnabled: settings.soundEnabled,
          vibrationEnabled: settings.vibrationEnabled,
          eggTurning: settings.eggTurningEnabled,
          incubation: settings.incubationReminderEnabled,
          chickCare: settings.feedingReminderEnabled,
          healthCheck: settings.healthCheckEnabled,
          cleanupDaysOld: settings.cleanupDaysOld,
        );
        _syncSoundAndVibrationToService();
      }
    } catch (e, st) {
      AppLogger.warning('Failed to load notification settings from DAO: $e');
      Sentry.captureException(e, stackTrace: st);
    }
  }

  /// Persists the current toggle state to the Drift DAO.
  Future<void> _persistToDao() async {
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == 'anonymous') return;
      final dao = ref.read(notificationSettingsDaoProvider);
      final existing = await dao.getByUser(userId);
      final model =
          (existing ??
                  NotificationSettings(id: const Uuid().v4(), userId: userId))
              .copyWith(
                soundEnabled: state.soundEnabled,
                vibrationEnabled: state.vibrationEnabled,
                eggTurningEnabled: state.eggTurning,
                incubationReminderEnabled: state.incubation,
                feedingReminderEnabled: state.chickCare,
                healthCheckEnabled: state.healthCheck,
                cleanupDaysOld: state.cleanupDaysOld,
                updatedAt: DateTime.now(),
              );
      await dao.upsert(model);
    } catch (e, st) {
      AppLogger.warning('Failed to persist notification settings to DAO: $e');
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
    );
    await _persistToDao();

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
    await _persistToDao();
    _syncSoundAndVibrationToService();
  }

  /// Toggles the notification vibration setting.
  Future<void> setVibration(bool value) async {
    state = state.copyWith(vibrationEnabled: value);
    await _persistToDao();
    _syncSoundAndVibrationToService();
  }

  /// Toggles the egg turning notification setting.
  Future<void> setEggTurning(bool value) async {
    state = state.copyWith(eggTurning: value);
    await _persistToDao();
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
    await _persistToDao();
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
    await _persistToDao();
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
    await _persistToDao();
    await _cancelCategoryIfDisabled(
      value,
      NotificationScheduler.healthCheckBaseId,
      NotificationScheduler.healthCheckBaseId + 100000,
      'healthCheck',
    );
  }

  /// Updates the number of days after which read notifications are cleaned up.
  Future<void> setCleanupDaysOld(int days) async {
    state = state.copyWith(cleanupDaysOld: days);
    await _persistToDao();
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
