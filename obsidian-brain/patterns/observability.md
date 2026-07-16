# Observability

Source: `.claude/rules/observability.md`

## Stack

| Layer | Tool | Purpose |
|-------|------|---------|
| Structured log | `AppLogger` | Development + production debug traces |
| Error tracking | Sentry `sentry_flutter ^9.0.0` | Production error capture, breadcrumb, performance |
| Edge function log | Supabase Dashboard | Server-side traces |

## AppLogger API

All methods take a SINGLE `message` string — there is no separate `tag` parameter:

```dart
AppLogger.debug(message);                       // Dev only — hidden in production
AppLogger.info(message);                        // Operational
AppLogger.warning(message);                     // Degraded state
AppLogger.error(message, error, stackTrace);    // Auto Sentry breadcrumb
```

**Source convention**: `[Bracket]` prefix embedded in the message —
`AppLogger.warning('[SyncOrchestrator] retry attempt failed')`

## Sentry Sample Rate Budget

| Environment | tracesSampleRate | replaysSessionSampleRate |
|-------------|-----------------|--------------------------|
| development | 1.0 | 0.0 |
| staging | 0.5 | 0.1 |
| production | 0.1 | 0.0 (cost) |

`errorSampleRate = 1.0` always — all errors captured regardless of trace sampling.

Selected via `SENTRY_ENVIRONMENT` dart-define.

## PII Rules

- **Never log**: password, token, MFA code, refresh token
- Email: debug only, mask in Sentry production scope
- Phone, birth date, location: redact
- Bird/egg data in Sentry: ID only — not user's private breeding data
- Payment info: never in local log or Sentry
- AI prompts: never in Sentry (privacy + storage cost)

## Sentry User Context

```dart
// After login
Sentry.configureScope((s) => s.setUser(SentryUser(id: userId)));

// After logout — MUST clear
Sentry.configureScope((s) => s.setUser(null));
```

## Sentry Tags

- `feature`: module name (`birds`, `genetics`, `sync`)
- `sync_phase`: `pull` / `push` / `merge`
- `entity_type`: `bird` / `egg` / `chick`
- `network`: `online` / `offline`
- `auth_method`: `email` / `google` / `apple`

## Edge Function Log Format

```json
{
  "ts": "2026-05-14T10:00:00Z",
  "level": "info",
  "event": "sync_completed",
  "user_id": "uuid",
  "entity_type": "birds",
  "duration_ms": 142
}
```

Event names: snake_case dictionary (`sync_started`, `sync_completed`, `auth_login`, `mfa_lockout`)

## Breadcrumb Budget Protection

`AppLogger.warning` always attaches a Sentry breadcrumb, even in release
builds (unlike `debug`, which only does in non-release). Sentry keeps ~100
breadcrumbs — a loop that logs `.warning` on every retry (e.g. a realtime
subscription the underlying SDK reconnects indefinitely with no cap from
caller code) can fully displace useful context before a real crash is
captured. `RealtimeErrorLogThrottle`
(`lib/core/utils/realtime_error_log_throttle.dart`) caps consecutive
`.warning` calls (default 5, matching `RealtimeSyncService.maxReconnectFailures`)
then drops to `.debug` — one instance per subscription. The reset/log policy
lives in the shared `handleRealtimeSubscribeStatus`
(`lib/data/remote/api/realtime_subscribe_status_handler.dart`): reset the budget
ONLY on `subscribed`; log (throttled) on `channelError`/`timedOut`; ignore the
transient `closed`. The SDK reports `closed`/`timedOut` with a null error
mid-reconnect, so the earlier `reset()`-on-any-null-error cleared the budget
between every `channelError`, defeating the cap entirely (2026-07-05 fix). Used
by `EventRemoteSource.subscribeToEvents` and
`CommunityPostRemoteSource.subscribeToPostChanges` (2026-07-02, iOS Simulator
`EADDRNOTAVAIL` reconnect-storm finding).

## Filtered Sentry Reporting

Not every caught error should reach Sentry. The shared exclusion set —
`FreeTierLimitException`, `ValidationException`, `NetworkException` (offline is an
expected user condition) — lives in one predicate `isExpectedSentryExclusion`
(`lib/core/utils/sentry_error_filter.dart`), mirroring
`base_repository.reportPullFailure` and § "Sentry'ye GİTMEYEN olaylar" of the
rule. Two entry points share it:

- `SentryErrorFilter` mixin → `reportIfUnexpected(error, st)` for Notifiers
  (`sendToSentry` is split out for test override).
- `reportUnexpectedToSentry(error, st)` top-level function for non-Notifier call
  sites (widgets, services) — e.g. the bird photo add/delete storage catches and
  the `createBird` inner photo-upload catch, which report genuinely unexpected
  storage/DB failures instead of only logging.

## Anti-Patterns

1. `print()` (anti-pattern #10)
2. Bare `catch (e)` without log/Sentry (#22, #23)
3. PII to Sentry (password, token, email in production)
4. Validation errors to Sentry (noise)
5. `AppLogger.error` without `stackTrace` parameter
6. Not clearing Sentry user scope on logout
7. Unthrottled `.warning` in a retry loop (breadcrumb budget exhaustion)

## See Also

- [[patterns/error-handling]] — exception hierarchy
- [[patterns/security]] — PII protection
