enum NotificationType {
  unknown,
  eggTurning,
  temperatureAlert,
  humidityAlert,
  feedingReminder,
  incubationReminder,
  healthCheck,
  custom;

  String toJson() => name;
  static NotificationType fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return NotificationType.unknown;
    }
  }
}

enum NotificationPriority {
  unknown,
  low,
  normal,
  high,
  critical;

  String toJson() => name;
  static NotificationPriority fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return NotificationPriority.unknown;
    }
  }
}
