# Feature: auth

**Purpose**: User authentication — email/password, Google OAuth, Apple Sign-In, and MFA.

## Key Screens

- Login screen
- Registration screen
- MFA enrollment and challenge screen
- Password reset
- OAuth redirect handler

## Key Providers

- Auth state provider (wraps Supabase Auth session)
- MFA status provider

## Auth Methods

| Method | Package |
|--------|---------|
| Email/password | Supabase Auth |
| Google OAuth | google_sign_in ^7.2.0 |
| Apple Sign-In | sign_in_with_apple ^8.0.0 |
| MFA (TOTP) | Supabase Auth + `mfa-lockout` Edge Function |

## Session Management

- Tokens stored in `FlutterSecureStorage` (encrypted)
- Supabase SDK auto-refreshes tokens 5min before expiry
- Refresh fail → `AuthException` → login redirect
- Logout: revoke OAuth tokens (`revoke-oauth-token` edge fn) + clear session + invalidate providers

## Startup Init (`appInitializationProvider`)

Gates the splash screen. To keep the splash→home path short, only work a
first render truly needs is awaited before `InitStep.ready`:

- **Awaited (critical path):** MFA check → profile pull (5s timeout, cached
  fallback) → `_initLocalNotifications` (local notification channels + the
  `rateLimiterReadyProvider` DND/rate-limit prefs — a scheduled reminder must
  not fire before these load). Then `ready` + `processPendingPayloads`.
- **Deferred (after `ready`, fire-and-forget microtasks):** FCM token
  registration (`_initPushNotifications` — a ~1s-late token is fine; the
  onTokenRefresh listener is permanent), `_syncAuthMetadataToProfile`
  (display-name backfill, no guard/premium dependency), notification
  reschedule/recovery, and the full data sync. Each self-contains its errors,
  so a deferred failure can't crash startup.

## MFA Lockout Policy

- 5 failed TOTP attempts → lockout
- 7-day inactivity decay before count decrements
- Enforced by `mfa-lockout` Edge Function server-side

## Rules

- `.claude/rules/auth.md` — owning rule: client auth flow, MFA challenge, AAL2 pattern, cooldowns, logout chain
- `.claude/rules/security.md` — policy: secure storage, MFA lockout, OAuth topology
- `.claude/rules/edge-functions.md` — mfa-lockout, revoke-oauth-token

## See Also

- [[features/_features-index]]
- [[patterns/security]]
- [[infrastructure/edge-functions]]
