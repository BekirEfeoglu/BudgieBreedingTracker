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

**App code state**: `ios/Runner/Info.plist` `CFBundleURLSchemes` and `.env.example` updated to the NEW iOS reversed client ID. `GOOGLE_*_CLIENT_ID` env vars need to be set to the new values in local `.env` (which `scripts/build_release.sh` reads via `--dart-define-from-file`) and in GitHub Actions secrets BEFORE the next signed release build. Old binaries still installed on user devices continue to use the legacy project's IDs (compiled in at build time) and Supabase accepts both audiences during the rollout window.

The Android SHA-1 fingerprint `4b:50:9f:a3:...` shows a duplicate-registration warning in Firebase because that fingerprint is registered against BOTH OAuth clients (legacy + new). **Do not delete it from Firebase** — it is the production app signature for both clients during the migration.

**Future-state cleanup** (only when ALL of these are true):
1. New signed binary shipped to App Store + Play
2. >90% of active users have updated to the new binary (check via Sentry tag or Supabase auth audit logs filtered by issuer)
3. Old binary traffic against the legacy Web Client ID is ~0 for 14 consecutive days

Then:
- Remove the legacy Web Client ID from Supabase Auth's "Client IDs" comma-separated list
- Optionally delete the OAuth client in the legacy GCP project
- **Never delete the legacy GCP project** itself if any unrelated services still reference it — only remove the OAuth client

**Rollout state**:
- New Web Client ID is committed in `.env.example`. Local `.env` and CI secrets must use the new `GOOGLE_WEB_CLIENT_ID` + `GOOGLE_IOS_CLIENT_ID` values before the next signed release build. A stale gitignored `ios/Flutter/DartDefines.xcconfig` was found still carrying the LEGACY web client ID (and no `SENTRY_DSN`), which a raw Xcode Archive would have shipped — run `scripts/build_release.sh ios`, which regenerates that file from `.env` (release-ops.md § Release Build).
- Old installed binaries still authenticate via the legacy project's IDs (compiled in at build time). Supabase accepts both audiences during this rollout, so old binaries do NOT break.
- A misconfigured iOS reversed client ID breaks Sign-In for every iOS user until a binary rebuild + store re-review (~24h minimum). Test new IDs in a debug build before shipping a signed release.

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
| User preferences (theme, language) | SharedPreferences (OK) |
| FCM token | Supabase DB |

### MFA UX Flow
1. **Enroll**: Settings → Security → Enable 2FA
2. Supabase TOTP secret üretir → QR code göster + manuel secret
3. Kullanıcı 6 haneli kod gir → `verify` → server activate
4. Login flow: email/password → MFA challenge → TOTP

**Recovery codes — shipped (2026-07-09):** 2FA kurulumu tamamlanınca
`RecoveryCodeService` (`lib/domain/services/auth/recovery_code_service.dart`)
10 tek-kullanımlık kod üretir; kodlar kullanıcıya BİR kez gösterilir, DB'de
yalnızca **SHA-256 hash** olarak (`mfa_recovery_codes` tablosu, own-scope RLS)
saklanır. Login 2FA verify ekranındaki "Kurtarma kodu kullan" akışı
`redeem_mfa_recovery_code` RPC'sini çağırır: RPC hash'i doğrular, kodu used
işaretler ve kullanıcının `auth.mfa_factors` satırlarını **server-side siler**
(AAL1'de kullanıcı kendi verified factor'ını silemez — bu yüzden SECURITY
DEFINER). Böylece MFA devre dışı kalır, AAL1 login tamamlanır ve kullanıcı
tekrar kurmaya yönlendirilir. Güvenlik deseni: exposed `public` wrapper
INVOKER, gerçek iş `private.redeem_mfa_recovery_code` DEFINER'da (advisor
0028/0029 temiz); yüksek entropili (50-bit) kodlar brute-force'u infeasible
kılar (kasıtlı olarak per-attempt lock yok). Client normalize (`strip
non-alnum + upper`) SQL normalize ile birebir aynı olmalı. Migration'lar
`20260709115154` + `20260709115445`.

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
1. Supabase leaf certificate expiry tarihinden en az 14 gün önce ECDSA ve RSA
   TLS istemci profilleriyle sunulan tüm geçerli leaf fingerprint'lerini üret.
2. Eski ve yeni fingerprint'i aynı release'te allowlist'te tut.
3. Release adoption yeterli olduktan sonra eski fingerprint'i kaldır.
4. `scripts/verify_security.py` ile pinning modülünün bootstrap'a bağlı
   kaldığını doğrula.

**14 günlük lead time CI'da zorunludur, takvim notu değildir.**
`check_certificate_pin_freshness` her pin'in üstündeki
`valid <başlangıç> through <bitiş>` yorumundan en erken expiry'yi okur ve
son 14 güne girildiğinde `security-audit` job'unu KIRAR (expire olmuşsa ayrı,
daha sert bir mesajla). Gerekçe: pin seti bir kez lapse ederse uygulama
backend'e hiç ulaşamaz ve tek çözüm yeni bir store release'idir — yani
fark edildiğinde düzeltmesi günler sürer. Bu yüzden hâlâ rotasyon vakti
varken build'i durdurur.

Sonuç olarak expiry yorumu **makine tarafından okunuyor**: yeni pin eklerken
`through YYYY-MM-DD` formatını koru. Yorum satır sonuna kayarsa tarih bir
sonraki satırda `//` işaretinin arkasında kalabilir; checker bunu tolere eder
(regex'i yazarken bu durum önce gözden kaçmış, testi yakalamıştı).

Emergency unpin:
- Proxy/debug ihtiyacı yalnızca explicit `--dart-define=ALLOW_PROXY=true` ile
  yapılır; production build'lerde kullanılmaz.
- **Release build'lerde flag YOK SAYILIR (2026-07-25):** `_allowProxy` artık
  `!kReleaseMode && bool.fromEnvironment('ALLOW_PROXY')`. Yani `--release`
  derlenmiş bir binary bu define ile üretilse bile pinning'i kapatmaz; TLS
  doğrulaması sessizce devre dışı kalamaz. Debug/profile build'lerde davranış
  değişmedi.
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
- CI secrets stored in GitHub Secrets; local release builds read `.env` via `scripts/build_release.sh` (`SENTRY_AUTH_TOKEN` is exported in-shell, never written to `.env`)
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
