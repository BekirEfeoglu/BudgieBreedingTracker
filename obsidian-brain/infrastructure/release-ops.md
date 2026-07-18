# Release Operations

Source: `.claude/rules/release-ops.md`

## Release Channels

| Channel | Platform | Purpose |
|---------|---------|---------|
| GitHub Actions `ci.yml` | — | Validation, smoke builds |
| `release-ready.yml` | Android | Manual signed AAB readiness |
| Codemagic | App Store / Google Play | Production releases |
| Codemagic `android-verify-only` | Android | Signed verification artifact without store publishing |
| Xcode Cloud | iOS | Build status (build-only) |
| GitHub Pages | Web | `docs/` deployment |

## Version Bump

`pubspec.yaml`: `version: X.Y.Z+build`

- **major**: breaking changes (rare)
- **minor**: new feature
- **patch**: bug fix
- Build number: increment every release
- iOS and Android build numbers must be consistent

Current version: `1.1.5+52` (verify against `pubspec.yaml` — this drifts every release, treat as a snapshot not a live value)

## Store Release Flow

1. `python3 scripts/check_remote_status.py` — main must be green
2. Manual trigger `release-ready.yml` — produces signed AAB + Dart symbols
3. Optional Codemagic `android-verify-only` — proves signing + Sentry upload without store mutation
4. Codemagic: `android-release` → Google Play alpha, `ios-release` → TestFlight
5. Promote in store console after QA

## Android AAB

Signed AAB only from Codemagic or `release-ready.yml`. CI main push produces debug APK only (smoke gate). Never send debug APK to store.
`android-verify-only` reads the committed `pubspec.yaml` version/build, uploads
artifacts and Sentry symbols, and deliberately has no store publishing block.

## iOS

- Xcode Cloud: **build-only** main workflow
- Archive/TestFlight/export: only when Apple Developer account, provisioning profile, and registered physical device are ready
- `ios/ci_scripts/ci_post_clone.sh` must remain executable
- Retry/backoff on pod download failures

## Environment Discipline

- Never use `.env` as production source of truth
- Secrets: GitHub Secrets (CI) / Codemagic env groups (release)
- Missing env → fail-fast; no silent fallback
- `SENTRY_DSN` is required for production Android/iOS releases and must remain
  synchronized between GitHub Actions and Codemagic `app_env_vars`.
- Obfuscated builds generate `build/app/obfuscation.map.json`; the
  `sentry_dart_plugin` upload uses the masked, `org:ci`-only
  `SENTRY_AUTH_TOKEN` and blocks publishing on failure. Source upload stays off.
- Symbol upload exports the same platform package/bundle ID and actual build
  number that `SentryFlutter` obtains from `PackageInfo`, keeping release/dist
  association exact for dynamic Codemagic builds.

## Supabase Ops

- Local email capture uses `[local_smtp]`; the deprecated `[inbucket]` alias is
  forbidden so CI/deploy commands stay warning-free.
- Migration: `supabase db push` (manual, staging first, then prod)
- Edge Function deploy: `deploy-edge-functions` CI job (main only; Edge
  source/config/deploy-workflow path-gated, so docs-only pushes skip it)
- RLS changes via migration files only — never console-only

## Operational Anti-Patterns

1. Signing AAB in main CI (bloats every push)
2. `android-release` job on PR events
3. Stale green from earlier commit as release evidence
4. Deploying before CI is fully green on exact commit SHA
5. Version bump without incrementing build number
6. Xcode Cloud archive without registered physical device/profile

## See Also

- [[infrastructure/ci-cd]] — CI jobs
- [[infrastructure/branch-workflow]] — merge policy
- [[infrastructure/environment]] — secrets
