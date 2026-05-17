# Security

## Authentication & Authorization
- Auth managed by Supabase Auth (email/password, Google OAuth, Apple Sign-In)
- MFA (TOTP) available — `mfa-lockout` Edge Function handles brute-force
- Session tokens stored in secure storage, never in SharedPreferences
- Auth state managed via Riverpod provider, reactive across app

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
