/// Re-exports commonly cross-imported notification settings providers.
///
/// The implementation lives in the domain notification service layer.
library;
export 'package:budgie_breeding_tracker/domain/services/notifications/notification_settings_providers.dart'
    show
        NotificationToggleSettingsNotifier,
        notificationToggleSettingsProvider;

export 'package:budgie_breeding_tracker/domain/services/notifications/notification_toggle_settings.dart'
    show NotificationToggleSettings;
