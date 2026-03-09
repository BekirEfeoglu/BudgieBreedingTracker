import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

@freezed
abstract class AppNotification with _$AppNotification {
  const AppNotification._();
  const factory AppNotification({
    required String id,
    required String title,
    @Default(false) bool read,
    @Default(NotificationType.custom)
    @JsonKey(unknownEnumValue: NotificationType.custom)
    NotificationType type,
    @Default(NotificationPriority.normal)
    @JsonKey(unknownEnumValue: NotificationPriority.normal)
    NotificationPriority priority,
    String? body,
    required String userId,
    String? referenceId,
    String? referenceType,
    DateTime? scheduledAt,
    DateTime? readAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
}

@freezed
abstract class NotificationSettings with _$NotificationSettings {
  const NotificationSettings._();
  const factory NotificationSettings({
    required String id,
    required String userId,
    @Default('tr') String language,
    @Default(true) bool soundEnabled,
    @Default(true) bool vibrationEnabled,
    @Default(true) bool eggTurningEnabled,
    @Default(true) bool temperatureAlertEnabled,
    @Default(true) bool humidityAlertEnabled,
    @Default(true) bool feedingReminderEnabled,
    @Default(true) bool incubationReminderEnabled,
    @Default(true) bool healthCheckEnabled,
    @Default(37.0) double temperatureMin,
    @Default(38.0) double temperatureMax,
    @Default(55.0) double humidityMin,
    @Default(65.0) double humidityMax,
    @Default(480) int eggTurningIntervalMinutes,
    @Default(1440) int feedingReminderIntervalMinutes,
    @Default(60) int temperatureCheckIntervalMinutes,
    @Default(30) int cleanupDaysOld,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _NotificationSettings;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsFromJson(json);
}
