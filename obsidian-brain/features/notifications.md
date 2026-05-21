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
| `notificationPermissionProvider` | `permission_handler` state |
| Notification list providers | `notification_list_providers.dart` (Drift + remote pull) |
| Settings providers | `notification_settings_providers.dart` (per-category toggles, DND window, master switch) |
| Action feedback providers | `action_feedback_providers.dart` (post-tap UX, success/error toast) |

## Channels / Categories

| ID | Purpose | Importance |
|----|---------|------------|
| `incubation` | Hatching reminders, egg turning | High |
| `breeding` | Breeding events | Default |
| `marketplace` | Listing matches | High |
| `community` | Mentions, replies | Default |
| `system` | Maintenance, updates | Low |

Channel definitions live in [[domain/notification-service]] (`notification_service.dart`).

## Permission Flow

Two-pass:

1. **First touchpoint** in a feature flow asks ("Kuluçka hatırlatması için
   izin gerekli") — never on first launch.
2. If permanently denied, render a Settings deeplink CTA via
   `permission_handler.openAppSettings()`.

UI surfaces in `notification_settings_banners.dart` (denied / not-determined
banner) so the user can react from the settings screen too.

## DND / Quiet Hours

`notification_settings_dnd.dart` exposes a start/end time picker with
weekday selection. Server-side `send-push` Edge Function checks the
user's window and skips delivery during quiet hours — local
notifications respect the same window via scheduling guards.

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
