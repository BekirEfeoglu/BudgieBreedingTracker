# Observability

Source: `.claude/rules/observability.md`

## Stack

| Layer | Tool | Purpose |
|-------|------|---------|
| Structured log | `AppLogger` | Development + production debug traces |
| Error tracking | Sentry `sentry_flutter ^9.0.0` | Production error capture, breadcrumb, performance |
| Edge function log | Supabase Dashboard | Server-side traces |

## AppLogger API

```dart
AppLogger.debug(tag, message);                  // Dev only — hidden in production
AppLogger.info(tag, message);                   // Operational
AppLogger.warning(message);                     // Degraded state
AppLogger.error(message, error, stackTrace);    // Auto Sentry breadcrumb
```

**Tag convention**: source class name — `'BirdRepository'`, `'SyncService'`

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

## Anti-Patterns

1. `print()` (anti-pattern #10)
2. Bare `catch (e)` without log/Sentry (#22, #23)
3. PII to Sentry (password, token, email in production)
4. Validation errors to Sentry (noise)
5. `AppLogger.error` without `stackTrace` parameter
6. Not clearing Sentry user scope on logout

## See Also

- [[patterns/error-handling]] — exception hierarchy
- [[patterns/security]] — PII protection
