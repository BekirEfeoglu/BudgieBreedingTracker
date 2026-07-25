# Environment Variables

Source: `CLAUDE.md` § Environment Variables

## dart-define Variables

| Variable | Required | Default | Purpose |
|----------|---------|---------|---------|
| `SUPABASE_URL` | Yes | — | Supabase project URL |
| `SUPABASE_ANON_KEY` | Yes | — | Supabase anonymous key |
| `SENTRY_DSN` | Yes for production releases | — | Sentry error tracking DSN |
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
| `REVENUECAT_SECRET_API_KEY` | sync-premium-status + revenuecat-webhook RevenueCat verification |
| `REVENUECAT_WEBHOOK_AUTH_TOKEN` | revenuecat-webhook shared secret (32+ random bytes; set in Supabase secrets AND RevenueCat webhook Authorization header) |
| `SUPABASE_ACCESS_TOKEN` | Edge Function deployment (CI) |
| `SUPABASE_PROJECT_REF` | Edge Function deployment (CI) |

**Never put Edge Function secrets in client code.**

## Release-Only Secrets

| Secret | Purpose |
|--------|---------|
| `SENTRY_AUTH_TOKEN` | `org:ci` organization token used by `sentry_dart_plugin` to upload release symbols; a GitHub Actions secret for `release-ready.yml`, otherwise exported in-shell for `scripts/build_release.sh` |

Never pass `SENTRY_AUTH_TOKEN` through `--dart-define` and never write it into
`.env`; it must not ship in the application binary. `scripts/build_release.sh`
refuses to build when it — or `SENTRY_DSN` — is missing, because neither absence
breaks the build: the result is a release with no crash reporting, or one whose
obfuscated stack traces nobody can read.

## Config Methods

| Context | Method |
|---------|--------|
| Local development | `.env` + `--dart-define-from-file=.env` |
| Release builds | `.env` via `scripts/build_release.sh` (same `--dart-define-from-file`) |
| GitHub Actions | GitHub Secrets (incl. `release-ready.yml`) |
| Edge Functions | Supabase Dashboard → Secrets |

iOS note: `flutter build` is what rewrites the gitignored
`ios/Flutter/DartDefines.xcconfig`. Archiving from Xcode without a preceding
build reuses whatever stale values that file holds — a found copy still had the
legacy Google web client ID and no `SENTRY_DSN`.

## `.env` Rules

- **Never commit** `.env` to git (in `.gitignore`)
- `.env` is local-only, never source of truth for production
- Build command: `flutter run --dart-define-from-file=.env`

## Fail-Fast

If `SUPABASE_URL` or `SUPABASE_ANON_KEY` is missing, cloud initialization
fails. Production release workflows also fail fast when `SENTRY_DSN` is
missing so store binaries cannot silently ship without crash reporting.

## See Also

- [[infrastructure/ci-cd]] — CI secrets
- [[patterns/security]] — credential handling
- [[patterns/feature-flags]] — DEBUG_* flags
