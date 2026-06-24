# Release Operations

Source: `.claude/rules/release-ops.md`

## Release Channels

| Channel | Platform | Purpose |
|---------|---------|---------|
| GitHub Actions `ci.yml` | — | Validation, smoke builds |
| `release-ready.yml` | Android | Manual signed AAB readiness |
| Codemagic | App Store / Google Play | Production releases |
| Xcode Cloud | iOS | Build status (build-only) |
| GitHub Pages | Web | `docs/` deployment |

## Version Bump

`pubspec.yaml`: `version: X.Y.Z+build`

- **major**: breaking changes (rare)
- **minor**: new feature
- **patch**: bug fix
- Build number: increment every release
- iOS and Android build numbers must be consistent

Current version: `1.1.3+50`

## Store Release Flow

1. `python3 scripts/check_remote_status.py` — main must be green
2. Manual trigger `release-ready.yml` — produces signed AAB + Dart symbols
3. Codemagic: `android-release` → Google Play alpha, `ios-release` → TestFlight
4. Promote in store console after QA

## Android AAB

Signed AAB only from Codemagic or `release-ready.yml`. CI main push produces debug APK only (smoke gate). Never send debug APK to store.

## iOS

- Xcode Cloud: **build-only** main workflow
- Archive/TestFlight/export: only when Apple Developer account, provisioning profile, and registered physical device are ready
- `ios/ci_scripts/ci_post_clone.sh` must remain executable
- Retry/backoff on pod download failures

## Environment Discipline

- Never use `.env` as production source of truth
- Secrets: GitHub Secrets (CI) / Codemagic env groups (release)
- Missing env → fail-fast; no silent fallback

## Supabase Ops

- Migration: `supabase db push` (manual, staging first, then prod)
- Edge Function deploy: `deploy-edge-functions` CI job (main only)
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
