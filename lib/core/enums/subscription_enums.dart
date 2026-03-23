enum SubscriptionStatus {
  unknown,
  free,
  premium,
  trial;

  String toJson() => name;
  static SubscriptionStatus fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return SubscriptionStatus.unknown;
    }
  }
}

enum BackupFrequency {
  unknown,
  daily,
  weekly,
  monthly,
  never;

  String toJson() => name;
  static BackupFrequency fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return BackupFrequency.unknown;
    }
  }
}

enum GracePeriodStatus {
  active,
  gracePeriod,
  expired,
  free,
  unknown;

  String toJson() => name;
  static GracePeriodStatus fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return GracePeriodStatus.unknown;
    }
  }
}
