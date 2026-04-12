enum ReminderType {
  unknown,
  notification,
  email,
  push;

  String toJson() => name;
  static ReminderType fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return ReminderType.unknown;
    }
  }
}
