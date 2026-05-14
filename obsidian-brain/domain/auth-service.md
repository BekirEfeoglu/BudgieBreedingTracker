# Auth Service

Source: `.claude/rules/security.md`

**Location**: `lib/domain/services/` (auth) + Supabase Auth SDK

## Responsibilities

- Email/password login + registration
- Google OAuth + Apple Sign-In
- MFA enrollment and challenge
- Session token storage and refresh
- Logout (token revocation + session clear)

## Session Storage

```dart
// Supabase SDK handles session storage in FlutterSecureStorage
// Access stored in iOS Keychain / Android EncryptedSharedPreferences
```

## Session Refresh

- Auto-refresh by Supabase SDK (5min before expiry)
- Refresh fail → `AuthException` → login redirect
- Offline: local session used, refresh on reconnect

## Logout Flow

```
1. Revoke OAuth token (revoke-oauth-token Edge Function)
2. Supabase signOut()
3. Delete all FCM tokens (FCMTokenService.unregisterAll())
4. Clear local Sentry user scope
5. Invalidate all providers
6. Navigate to auth
```

## MFA

- TOTP enrollment via Supabase Auth
- Lockout: 5 failed attempts → `mfa-lockout` Edge Function
- 7-day decay window before lockout count decrements
- Recovery codes: generated at enrollment, shown once

## Secure Storage Rules

| Item | Storage |
|------|---------|
| Session token | Secure storage (Supabase SDK) |
| Refresh token | Secure storage |
| User preferences | SharedPreferences (OK) |
| FCM token | Supabase DB |

**Never** store tokens in SharedPreferences.

## See Also

- [[features/auth]]
- [[patterns/security]]
- [[infrastructure/edge-functions]] — mfa-lockout, revoke-oauth-token
- [[domain/services-index]]
