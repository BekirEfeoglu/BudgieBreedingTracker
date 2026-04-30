# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in BudgieBreedingTracker, please report it responsibly.

### How to Report

1. **GitHub Private Vulnerability Reporting**: Use the [Security Advisories](https://github.com/BekirEfeoglu/BudgieBreedingTracker/security/advisories/new) feature to privately report the issue.
2. **Email**: Send details to **befeoglu016@gmail.com** with the subject line `[SECURITY] BudgieBreedingTracker`.

### What to Include

- A clear description of the vulnerability
- Steps to reproduce the issue
- Affected versions
- Any potential impact assessment

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 5 business days
- **Resolution**: Depending on severity, typically within 30 days

### Guidelines

- Please do **not** open public issues for security vulnerabilities
- Allow reasonable time for us to address the issue before public disclosure
- We will credit reporters in the fix announcement (unless anonymity is preferred)

### Scope

The following are in scope:

- Authentication and authorization bypasses
- Data exposure (user data, breeding records)
- SQL injection in Supabase queries
- RLS policy bypasses
- API key or secret exposure
- Encryption weaknesses (AES-256-CBC implementation)
- Certificate pinning bypasses

### Out of Scope

- Denial of service attacks
- Social engineering
- Physical security
- Third-party service infrastructure (Supabase, RevenueCat, Firebase)

## Security Measures

This application implements:

### Mobile Client
- **TLS Certificate Pinning** for Supabase connections (`lib/core/security/certificate_pinning.dart`)
- **AES-256-CBC Encryption** with HMAC-SHA256 authentication for sensitive fields and backups
- **`flutter_secure_storage`** for crypto keys, OAuth refresh tokens, and Local AI API key (Keychain on iOS, EncryptedSharedPreferences on Android)
- **Inactivity Guard** with automatic session timeout after 30 minutes
- **Release-build Obfuscation** via `--obfuscate --split-debug-info=...` for both Android (AAB) and iOS (IPA); symbol files retained as CI artifacts for crash deobfuscation
- **ProGuard / R8** minification + resource shrinking on Android release builds

### Backend (Supabase + Edge Functions)
- **Row-Level Security (RLS)** on all tables — enforced server-side; clients never modify policies
- **MFA (TOTP)** with brute-force lockout: 5 failed attempts → lockout, 7-day decay window (`mfa-lockout` Edge Function)
- **`pgaudit` extension** + row-level audit triggers on `profiles` (role changes), `admin_users`, and `mfa_lockouts` writing to the admin-only `audit_logs` table
- **HTTP Security Headers** on every Edge Function response: `Strict-Transport-Security` (2y, includeSubDomains, preload), `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin`, default-deny `Content-Security-Policy`
- **CORS Allowlist** driven by `ALLOWED_ORIGINS` env var; unknown origins receive no `Access-Control-Allow-Origin` header
- **Per-user Rate Limiting** on Edge Functions (`_shared/rate-limit.ts`)
- **Zod-validated** request bodies on every Edge Function (`_shared/validation.ts`)
- **Service Role Key** is never exposed to clients; only used inside Edge Functions
- **OAuth Token Revocation** on logout via `revoke-oauth-token` Edge Function
- **Image Safety Scanning** before storage uploads (`scan-image-safety` Edge Function)
- **Free Tier Enforcement** server-side via `validate-free-tier-limit` Edge Function

### Operational / CI
- **Sentry Error Tracking** with PII scrubbing
- **Dependabot** for `pub`, GitHub Actions, and `npm` (weekly)
- **`scripts/verify_security.py`** runs in the `security-audit` CI job to detect regressions in any of the controls above
- **`scripts/verify_code_quality.py`** scans for 21 anti-patterns (`withOpacity`, hardcoded credentials, bare `catch`, etc.)
- **Secret Hygiene**: `.env`, `*.keystore`, `*.jks`, `*.p12`, `*.pem`, and `key.properties` are gitignored; CI uses GitHub Secrets, releases use Codemagic env groups
- **Strict Lints** in `analysis_options.yaml`: `avoid_print`, `cancel_subscriptions`, `close_sinks`, `use_build_context_synchronously`, `avoid_catching_errors`, `avoid_returning_null_for_void`

### Operator-Managed Settings (Supabase Dashboard)
The following must be configured directly in the Supabase project — they are not in source control:

- **JWT expiry**: access token ≤ 15 min, refresh token ≤ 7 days (Authentication → Sessions)
- **MFA enrollment** policy and enforced AAL2 for sensitive endpoints
- **Allowed redirect URLs** locked to production domains
- **`pgaudit` extension** enabled (Database → Extensions → pgaudit) + `pgaudit.log = 'ddl, role'`
- **Network restrictions** to limit DB access to known origins/CIDRs

## Security Best Practices for Users

- Keep the app updated to the latest version
- Use a strong, unique password for your Supabase account
- Enable two-factor authentication (2FA / MFA) in your account settings
- Do not share your `.env` file or API keys publicly
- Review app permissions periodically

## OWASP Top 10 (2021) Coverage

| Risk                                       | Mitigation in this project                                                                                  |
| ------------------------------------------ | ----------------------------------------------------------------------------------------------------------- |
| A01 Broken Access Control                  | RLS on every table; route guards (`AdminGuard`, `PremiumGuard`); server-side authorization in Edge Funcs    |
| A02 Cryptographic Failures                 | TLS 1.2+ via certificate pinning; AES-256-CBC + HMAC-SHA256 for at-rest crypto; `flutter_secure_storage`    |
| A03 Injection                              | Drift parameterized queries; PostgREST type-checked filters; Zod schemas at Edge Function boundary          |
| A04 Insecure Design                        | Offline-first with explicit sync metadata; threat model in `.claude/rules/security.md`                      |
| A05 Security Misconfiguration              | `verify_security.py` CI job; HTTP security headers; `.gitignore` audit                                      |
| A06 Vulnerable Components                  | Dependabot for `pub` / GH Actions / `npm`; weekly cadence                                                   |
| A07 Identification & Authentication        | Supabase Auth; MFA + lockout; AAL claim verified in privileged Edge Functions                               |
| A08 Software & Data Integrity              | HMAC on encrypted backups; signed AAB; Codemagic + Code Signing for IPA                                     |
| A09 Logging & Monitoring                   | Sentry (no PII); `audit_logs` table; `pgaudit` for DDL/role changes                                         |
| A10 SSRF                                   | Edge Functions only call known FCM / Google OAuth / Supabase endpoints; no user-controlled URLs are fetched |
