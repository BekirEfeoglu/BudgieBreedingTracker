# Feature: notifications

**Purpose**: In-app notification inbox, push/local notification settings,
category preferences, quiet hours / do-not-disturb. The user's control
surface for what the app can interrupt them about.

## Key Screens

| Screen | Route |
|--------|-------|
| `NotificationListScreen` | `AppRoutes.notifications` — inbox of received notifications |
| `NotificationSettingsScreen` | `AppRoutes.notificationSettings` — preferences + DND |

## Providers

| Provider | Source |
|----------|--------|
| `notificationPermissionGrantedProvider` | Platform notification permission state |
| Notification list providers | `notification_list_providers.dart` (Drift + remote pull) |
| Settings providers | `notification_settings_providers.dart` (per-category toggles, DND window, master switch, scheduling-ready snapshot) |
| Action feedback providers | `action_feedback_providers.dart` (post-tap UX, success/error toast) |

## Channels / Categories

| ID | Purpose |
|----|---------|
| `egg_turning` | Egg-turning reminders |
| `incubation` | Incubation milestones |
| `chick_care` | Chick care/weighing + banding |
| `health_check` | Health-record follow-ups |
| `streak` | Smart daily-streak reminder |
| `default` | Fallback for unmapped notification types |

No `breeding` / `marketplace` / `community` / `system` channel exists (design
target, never built), and there is no per-channel importance — every
notification posts with `Importance.high` (no `AndroidNotificationChannel` is
ever constructed). IDs are declared in `NotificationChannelConfig`
(`lib/domain/services/notifications/notification_channel_config.dart`); see
[[domain/notification-service]] § Channels / Categories.

## Permission Flow

Two-pass:

1. **First touchpoint** in a feature flow asks ("Kuluçka hatırlatması için
   izin gerekli") — never on first launch.
2. If permanently denied, render a Settings deeplink CTA via
   `NotificationPermissionHandler.openNotificationSettings()`.

UI surfaces in `notification_settings_banners.dart` (denied / not-determined
banner) so the user can react from the settings screen too. The settings screen
refreshes platform status without prompting; explicit CTA calls
`notificationPermissionRequestControllerProvider`.

## Scheduling Preferences

Feature flows that create local notifications must await
`notificationToggleSettingsReadyProvider.future` before scheduling. This keeps
saved disabled categories from being bypassed by the provider's initial default
state. Startup/reboot rescheduling uses the same persisted settings snapshot
through `NotificationRescheduler`.

## DND / Quiet Hours

`notification_settings_dnd.dart` exposes a start/end time picker with
weekday selection. Changes are written to the local rate limiter and
`profiles.quiet_hours`; server-side `send-push` checks that window for opt-in
requests and skips delivery during quiet hours. Local notifications respect the
same window via scheduling guards.

## Inbox

`NotificationCard` renders a single received notification with:

- Category icon + l10n title
- Action button (deeplink to entity)
- Read/unread state — read receipt persists to Supabase

`NotificationBellButton` (top-bar widget) shows an unread count badge
sourced from `notification_list_providers`.

## Anti-Patterns

See [[domain/notification-service]] §"Anti-Patterns" — covered by the
canonical rule.

## See Also

- [[domain/notification-service]] — channel setup, FCM, schedule helpers
- [[infrastructure/edge-functions]] — `send-push`
- [[patterns/datetime-format]] — tz.TZDateTime
- [[features/_features-index]]
