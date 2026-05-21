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
| `currentUserProfileProvider` | `StreamProvider` | Live profile from Drift |
| `avatarUploadStateProvider` | `NotifierProvider<AvatarUploadNotifier, …>` | Upload pipeline state |
| `passwordChangeStateProvider` | `NotifierProvider<PasswordChangeNotifier, …>` | Password change state |
| `profileStatsProvider(userId)` | `Provider.family<AsyncValue<ProfileStats>, …>` | Aggregated counts (birds, pairs, chicks) |
| `securityScoreProvider(userId)` | `Provider.family<SecurityScore, …>` | Per-factor score (MFA, recent password, verified email, …) |
| `isTwoFactorEnabledProvider` | `FutureProvider<bool>` | MFA status |

## Avatar Upload

Pipeline (full details in [[patterns/assets-images]]):

1. `ImagePicker` → local file
2. 10 MB guard (rejects before network)
3. Compress to 1920px / JPEG q85
4. `scan-image-safety` Edge Function (fail-closed)
5. Upload to `bird-photos` Supabase Storage bucket (RLS user-scoped)
6. `CachedNetworkImage` cache invalidated on URL change

## Security Score

`SecurityScore` is the sum of per-factor scores:

- MFA enabled
- Recent password rotation
- Verified email
- No active recovery codes left unused (encourages key storage)

UI renders a 0–100 score + per-factor hints. Score isn't sent to the
server — it's purely a local nudge.

## Account Deletion

CTA lives in Settings, not Profile (see [[features/settings]]). The
multi-step confirm + grace period is handled by
`account_storage_cleanup_provider.dart` (domain/profile service).

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
