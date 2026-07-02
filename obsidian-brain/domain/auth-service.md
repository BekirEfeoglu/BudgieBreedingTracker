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
3. Delete all FCM tokens (`FcmTokenRemoteSource`, `lib/data/remote/api/fcm_token_remote_source.dart`)
4. Clear local Sentry user scope
5. Invalidate all providers
6. Navigate to auth
```

## MFA

- TOTP enrollment via Supabase Auth
- Lockout: 5 failed attempts → `mfa-lockout` Edge Function
- 7-day decay window before lockout count decrements
- **Recovery codes do not exist (2026-07-02 audit):** `TwoFactorService` has
  no `generateRecoveryCodes` method, no recovery-code UI step in either 2FA
  screen, and no l10n keys reference them. A user who loses their
  authenticator device has no self-service recovery path today — this was a
  design target documented here and in `.claude/rules/security.md`, not
  shipped behavior.

## Destructive-Action Re-Authentication (changePassword / account deletion)

`_AuthAccountMixin.changePassword`/`requestAccountDeletionForVerifiedSession`
re-check AAL2 via `_requireAal2IfEnrolled()`. Re-authenticating with a
password (`signInWithPassword`) always resets an MFA-enrolled session back
to AAL1, so a naive "check → reauth → check again" sequence always throws
`MfaAssuranceRequiredException` on the second check for every MFA-enrolled
user — this was a real bug (fixed 2026-07-02) that permanently blocked
password change and account deletion for exactly the security-conscious
users who enabled 2FA. Account deletion had a second, more severe form of
the same bug: `AccountDeletionController.deleteAccount` ran storage-file
cleanup *before* the AAL2 check, so an MFA user could lose all their photos
without the deletion actually completing.

Fix pattern: `changePasswordForVerifiedSession` /
`requestAccountDeletionForVerifiedSession` skip the password re-auth (call
only after the caller has independently re-established AAL2). The UI layer
catches `MfaAssuranceRequiredException`, shows `showMfaChallengeDialog`
(`lib/features/auth/widgets/mfa_challenge_dialog.dart`, exposed via
`lib/shared/widgets/auth.dart`) to re-verify a TOTP challenge
(`TwoFactorService.challengeAndVerify` — this alone re-establishes AAL2, no
second password prompt needed), then retries via the "for verified session"
variant. `AccountDeletionController` now calls
`requireAal2ForDestructiveAction()` immediately after password verification
and *before* any destructive step, so an MFA session that can't complete
the flow fails before touching data, not partway through.

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
