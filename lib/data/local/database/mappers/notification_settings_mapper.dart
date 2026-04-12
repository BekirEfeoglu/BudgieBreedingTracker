import 'package:drift/drift.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';

extension NotificationSettingsRowMapper on NotificationSettingsRow {
  NotificationSettings toModel() => NotificationSettings(
    id: id,
    userId: userId,
    language: language,
    soundEnabled: soundEnabled,
    vibrationEnabled: vibrationEnabled,
    eggTurningEnabled: eggTurningEnabled,
    temperatureAlertEnabled: temperatureAlertEnabled,
    humidityAlertEnabled: humidityAlertEnabled,
    feedingReminderEnabled: feedingReminderEnabled,
    incubationReminderEnabled: incubationReminderEnabled,
    healthCheckEnabled: healthCheckEnabled,
    bandingEnabled: bandingEnabled,
    temperatureMin: temperatureMin,
    temperatureMax: temperatureMax,
    humidityMin: humidityMin,
    humidityMax: humidityMax,
    eggTurningIntervalMinutes: eggTurningIntervalMinutes,
    feedingReminderIntervalMinutes: feedingReminderIntervalMinutes,
    temperatureCheckIntervalMinutes: temperatureCheckIntervalMinutes,
    cleanupDaysOld: cleanupDaysOld,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension NotificationSettingsModelMapper on NotificationSettings {
  NotificationSettingsTableCompanion toCompanion() =>
      NotificationSettingsTableCompanion(
        id: Value(id),
        userId: Value(userId),
        language: Value(language),
        soundEnabled: Value(soundEnabled),
        vibrationEnabled: Value(vibrationEnabled),
        eggTurningEnabled: Value(eggTurningEnabled),
        temperatureAlertEnabled: Value(temperatureAlertEnabled),
        humidityAlertEnabled: Value(humidityAlertEnabled),
        feedingReminderEnabled: Value(feedingReminderEnabled),
        incubationReminderEnabled: Value(incubationReminderEnabled),
        healthCheckEnabled: Value(healthCheckEnabled),
        bandingEnabled: Value(bandingEnabled),
        temperatureMin: Value(temperatureMin),
        temperatureMax: Value(temperatureMax),
        humidityMin: Value(humidityMin),
        humidityMax: Value(humidityMax),
        eggTurningIntervalMinutes: Value(eggTurningIntervalMinutes),
        feedingReminderIntervalMinutes: Value(feedingReminderIntervalMinutes),
        temperatureCheckIntervalMinutes: Value(temperatureCheckIntervalMinutes),
        cleanupDaysOld: Value(cleanupDaysOld),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt ?? DateTime.now()),
      );
}
