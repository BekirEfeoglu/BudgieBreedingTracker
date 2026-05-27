# Presence Service

Source: `.claude/rules/presence.md` (primary — TTL, heartbeat schedule, privacy visibility modes, multi-device session limit, battery/realtime budget)

**Location**: `lib/domain/services/presence/`

## Responsibility

Tracks per-device session activity in `user_sessions` Supabase table so the
community + messaging UIs can show "online now" indicators and the server
can scope realtime broadcasts. Lifecycle is driven by app foreground /
background events and a heartbeat timer.

## Components

| File | Purpose |
|------|---------|
| `user_presence_service.dart` | Session CRUD via Supabase (`startSession`, `heartbeat`, `endSession`) |
| `user_presence_constants.dart` | `sessionTtl`, heartbeat interval, platform tag |
| `user_presence_providers.dart` | Riverpod controller + lifecycle bridge |

## Session Lifecycle

```
App foreground / login
  ├── startSession(userId)
  │   ├── auth user match guard (RLS preflight)
  │   ├── INSERT user_sessions row (UUID v7, platform, is_active=true, expires_at=now+TTL)
  │   └── returns sessionId — null on auth mismatch or insert failure

Periodic (heartbeat interval)
  └── heartbeat(userId, sessionId)
      └── UPDATE is_active=true, last_active_at=now, expires_at=now+TTL

App background / logout
  └── endSession(userId, sessionId)
      └── UPDATE is_active=false
```

UTC `toIso8601String()` everywhere — naive local timestamps would break
TTL math across timezones (see [[patterns/datetime-format]]).

## Providers

| Provider | Role |
|----------|------|
| `userPresenceServiceProvider` | Singleton service |
| `userPresenceControllerProvider` | Notifier holding active `sessionId` |
| `userPresenceLifecycleProvider` | Listens to auth + lifecycle, drives start/heartbeat/end |

## Auth Guard

Every method early-returns when the Supabase auth user doesn't match the
provided `userId`. Prevents cross-user session pollution if state leaks
between login transitions.

## PII

User ID is logged via `AppLogger.obfuscate(userId)` — never the raw UUID.
Platform name (`ios` / `android` / `web`) is fine to log. Bird/community
data is not part of this service's footprint.

## Anti-Patterns

1. Calling `heartbeat` without `startSession` (no row to update, silent no-op)
2. Storing session ID in SharedPreferences across cold launches (TTL expired, server-side row is stale)
3. Polling presence from UI instead of subscribing to realtime stream
4. Forgetting to `endSession` on logout (server thinks user is still online)
5. Local-clock `expires_at` without `.toUtc()` (TTL drift)

## See Also

- [[features/community]] — online indicator consumer
- [[features/messaging]] — realtime presence
- [[patterns/datetime-format]] — UTC at boundary
- [[domain/services-index]]
