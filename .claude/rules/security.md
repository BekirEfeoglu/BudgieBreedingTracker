# Security

## Authentication & Authorization
- Auth managed by Supabase Auth (email/password, Google OAuth, Apple Sign-In)
- MFA (TOTP) available — `mfa-lockout` Edge Function handles brute-force
- Session tokens stored in secure storage, never in SharedPreferences
- Auth state managed via Riverpod provider, reactive across app

### Google Sign-In OAuth Topology (migrating to single-project)

**State as of 2026-05-26**: mid-migration. OAuth clients now exist in BOTH the legacy GCP project (number `118599620356`) AND the Firebase project (`budgiebreedingtracker-12072`, number `720334450619`). Supabase Auth Google provider is configured with both Web Client IDs in its comma-separated list, so ID tokens from old AND new binaries are both accepted — no breaking transition.

| Layer | Identifier |
|-------|------------|
| Firebase project | `budgiebreedingtracker-12072` (project number `720334450619`) — owns FCM, Crashlytics, google-services.json/GoogleService-Info.plist, NEW OAuth clients (consent screen "In production", basic scopes only, no verification needed). |
| Legacy OAuth project | Separate GCP project, project number `118599620356`. Still hosts the OAuth client that older binaries reference. Do NOT delete until binary traffic drops to ~0 (see future-state below). |

**New iOS Client ID**: `720334450619-oacalc9gn0sg986d16it34jr4th6bkf4.apps.googleusercontent.com` (reversed: `com.googleusercontent.apps.720334450619-oacalc9gn0sg986d16it34jr4th6bkf4`). Bundle `com.budgiebreeding.tracker`, App Store ID `6759828211`, Team `GKFR8WRJR7`.

**New Web Client ID**: `720334450619-kvo5m738euj98t4qmmqeabmmd48ma0tl.apps.googleusercontent.com` (redirect URI: `https://lmqkwgitzvpacycujzgc.supabase.co/auth/v1/callback`). Web Client Secret is stored only in Supabase Edge Function secrets / RC dashboard, never in this repo.

**App code state**: `ios/Runner/Info.plist` `CFBundleURLSchemes` and `.env.example` updated to the NEW iOS reversed client ID. `GOOGLE_*_CLIENT_ID` env vars need to be set to the new values in local `.env`, Codemagic env groups, and any GitHub Actions secrets BEFORE the next signed release build. Old binaries still installed on user devices continue to use the legacy project's IDs (compiled in at build time) and Supabase accepts both audiences during the rollout window.

The Android SHA-1 fingerprint `4b:50:9f:a3:...` shows a duplicate-registration warning in Firebase because that fingerprint is registered against BOTH OAuth clients (legacy + new). **Do not delete it from Firebase** — it is the production app signature for both clients during the migration.

**Future-state cleanup** (only when ALL of these are true):
1. New signed binary shipped to App Store + Play
2. >90% of active users have updated to the new binary (check via Sentry tag or Supabase auth audit logs filtered by issuer)
3. Old binary traffic against the legacy Web Client ID is ~0 for 14 consecutive days

Then:
- Remove the legacy Web Client ID from Supabase Auth's "Client IDs" comma-separated list
- Optionally delete the OAuth client in the legacy GCP project
- **Never delete the legacy GCP project** itself if any unrelated services still reference it — only remove the OAuth client

**Implications**:
- Two GCP projects must stay healthy. If billing lapses or the OAuth-owning project is deleted, Google Sign-In silently breaks for every user.
- OAuth consent screen verification status, branding (app logo, support email, privacy policy URL) and scope changes happen in the OAuth-owning project, not in Firebase.
- New OAuth credentials (e.g. adding a debug SHA for a teammate) must be created in the OAuth-owning project; adding them under Firebase's "auto created by Firebase" API keys does not register a Sign-In client.
- The app reads `GOOGLE_WEB_CLIENT_ID` / `GOOGLE_IOS_CLIENT_ID` from `--dart-define`; those values come from the OAuth-owning project. Info.plist `CFBundleURLSchemes` and `GIDClientID` reference the same client.

**Future consolidation runbook** (when ready to migrate OAuth into the Firebase project):
1. In Firebase project's GCP console (`budgiebreedingtracker-12072`), configure the OAuth consent screen (External, app name, support email, privacy policy URL `https://budgiebreedingtracker.online/privacy-policy.html`, scopes: `openid email profile`).
2. Create new OAuth 2.0 Client IDs in the Firebase project: one iOS (bundle ID `com.budgiebreeding.tracker`, add the prod SHA-1 + SHA-256), one Web (used as `GOOGLE_WEB_CLIENT_ID`).
3. Update Info.plist `CFBundleURLSchemes` (replace `com.googleusercontent.apps.118599620356-…` with the new reversed iOS client ID).
4. Update `.env` / dart-defines / CI secrets: `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID`.
5. Add Sign-In flow telemetry, ship to a small beta first — old binaries still hit the OAuth-owning project for ~30 days post-release.
6. Once Sign-In traffic on the old client ID drops to ~0 for 14 days, optionally delete the OAuth client in the legacy project; never delete the legacy GCP project itself if there's any chance it still owns the consent screen.
7. Do NOT do this work outside a scheduled maintenance window. A misconfigured iOS reversed client ID breaks Sign-In for every iOS user until a binary rebuild + store re-review (~24h minimum).

### Secure Storage (`flutter_secure_storage`)
```dart
const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
);

await _storage.write(key: 'refresh_token', value: token);
final token = await _storage.read(key: 'refresh_token');
await _storage.deleteAll();  // on logout
```

| Item | Storage |
|------|---------|
| Supabase session token | Secure storage (auto by SDK) |
| Refresh token | Secure storage |
| MFA recovery codes (kısa süre) | Secure storage |
| User preferences (theme, language) | SharedPreferences (OK) |
| FCM token | Supabase DB |

### MFA UX Flow
1. **Enroll**: Settings → Security → Enable 2FA
2. Supabase TOTP secret üretir → QR code göster + manuel yedek kod
3. Kullanıcı 6 haneli kod gir → `verify` → server activate
4. **Recovery codes**: 8 kod üret, bir daha gösterilmez — kullanıcı kaydetmeli
5. Login flow: email/password → MFA challenge → TOTP veya recovery code

### Session Refresh
- Supabase SDK otomatik refresh (expire'dan 5dk önce)
- Refresh fail → `AuthException` → login redirect
- Offline mod local session ile çalışır, online'da refresh
- Concurrent refresh: SDK lock'lu

### Certificate Pinning
Aktif: `CertificatePinning.install()` bootstrap'ta `Supabase.initialize()`
öncesi çalışır ve `*.supabase.co` için SHA-256 fingerprint allowlist'i
uygular.

Rotation prosedürü:
1. Supabase leaf certificate expiry tarihinden en az 14 gün önce yeni
   fingerprint'i üret.
2. Eski ve yeni fingerprint'i aynı release'te allowlist'te tut.
3. Release adoption yeterli olduktan sonra eski fingerprint'i kaldır.
4. `scripts/verify_security.py` ile pinning modülünün bootstrap'a bağlı
   kaldığını doğrula.

Emergency unpin:
- Proxy/debug ihtiyacı yalnızca explicit `--dart-define=ALLOW_PROXY=true` ile
  yapılır; production build'lerde kullanılmaz.
- Sertifika rotasyonu beklenmedik şekilde kullanıcıları offline bırakırsa önce
  pin allowlist fix release'i çıkarılır, sonra eski pin kaldırılır.

## MFA Lockout Policy
- Threshold: 5 failed TOTP attempts → lockout
- Decay window: **7 days** of inactivity before `lockout_count` decrements
- Rationale: short decay (e.g., 24h) lets attacker try 1 code/day indefinitely; 7d makes slow brute force economically infeasible
- Enforced server-side in `supabase/functions/mfa-lockout/index.ts`
- Grace period for premium accounts: `premiumGracePeriodProvider` — guards MUST honor `GracePeriodStatus.gracePeriod` as passing, not just `isPremium`

## Remote Payload Validation (boundary)
- All Supabase responses deserialize through Freezed models with `@JsonKey(unknownEnumValue: X.unknown)` on enums
- Critical models (Profile, Bird, CommunityPost, Message) MUST assert required fields in factory body — do not trust remote to honor non-null contract
- Edge function responses: parse into typed Freezed model, not `Map<String, dynamic>`; malformed payload throws `ValidationException`, not silent null
- Never write `data['field'] as String` without null check on remote data — use `as String?` + explicit fallback or validation

## Route Guards
| Guard | Protects | Behavior |
|-------|----------|----------|
| `AdminGuard` | Admin-only screens | Redirects to home if not admin |
| `PremiumGuard` | Premium features | Redirects to premium upsell |
| Auth redirect | Protected routes | Redirects to login if unauthenticated |

- Guards defined in `lib/router/guards/`
- Never skip guards on protected routes — even for "quick testing"
- All guard logic must be stateless (derive from current auth state)

## Row-Level Security (RLS)
- ALL RLS policies managed server-side in Supabase
- Never modify, create, or drop RLS policies from client code
- Never use `service_role` key in client app
- Verify RLS with `scripts/verify_rls_staging.sql` before production migration
- Each user can only access their own data (enforced by `auth.uid()` in policies)

## Credentials & Secrets
- Supabase URL/anon key via `--dart-define` or `.env` file
- NEVER hardcode credentials in source code
- NEVER commit `.env`, `credentials.json`, or key files
- CI secrets stored in GitHub Secrets / Codemagic env groups
- RevenueCat API keys via dart-define, not in code

## Data Protection
- Sensitive user data encrypted at rest (Supabase manages server-side)
- Local DB (Drift/SQLite) on device — OS-level encryption on iOS/Android
- Photo uploads go through `storage_service.dart` with proper bucket policies
- Community content moderated via `moderate-content` Edge Function
- Free tier limits enforced server-side via `validate-free-tier-limit` Edge Function

## OAuth Token Management
- Google/Apple OAuth token revocation via `revoke-oauth-token` Edge Function
- Tokens refreshed automatically by Supabase client
- On logout: revoke tokens, clear local session, invalidate providers

## Security Anti-Patterns
1. Hardcoding Supabase credentials in source code
2. Using `service_role` key in client app
3. Modifying RLS policies from client code
4. Storing tokens in SharedPreferences (use secure storage)
5. Skipping auth guards for convenience
6. Trusting client-side validation alone (always validate server-side too)
7. Logging sensitive data (passwords, tokens, PII)
8. Committing `.env` files or secrets to git

> **Related**: architecture.md (security overview), error-handling.md (auth exceptions), release-ops.md (environment secrets)
