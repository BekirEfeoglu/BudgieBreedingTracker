# Environment Variables

Source: `CLAUDE.md` § Environment Variables

## dart-define Variables

| Variable | Required | Default | Purpose |
|----------|---------|---------|---------|
| `SUPABASE_URL` | Yes | — | Supabase project URL |
| `SUPABASE_ANON_KEY` | Yes | — | Supabase anonymous key |
| `SENTRY_DSN` | No | — | Sentry error tracking DSN |
| `SENTRY_ENVIRONMENT` | No | `production` | Sentry environment tag |
| `REVENUECAT_API_KEY_IOS` | No | — | RevenueCat iOS |
| `REVENUECAT_API_KEY_ANDROID` | No | — | RevenueCat Android |
| `GOOGLE_WEB_CLIENT_ID` | No | — | Google OAuth (web) |
| `GOOGLE_IOS_CLIENT_ID` | No | — | Google OAuth (iOS) |
| `DEBUG_START_ROUTE` | No | — | Debug: skip splash, open route |
| `DEBUG_GENETICS_FIXTURE` | No | — | Debug: preset genetics state |

## Edge Function Secrets (Server Only)

| Secret | Purpose |
|--------|---------|
| `REVENUECAT_SECRET_API_KEY` | sync-premium-status RevenueCat verification |
| `SUPABASE_ACCESS_TOKEN` | Edge Function deployment (CI) |
| `SUPABASE_PROJECT_REF` | Edge Function deployment (CI) |

**Never put Edge Function secrets in client code.**

## Config Methods

| Context | Method |
|---------|--------|
| Local development | `.env` + `--dart-define-from-file=.env` |
| GitHub Actions | GitHub Secrets |
| Codemagic | Environment groups |
| Edge Functions | Supabase Dashboard → Secrets |

## `.env` Rules

- **Never commit** `.env` to git (in `.gitignore`)
- `.env` is local-only, never source of truth for production
- Build command: `flutter run --dart-define-from-file=.env`

## Fail-Fast

If `SUPABASE_URL` or `SUPABASE_ANON_KEY` missing → app fails at init. No silent fallback to hardcoded values.

## See Also

- [[infrastructure/ci-cd]] — CI secrets
- [[patterns/security]] — credential handling
- [[patterns/feature-flags]] — DEBUG_* flags
