# Security

Source: `.claude/rules/security.md`

## Authentication Methods

| Method | Package |
|--------|---------|
| Email/password | Supabase Auth |
| Google OAuth | google_sign_in ^7.2.0 |
| Apple Sign-In | sign_in_with_apple ^8.0.0 |
| MFA (TOTP) | Supabase Auth + mfa-lockout Edge Function |

## Secure Storage

```dart
const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
);
```

| Item | Storage |
|------|---------|
| Supabase session token | Secure storage (auto by SDK) |
| Refresh token | Secure storage |
| User preferences | SharedPreferences (OK) |
| FCM token | Supabase DB |

**Never store tokens in SharedPreferences.**

## MFA Lockout Policy

- 5 failed TOTP attempts → lockout
- 7-day inactivity decay (not 24h — prevents 1 try/day forever attack)
- Server-side enforcement in `mfa-lockout` Edge Function

## Route Guards

| Guard | Protects | Behavior |
|-------|---------|---------|
| Auth redirect | Protected routes | → login if unauthenticated |
| `AdminGuard` | Admin screens | → home if not admin |
| `PremiumGuard` | Premium features | → upsell if not premium/grace |

All guards in `lib/router/guards/`. Never skip for "quick testing".

## Row-Level Security (RLS)

- ALL RLS policies managed server-side in Supabase
- Never modify RLS from client code
- Never use `service_role` key in client app
- Each user accesses only their own data (`auth.uid()` in policies)
- Verify with `scripts/verify_rls_staging.sql` before production migration

## Remote Payload Validation

- All Supabase responses deserialize through Freezed models
- `@JsonKey(unknownEnumValue: X.unknown)` on all enum fields
- Critical models assert required fields in factory body
- Edge function responses: parse to Freezed model, not `Map<String, dynamic>`
- Malformed payload → `ValidationException`, not silent null

## Credentials & Secrets

- Supabase URL/anon key: `--dart-define` or `.env` (never hardcoded)
- RevenueCat secret key: Edge Function secret only (never client)
- Never commit `.env`, `credentials.json`, key files
- CI: GitHub Secrets; Codemagic: env groups

## OAuth Token Management

- Google/Apple token revocation: `revoke-oauth-token` Edge Function on logout
- FCM tokens: deleted from DB on logout

## Google OAuth (mid-migration)

State as of 2026-05-26: OAuth clients exist in BOTH legacy GCP project (number `118599620356`) AND Firebase project (`budgiebreedingtracker-12072`, number `720334450619`). Supabase Auth Google provider holds both Web Client IDs in its comma-separated list — old AND new binaries' ID tokens are accepted in parallel.

| Layer | Identifier |
|-------|------------|
| Firebase project | `budgiebreedingtracker-12072` (`720334450619`). NEW OAuth clients (consent "In production", basic scopes, no verification needed). |
| Legacy OAuth project | `118599620356` — still hosts the client older binaries reference. Keep until binary traffic drops. |

New iOS Client: `720334450619-oacalc9gn0sg986d16it34jr4th6bkf4.apps.googleusercontent.com`.
New Web Client: `720334450619-kvo5m738euj98t4qmmqeabmmd48ma0tl.apps.googleusercontent.com`, redirect `https://lmqkwgitzvpacycujzgc.supabase.co/auth/v1/callback`.

`ios/Runner/Info.plist` `CFBundleURLSchemes` and `.env.example` updated. `GOOGLE_*_CLIENT_ID` env vars must be set to the new values in local `.env`, Codemagic env groups, and CI secrets before the next signed release. Old installed binaries still authenticate via legacy IDs — Supabase accepts both audiences.

The Android SHA-1 `4b:50:9f:a3:…` is registered against BOTH OAuth clients during the rollout. **Do not delete from Firebase.**

**Rollout state**:

- New Client IDs committed in `.env.example`; local `.env`, Codemagic env groups, and CI secrets must use the new values before the next signed release build
- Old installed binaries authenticate via legacy IDs (compiled in at build time) — Supabase accepts both audiences, no breakage
- A misconfigured iOS reversed client ID breaks Sign-In for every iOS user until binary rebuild + store re-review (~24h)
- Test new IDs in a debug build before shipping a signed release

## Certificate Pinning

- Active: `CertificatePinning.install()` runs before `Supabase.initialize()` in bootstrap
- SHA-256 fingerprint allowlist for `*.supabase.co`
- Rotation procedure: produce new fingerprint ≥14 days before leaf cert expiry, keep both old + new in one release, drop old after adoption
- Emergency proxy/debug: `--dart-define=ALLOW_PROXY=true` only — never in release builds
- Verification: `scripts/verify_security.py` confirms pinning module is wired in bootstrap

## Anti-Patterns

1. Hardcoding Supabase credentials
2. `service_role` key in client app
3. Modifying RLS from client code
4. Tokens in SharedPreferences (use secure storage)
5. Skipping auth guards
6. Trusting client-side validation alone
7. Logging PII (passwords, tokens)
8. Committing `.env` or secrets to git

## See Also

- [[patterns/anti-patterns]] — #7 (client.from in features)
- [[patterns/observability]] — PII rules
- [[infrastructure/edge-functions]] — JWT enforcement
- [[domain/auth-service]] — session management
