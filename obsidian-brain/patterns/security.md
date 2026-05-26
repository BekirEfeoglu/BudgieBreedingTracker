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

## Dual-Project Google OAuth

Google Sign-In OAuth client lives in a SEPARATE Google Cloud project from the Firebase project. Verified 2026-05-26; intentional but unusual setup.

| Layer | Identifier |
|-------|------------|
| Firebase project | `budgiebreedingtracker-12072` (project number `720334450619`) — FCM, Crashlytics, google-services.json/GoogleService-Info.plist |
| Google OAuth project | Separate GCP project, number `118599620356` — owns iOS Client ID `118599620356-…apps.googleusercontent.com`, OAuth consent screen, Web Client ID. Firebase project's GCP "OAuth Overview" shows "Google Auth Platform not configured yet" because OAuth is hosted elsewhere. |

The Android SHA-1 `4b:50:9f:a3:…` shows a duplicate-registration warning in Firebase because the same fingerprint is registered against the OAuth client in the other project. **The warning is informational, NOT a deletion recommendation.** Removing it from Firebase breaks Sign-In trust.

**Implications**:

- Two GCP projects must stay healthy — if billing lapses or the OAuth-owning project is deleted, Google Sign-In silently breaks for every user
- OAuth consent screen verification, branding, and scope changes happen in the OAuth-owning project, not in Firebase
- New SHAs (debug, teammate) must be created in the OAuth-owning project; Firebase's auto-created API keys don't register a Sign-In client
- App reads `GOOGLE_WEB_CLIENT_ID` / `GOOGLE_IOS_CLIENT_ID` from `--dart-define`; values come from the OAuth-owning project

**Future consolidation runbook** (when ready to migrate OAuth into the Firebase project):

1. In Firebase project's GCP console, configure OAuth consent screen (External, app name, support email, privacy policy URL, scopes `openid email profile`)
2. Create new OAuth 2.0 Client IDs in the Firebase project: one iOS (bundle `com.budgiebreeding.tracker`, prod SHA-1 + SHA-256), one Web
3. Update Info.plist `CFBundleURLSchemes` (replace `com.googleusercontent.apps.118599620356-…`)
4. Update `.env` / dart-defines / CI secrets
5. Add Sign-In telemetry, ship to small beta first — old binaries still hit the OAuth-owning project for ~30 days
6. Once Sign-In traffic on old client drops to ~0 for 14 days, optionally delete the OAuth client in the legacy project; never delete the legacy GCP project itself if it might still own the consent screen
7. Do NOT do this work outside a scheduled maintenance window — a misconfigured iOS reversed client ID breaks Sign-In for every iOS user until a binary rebuild + store re-review (~24h minimum)

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
