# Auth Service

Source: `.claude/rules/auth.md`, `.claude/rules/security.md`

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
3. Deactivate this device's FCM token (`PushNotificationService.deactivateCurrentToken` → `FcmTokenRemoteSource.deactivateToken`, `lib/data/remote/api/fcm_token_remote_source.dart`) — per-device, not all tokens
4. Clear local Sentry user scope
5. Invalidate all providers
6. Navigate to auth
```

## MFA

- TOTP enrollment via Supabase Auth
- Lockout: 5 failed attempts → `mfa-lockout` Edge Function
- 7-day decay window before lockout count decrements
- **Recovery codes — shipped (2026-07-09):** `RecoveryCodeService`
  (`lib/domain/services/auth/recovery_code_service.dart`) generates 10
  single-use codes at 2FA enrollment, shown to the user ONCE and stored only as
  SHA-256 hashes (`mfa_recovery_codes` table, own-scope RLS). The login 2FA
  verify screen's "use a recovery code" path calls the
  `redeem_mfa_recovery_code` RPC: it verifies the hash, marks the code used, and
  server-side deletes the user's `auth.mfa_factors` rows (an AAL1 user cannot
  delete their own verified factor, so the real work is a `private`
  `SECURITY DEFINER` function behind a `public` `SECURITY INVOKER` wrapper). MFA
  is disabled, AAL1 login completes, and the user is routed to re-enroll. Client
  normalization (strip non-alnum + upper) must match the SQL normalization
  exactly. Migrations `20260709115154` + `20260709115445`.

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
