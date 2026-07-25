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
  → send-push Edge Function (JWT)
  → tokens deduped + clamped to MAX_TOKENS = 500 (total recipient cap)
  → sent to FCM REST in groups of BATCH_SIZE = 50 (push_core.ts)
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

The payload is a single `'<type>:<id>'` **string**, not a JSON object, and it
carries no `route` — the route is derived client-side by
`NotificationChannelConfig.payloadToRoute`.
`PushNotificationService._payloadFromMessage` builds it from FCM `data`:
`data['payload']` verbatim if present, otherwise
`'${type|reference_type}:${entity_id|related_entity_id|reference_id|id}'`
(null if either half is missing).

Real schedulers emit `incubation:<id>`, `egg_turning:<id>`, `chick_care:<id>`,
`banding:<id>`, `health_check:<birdId>`, `streak:reminder`.

Mapping: `breeding|incubation → /breeding/<id>` · `bird → /birds/<id>` ·
`chick|chick_care|banding → /chicks/<id>` · `egg|egg_turning → /breeding`
(id intentionally dropped — these carry an egg id, not a pair id, and no
`/eggs/<id>` route exists) · `health_check → /health-records/<id>` ·
`event|event_reminder|calendar → /calendar` · `notification → /notifications` ·
anything else → `null`.

Ids destined for a path segment are validated with `isValidRouteId`; an invalid
id rejects the payload (`AppLogger.warning`) so a crafted payload cannot flash a
NotFound screen. Unknown type → `null`, no navigation.

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

Single source: `NotificationChannelConfig`
(`lib/domain/services/notifications/notification_channel_config.dart`) — five
declared constants plus the literal `'default'` produced by its `_ =>` branch.

| ID | Constant | Used by |
|----|----------|---------|
| `egg_turning` | `eggTurningChannelId` | `NotificationScheduler` egg-turning reminders |
| `incubation` | `incubationChannelId` | `NotificationScheduler` incubation milestones |
| `chick_care` | `chickCareChannelId` | Chick care/weighing + banding reminders |
| `health_check` | `healthCheckChannelId` | Health-record follow-up reminders |
| `streak` | `streakChannelId` | `StreakReminderScheduler` |
| `default` | (literal) | `NotificationProcessor` fallback for unmapped types |

There are **no** `breeding` / `marketplace` / `community` / `system` channels —
those were a design target, never built.

**No per-channel importance.** The repo contains no `AndroidNotificationChannel`
construction at all; channels are created implicitly at post time from
`AndroidNotificationDetails`, and `NotificationService._buildNotificationDetails`
hardcodes `importance: Importance.high` + `priority: Priority.high` for every
channel. Differentiated importance would require adding real channel creation
first (Android will not let code lower an already-created channel's importance).

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
