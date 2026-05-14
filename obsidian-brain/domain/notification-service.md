# Notification Service

Source: `.claude/rules/notifications.md`

**Location**: `lib/data/services/notification_service.dart`, `lib/domain/services/`

## Two Channels

| Type | Package | Trigger |
|------|---------|---------|
| Push (remote FCM) | `firebase_messaging` | Server → `send-push` Edge Function |
| Local (scheduled) | `flutter_local_notifications` | Device schedule API |

## FCM Flow

```
Domain event (egg hatching, marketplace sale)
  → send-push Edge Function (JWT, batch 500 tokens)
  → FCM → devices
  → App handles foreground/background/terminated
```

## Token Management

- Tokens stored in Supabase `user_fcm_tokens` table (multi-device)
- Token refresh: delete old, register new
- Logout: delete all device tokens

## Foreground / Background / Terminated

| State | Handler | UI |
|-------|---------|-----|
| Foreground | `FirebaseMessaging.onMessage` | In-app banner (no auto-navigate) |
| Background | `FirebaseMessaging.onMessageOpenedApp` | Navigate via deeplink |
| Terminated | `getInitialMessage()` on start | Navigate after splash |

## Deeplink Payload

```json
{ "type": "egg_hatching", "entity_id": "uuid", "route": "/eggs/uuid" }
```

Validate type before navigating. Unknown type → `AppLogger.warning` + home fallback.

## Local Scheduling (IncubationReminderService)

- `tz.TZDateTime` — mandatory (not naive `DateTime`)
- Deterministic IDs: `'egg_${eggId}_day_${day}'.hashCode`
- Cancel + reschedule on insert/update

## Channels / Categories

| ID | Purpose | Importance |
|----|---------|-----------|
| `incubation` | Hatch reminders | High |
| `breeding` | Breeding events | Default |
| `marketplace` | Listing matches | High |
| `community` | Mentions, replies | Default |
| `system` | Maintenance | Low |

## Anti-Patterns

1. Requesting permission on first launch without context
2. Not cleaning FCM tokens on logout (old account gets notifications)
3. Navigating on foreground notification (interrupts user)
4. Using naive `DateTime` for schedule (timezone bug)

## See Also

- [[features/notifications]]
- [[infrastructure/edge-functions]] — send-push
- [[patterns/datetime-format]] — tz.TZDateTime
- [[domain/services-index]]
