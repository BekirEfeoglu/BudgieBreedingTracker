# Feature: profile

**Purpose**: User-facing account: display name, avatar, password, MFA,
security score, basic stats. Settings live next door (see
[[features/settings]]) — profile owns who-you-are, settings owns
how-the-app-behaves.

## Key Screens

| Screen | Route |
|--------|-------|
| `ProfileScreen` | `AppRoutes.profile` — single-page view + inline edit |

Sub-flows (MFA setup, password change, avatar pick) open as bottom sheets
or routed sub-screens (`twoFactorSetup`, `twoFactorVerify`).

## Key Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `userProfileProvider` | `StreamProvider` | Live profile from Drift |
| `avatarUploadStateProvider` | `NotifierProvider<AvatarUploadNotifier, …>` | Upload pipeline state |
| `passwordChangeStateProvider` | `NotifierProvider<PasswordChangeNotifier, …>` | Password change state |
| `profileStatsProvider(userId)` | `Provider.family<AsyncValue<ProfileStats>, …>` | Aggregated counts (birds, pairs, chicks) |
| `securityScoreProvider(userId)` | `Provider.family<SecurityScore, …>` | Per-factor score (MFA, recent password, verified email, …) |
| `isTwoFactorEnabledProvider` | `FutureProvider<bool>` | MFA status |

## Avatar Upload

Pipeline (`avatar_picker_sheet.dart` → `AvatarUploadNotifier` →
`ProfileRepository.uploadAvatar` → `StorageService`):

1. `ImagePicker` with `maxWidth/maxHeight: 512`, `imageQuality: 80` (downscale
   happens at pick time; every upload surface owns its own picker limits)
2. 2 MB avatar guard (rejects before network; matches the safety-scan cap)
3. Upload to the **`avatars`** Supabase Storage bucket (path
   `avatars/{userId}/avatar.{ext}`, RLS user-scoped). `StorageService` holds an
   optional `ImageSafetyService` for uploads (see [[domain/moderation-service]]).
4. Save URL to Drift profile + mark sync pending → `CachedNetworkImage`
   invalidated on URL change

The picker sheet captures the root `ScaffoldMessenger` **before** popping
itself. The old code kept the sheet's own context and re-checked `.mounted`
after the async pick — always false post-pop — so the upload was skipped and
a validly-picked avatar was never uploaded (and picker errors were swallowed);
fixed 2026-07-02 via `ImagePickerGuard.ensureWithinSizeLimitVia`.

## Security Score

`SecurityScore` is the sum of per-factor scores:

- MFA enabled
- Recent password rotation
- Verified email
- No active recovery codes left unused (encourages key storage)

UI renders a 0–100 score + per-factor hints. Score isn't sent to the
server — it's purely a local nudge.

## Account Deletion

CTA lives in Settings, not Profile (see [[features/settings]]). Orchestrated by
`AccountDeletionController` (`account_deletion_providers.dart`), NOT a grace
period. Fixed step order (destructive, irreversible after the RPC):

1. Verify current password
2. `requireAal2ForDestructiveAction()` — if MFA is enrolled, an AAL2 challenge
   is required (`MfaAssuranceRequiredException` → challenge dialog →
   `completeAfterMfaChallenge()`)
3. Storage cleanup — `accountStorageCleanupProvider.deleteAllUserFiles(userId)`
   (this provider is one step, not the whole flow)
4. OAuth token revoke (best-effort, `revoke-oauth-token`)
5. RPC `requestAccountDeletionForVerifiedSession()` → deletes `auth.users`
6. Local `clearAllUserData(userId)` + full SharedPreferences wipe
7. Sign out all sessions (best-effort)

The guard is password + AAL2 — there is no type-to-confirm here (that pattern is
admin-panel destructive actions, see [[features/admin]]).

## Online-First

Profile reads from Drift but writes hit Supabase first (Supabase profile
table is the source of truth across devices). `profileSyncProvider`
in Home refreshes Drift on resume.

## L10n

Keys under `profile.*` and `auth.*` (for MFA flows).

## See Also

- [[features/settings]] — theme, backup, account deletion CTA
- [[features/auth]] — MFA verify, OAuth providers
- [[patterns/assets-images]] — avatar upload pipeline
- [[features/_features-index]]
