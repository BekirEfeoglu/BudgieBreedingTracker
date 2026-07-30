# Presence Service

Source: `.claude/rules/presence.md` (primary — TTL, heartbeat schedule, battery budget; privacy visibility modes are UNSHIPPED design targets, see [[known-gaps]])

**Location**: `lib/domain/services/presence/`

## Responsibility

Tracks per-device session activity and installed app builds in the
`user_sessions` Supabase table. **The only shipped consumer is the admin
panel** (online-user visibility and build adoption) — community/messaging "online now" badges are
unshipped design targets ([[known-gaps]]). Lifecycle is driven by app
foreground / background events and a heartbeat timer.

## Components

| File | Purpose |
|------|---------|
| `user_presence_service.dart` | Session lifecycle + auth-match guard (`startSession`, `heartbeat`, `endSession`) — depends on `UserPresenceRemoteSource`, never touches `SupabaseClient` directly |
| `user_presence_constants.dart` | `sessionTtl`, heartbeat interval, platform tag |
| `user_presence_providers.dart` | Riverpod controller + lifecycle bridge |

`data/remote/api/user_presence_remote_source.dart` holds the actual
`client.from(SupabaseConstants.userSessionsTable)` calls (architecture.md
Import Rules boundary — a domain service must not call `client.from()`
directly). Not a `BaseRemoteSource<T>` subclass: presence rows are transient
key-value writes with no Freezed model, offline mirror, or sync lifecycle.

## Session Lifecycle

```
App foreground / login
  ├── startSession(userId)
  │   ├── auth user match guard (RLS preflight)
  │   ├── read package metadata (fail-open)
  │   ├── UPSERT user_sessions row (UUID v7, platform, app_version=version+build, is_active=true, expires_at=now+TTL)
  │   └── returns sessionId — null on auth mismatch or write failure

Periodic (heartbeat interval)
  └── heartbeat(userId, sessionId)
      └── UPDATE is_active=true, last_active_at=now, expires_at=now+TTL

App background / logout
  └── endSession(userId, sessionId)
      └── UPDATE is_active=false
```

`startSession` upserts (not inserts): `sessionId` is a fresh client-generated
`v7()` UUID per call, so `id` never collides across calls today, but upsert
matches data-layer.md's blanket Write Safety rule and protects a future
caller-level retry that reuses the same `sessionId`.

`app_version` is nullable for legacy clients. Package metadata failures do not
block presence; the admin rollup reports versioned/total coverage separately.

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

- [[features/admin]] — the only shipped presence consumer (online-user visibility)
- [[features/messaging]] — typing indicator (messaging-owned, not presence)
- [[known-gaps]] — visibility modes + user-facing badges (unshipped)
- [[patterns/datetime-format]] — UTC at boundary
- [[domain/services-index]]
