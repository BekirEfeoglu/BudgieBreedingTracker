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

## Quiet Hours (server-side, §5.2)

`send-push` can hold back a recipient's push while they are inside their
quiet-hours window. Pure logic lives in `push_core.ts`
(`isWithinQuietHours` mirrors the client `NotificationRateLimiter`
wraparound; `localHourInZone` resolves the recipient's local hour from their
IANA timezone; `isSuppressedByQuietHours` is **fail-open**). `index.ts` reads
`profiles.quiet_hours` (JSONB `{enabled,startHour,endHour,timeZone}`) and drops
suppressed recipients before token resolution. Suppression is **opt-in**: only
requests with `respectQuietHours: true` are affected, so critical/incubation
notifications (which omit it) are never held back, and any missing/invalid
config delivers. Added 2026-07-03; activation still needs the client to sync
its DND window and callers to opt non-critical notifications in
(`.claude/rules/notifications.md` § Quiet Hours).

## Token Management

- Tokens stored in Supabase `fcm_tokens` table (multi-device)
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

## Local Scheduling (NotificationScheduler)

- `lib/domain/services/notifications/notification_scheduler.dart` — there is no class literally named `IncubationReminderService`
- `tz.TZDateTime` — mandatory (not naive `DateTime`)
- Deterministic IDs via `NotificationIds.generate()` — FNV-1a hash into a partitioned ID space, NOT raw `.hashCode`
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
