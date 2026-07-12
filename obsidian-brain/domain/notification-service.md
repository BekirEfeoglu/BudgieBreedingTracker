# Notification Service

Source: `.claude/rules/notifications.md`

**Location**: `lib/domain/services/notifications/notification_service.dart`

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
config delivers. Client DND changes sync to `profiles.quiet_hours`, and manual
admin user/bulk pushes opt in with `respectQuietHours: true`; new non-critical
callers must opt in deliberately (`.claude/rules/notifications.md` § Quiet
Hours).

## Token Management

- Tokens stored in Supabase `fcm_tokens` table (multi-device)
- Token refresh: delete old, register new
- Logout: deactivate ONLY the current device's active token (`deactivateCurrentToken` → `FcmTokenRemoteSource.deactivateToken`) — per-device, not `unregisterAll`; other logged-in devices keep their tokens

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
- Scheduling side effects must await `notificationToggleSettingsReadyProvider.future`
  before passing settings to `NotificationScheduler`; direct synchronous reads
  can use default `true` values before Drift-backed settings load.
- `NotificationRescheduler` loads the user's persisted settings via
  `NotificationSettingsDao.getByUser()` and passes the snapshot to every
  incubation, egg, chick-care, and banding schedule call.
- Local background notification taps are persisted first and restored through
  `NotificationService.restorePendingBackgroundTapPayloads()` so payloads are
  not lost before the router is ready.

## Permission Flow

- No first-launch prompt. Permission starts as unknown/false in
  `notificationPermissionGrantedProvider` until the platform status is checked.
- `NotificationSettingsScreen` refreshes status without prompting.
- Explicit CTA uses `notificationPermissionRequestControllerProvider`; if the
  user still denies permission, app notification settings are opened where
  supported.

## Channels / Categories

| ID | Purpose | Importance |
|----|---------|-----------|
| `incubation` | Hatch reminders | High |
| `breeding` | Breeding events | Default |
| `marketplace` | Listing matches | High |
| `community` | Mentions, replies | Default |
| `system` | Maintenance | Low |
| `streak` | Smart daily-streak reminder | Default |

`streak` (shipped 2026-07-12): `StreakReminderScheduler` re-schedules a single
next-day 20:00-local reminder after every check-in call, only when the
`streakReminder` toggle is on (opt-out, not in `allEnabled`) and the current
streak is `>= 3`. See [[domain/gamification-service]] § Daily Streak.

## Current Decisions

- Permission is never requested on first launch; explicit CTAs own the prompt.
- Local scheduling must wait for persisted toggle settings before scheduling.
- Quiet hours are opt-in on push requests via `respectQuietHours: true`.
- Background notification taps are persisted and restored after router readiness.

## Known Deferred Work

- New non-critical push callers must deliberately opt into quiet-hours suppression.
- DM attachment storage is not wired here; notification payloads should not assume it.
- Platform-specific permission edge cases should stay behind `NotificationPermissionHandler`.

## Do Not Reintroduce

- Do not navigate automatically from foreground push notifications.
- Do not use raw `DateTime` for scheduled notifications.
- Do not rely on Dart `hashCode` for notification IDs.
- Do not read default toggle values synchronously before Drift settings load.
- Do not "fix" logout to `unregisterAll` / delete-all-device-tokens — per-device
  `deactivateCurrentToken` is intentional so other logged-in devices keep push.

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
