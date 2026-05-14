# Feature: notifications

**Purpose**: Notification permission settings, category preferences, quiet hours.

## Key Screens

- Notification settings screen

## Key Providers

- `notificationPermissionProvider` — tracks permission state
- Category enable/disable preferences stored in `profile.notification_preferences`

## Notification Channels (Android) / Categories (iOS)

| ID | Purpose | Importance |
|----|---------|-----------|
| `incubation` | Hatching reminders | High |
| `breeding` | Breeding events | Default |
| `marketplace` | Listing matches | High |
| `community` | Mentions, replies | Default |
| `system` | Maintenance, updates | Low |

## Permission Flow

- Never request on first launch without context
- Request at feature touchpoint ("Kuluçka hatırlatması için izin gerekli")
- If denied, show Settings deeplink

## See Also

- [[domain/notification-service]]
- [[features/_features-index]]
- [[patterns/empty-loading-error-states]]
