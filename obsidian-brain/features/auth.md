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

## MFA Lockout Policy

- 5 failed TOTP attempts → lockout
- 7-day inactivity decay before count decrements
- Enforced by `mfa-lockout` Edge Function server-side

## Rules

- `.claude/rules/security.md` — full auth details
- `.claude/rules/edge-functions.md` — mfa-lockout, revoke-oauth-token

## See Also

- [[features/_features-index]]
- [[patterns/security]]
- [[infrastructure/edge-functions]]
