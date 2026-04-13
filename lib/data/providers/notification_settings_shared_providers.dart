/// Re-exports commonly cross-imported notification settings providers.
///
/// The full notification settings implementation remains in
/// `lib/features/notifications/providers/notification_settings_providers.dart`.
/// This file exists so other features can import notification settings
/// without creating cross-feature import violations.
export 'package:budgie_breeding_tracker/features/notifications/providers/notification_settings_providers.dart'
    show
        NotificationToggleSettingsNotifier,
        notificationToggleSettingsProvider;

export 'package:budgie_breeding_tracker/domain/services/notifications/notification_toggle_settings.dart'
    show NotificationToggleSettings;
