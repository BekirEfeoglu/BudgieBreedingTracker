# Security

## Authentication & Authorization
- Auth managed by Supabase Auth (email/password, Google OAuth, Apple Sign-In)
- MFA (TOTP) available — `mfa-lockout` Edge Function handles brute-force
- Session tokens stored in secure storage, never in SharedPreferences
- Auth state managed via Riverpod provider, reactive across app

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
