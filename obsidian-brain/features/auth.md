# Feature: auth

**Purpose**: User authentication — email/password, Google OAuth, Apple Sign-In, and MFA.

## Key Screens

- Login screen
- Registration screen
- MFA enrollment and challenge screen
- Password reset
- Password recovery deep link and new-password form
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
| Guest / anonymous | Disabled in Supabase and `FeatureFlags`; login CTA hidden |

## Guest Policy

Account-scoped data and RLS have not been approved for Supabase anonymous
users, so `enable_anonymous_sign_ins=false` remains fail-closed. The login
screen passes no guest callback while `FeatureFlags.anonymousSignInEnabled` is
false; `BudgieLoginCard` therefore omits both the CTA and limitation copy
instead of issuing a request that can only fail. Enabling guest access requires
one coordinated server + client rollout with matching contract tests.

## Session Management

- Tokens stored in `FlutterSecureStorage` (encrypted)
- Supabase SDK auto-refreshes tokens 5min before expiry
- Refresh fail → `AuthException` → login redirect
- Logout: revoke OAuth tokens (`revoke-oauth-token` edge fn) + clear session + invalidate providers
- Recovery sessions are held on `/forgot-password` until a new password is
  saved; they are not treated as completed normal sign-ins
- Protected deep links carry a validated local `returnTo` path through login,
  browser/native OAuth, MFA, and splash initialization. Browser OAuth stores
  the target temporarily in `PostAuthDestinationStore` so an app restart does
  not drop the destination; the value is consumed after successful auth.
- Login validates only that the existing password is non-empty. Password
  length and complexity belong to registration/recovery/update flows so
  legacy accounts are not rejected before Supabase authenticates them.

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
