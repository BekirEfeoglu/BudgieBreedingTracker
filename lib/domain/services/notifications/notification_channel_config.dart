import 'package:easy_localization/easy_localization.dart';

/// Channel ID constants and localized channel metadata for Android notifications.
///
/// Extracted from [NotificationService] to keep the main service class
/// within the 300-line file limit.
abstract final class NotificationChannelConfig {
  /// Notification channel ID for egg turning reminders.
  static const eggTurningChannelId = 'egg_turning';

  /// Notification channel ID for incubation milestones.
  static const incubationChannelId = 'incubation';

  /// Notification channel ID for chick care reminders.
  static const chickCareChannelId = 'chick_care';

  /// Notification channel ID for health check reminders.
  static const healthCheckChannelId = 'health_check';

  /// Returns the localized channel name for Android notification settings.
  static String channelName(String channelId) => switch (channelId) {
    eggTurningChannelId => 'notifications.channel_egg_turning_name'.tr(),
    incubationChannelId => 'notifications.channel_incubation_name'.tr(),
    chickCareChannelId => 'notifications.channel_chick_care_name'.tr(),
    healthCheckChannelId => 'notifications.channel_health_check_name'.tr(),
    _ => 'notifications.channel_default_name'.tr(),
  };

  /// Returns the localized channel description for Android notification settings.
  static String channelDescription(String channelId) => switch (channelId) {
    eggTurningChannelId => 'notifications.channel_egg_turning_desc'.tr(),
    incubationChannelId => 'notifications.channel_incubation_desc'.tr(),
    chickCareChannelId => 'notifications.channel_chick_care_desc'.tr(),
    healthCheckChannelId => 'notifications.channel_health_check_desc'.tr(),
    _ => 'notifications.channel_default_desc'.tr(),
  };

  /// Parses a payload string into a route path for deep-link navigation.
  ///
  /// Expected format: `type:id` (e.g. `breeding:abc-123`).
  /// Returns the corresponding GoRouter path or null if unrecognized.
  static String? payloadToRoute(String? payload) {
    if (payload == null || !payload.contains(':')) return null;

    final parts = payload.split(':');
    if (parts.length != 2) return null;

    final type = parts[0];
    final id = parts[1];

    return switch (type) {
      'breeding' || 'incubation' => '/breeding/$id',
      'bird' => '/birds/$id',
      'chick' || 'chick_care' => '/chicks/$id',
      // Egg-related payloads currently carry egg IDs, not pair IDs. Route to
      // breeding list instead of an invalid pair-detail path.
      'egg' || 'egg_turning' => '/breeding',
      'health_check' => '/health-records/$id',
      'event' || 'event_reminder' || 'calendar' => '/calendar',
      'notification' => '/notifications',
      _ => null,
    };
  }
}
