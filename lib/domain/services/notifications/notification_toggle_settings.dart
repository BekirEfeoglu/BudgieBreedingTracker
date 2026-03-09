/// Holds the enabled/disabled state for each notification category.
///
/// Not to be confused with the Freezed [NotificationSettings] model in
/// `notification_model.dart` which stores full server-synced settings
/// (sound, vibration, thresholds, intervals). This class only tracks
/// local toggle preferences for notification categories.
class NotificationToggleSettings {
  const NotificationToggleSettings({
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.eggTurning = true,
    this.incubation = true,
    this.chickCare = true,
    this.healthCheck = true,
    this.cleanupDaysOld = 30,
  });

  /// Whether notification sounds are enabled.
  final bool soundEnabled;

  /// Whether notification vibrations are enabled.
  final bool vibrationEnabled;

  /// Whether egg turning reminders are enabled.
  final bool eggTurning;

  /// Whether incubation milestone alerts are enabled.
  final bool incubation;

  /// Whether chick care reminders are enabled.
  final bool chickCare;

  /// Whether health check reminders are enabled.
  final bool healthCheck;

  /// Number of days after which read notifications are automatically deleted.
  final int cleanupDaysOld;

  /// Whether all category toggles are enabled.
  bool get allEnabled => eggTurning && incubation && chickCare && healthCheck;

  /// Creates a copy with the given fields replaced.
  NotificationToggleSettings copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? eggTurning,
    bool? incubation,
    bool? chickCare,
    bool? healthCheck,
    int? cleanupDaysOld,
  }) {
    return NotificationToggleSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      eggTurning: eggTurning ?? this.eggTurning,
      incubation: incubation ?? this.incubation,
      chickCare: chickCare ?? this.chickCare,
      healthCheck: healthCheck ?? this.healthCheck,
      cleanupDaysOld: cleanupDaysOld ?? this.cleanupDaysOld,
    );
  }
}
