# Release Operations

Source: `.claude/rules/release-ops.md`

## Release Channels

| Channel | Platform | Purpose |
|---------|---------|---------|
| GitHub Actions `ci.yml` | — | Validation, smoke builds |
| `release-ready.yml` | Android | Manual signed AAB + symbols as artifacts; publishes nothing |
| `scripts/build_release.sh android` | Android | Local equivalent, for verification |
| `scripts/build_release.sh ios` | iOS | IPA; distributed manually via Xcode Organizer / `xcrun altool` |
| Xcode Cloud | iOS | Build status (build-only) — not a release path |
| GitHub Pages | Web | `docs/` deployment |

**Codemagic was removed 2026-07-25** (`codemagic.yaml` deleted). There is no
hosted release pipeline and nothing publishes to a store automatically; every
store upload is a manual user action on both platforms.

## Version Bump

`pubspec.yaml`: `version: X.Y.Z+build`

- **major**: breaking changes (rare)
- **minor**: new feature
- **patch**: bug fix
- Build number: increment every release
- iOS and Android build numbers must be consistent

Current version: `1.1.7+56` (verify against `pubspec.yaml` — this drifts every release, treat as a snapshot not a live value)

## Store Release Flow

1. `python3 scripts/check_remote_status.py` — main must be green
2. Bump `pubspec.yaml`; for Android confirm the build number beats the
   package-wide Play maximum (see below)
3. Android: manual trigger `release-ready.yml` → signed AAB + Dart symbols as
   artifacts. iOS: `scripts/build_release.sh ios` → IPA
4. Upload manually — Play Console for the AAB, Xcode Organizer / `xcrun altool`
   for the IPA
5. Promote in store console after QA

**Play version codes are package-global**, reserved across tracks and the
artifact library. Codemagic used to resolve the next code automatically from the
package-wide maximum; that is gone, so the `pubspec.yaml` build number must be
checked against Play Console by hand before every Android release. A reused code
is a hard upload rejection.

## Release Build Script

`scripts/build_release.sh <ios|android>` is the canonical release build. It
refuses to run without `SENTRY_DSN` (in `.env`) and `SENTRY_AUTH_TOKEN`
(environment), builds with `--obfuscate --split-debug-info
--save-obfuscation-map`, then uploads symbols via `dart run sentry_dart_plugin`
using a per-platform `SENTRY_RELEASE` that matches runtime `PackageInfo`
naming. iOS re-runs `scripts/generate_ios_env.sh` first.

**Do not Archive from Xcode without running it.** `ios/Flutter/DartDefines.xcconfig`
is gitignored and only rewritten by a `flutter build`; a stale copy was found
holding the legacy Google web client ID and no `SENTRY_DSN`, so a raw Archive
would have shipped a release with no crash reporting at all.

## Android AAB

Signed AAB only from `release-ready.yml` (or `scripts/build_release.sh android`
locally). CI main push produces a debug APK only (smoke gate) — never send a
debug APK to the store. `release-ready.yml` reads the committed `pubspec.yaml`
version/build, uploads artifacts and Sentry symbols, and deliberately has no
store publishing block. It pins Flutter `3.41.4` to match GitHub Actions and
Xcode Cloud; a moving `stable` release toolchain is not accepted (2026-07-18: a
drift to 3.44.6 broke release compilation against locked `lucide_icons 0.257.0`).

## iOS

- Xcode Cloud: **build-only** main workflow
- Archive/TestFlight/export: only when Apple Developer account, provisioning profile, and registered physical device are ready
- `ios/ci_scripts/ci_post_clone.sh` must remain executable
- Retry/backoff on pod download failures

## Environment Discipline

- Never use `.env` as production source of truth
- Secrets: GitHub Secrets (CI + `release-ready.yml`); local release builds read
  `.env`, with `SENTRY_AUTH_TOKEN` exported in-shell rather than stored there
- Missing env → fail-fast; no silent fallback
- `SENTRY_DSN` is required for production Android/iOS releases and must stay
  synchronized between the GitHub Actions secret and local `.env`;
  `scripts/build_release.sh` enforces this before building.
- Obfuscated builds generate `build/app/obfuscation.map.json`; the
  `sentry_dart_plugin` upload uses the masked, `org:ci`-only
  `SENTRY_AUTH_TOKEN` and blocks the release on failure. Source upload stays off.
- Symbol upload exports the same platform package/bundle ID and actual build
  number that `SentryFlutter` obtains from `PackageInfo`, keeping release/dist
  association exact.

## Supabase Ops

- Local email capture uses `[local_smtp]`; the deprecated `[inbucket]` alias is
  forbidden so CI/deploy commands stay warning-free.
- Migration: `supabase db push` (manual, staging first, then prod)
- Edge Function deploy: `deploy-edge-functions` CI job (main only; Edge
  source/config/deploy-workflow path-gated, so docs-only pushes skip it)
- RLS changes via migration files only — never console-only

## Operational Anti-Patterns

1. Signing AAB in main CI (bloats every push)
2. Release/signing jobs on PR events
3. Stale green from earlier commit as release evidence
4. Deploying before CI is fully green on exact commit SHA
5. Version bump without incrementing build number
6. Xcode Cloud archive without registered physical device/profile
7. Archiving from Xcode without `scripts/build_release.sh` first (stale
   `DartDefines.xcconfig` → DSN-less release)
8. Assuming the Android version code is resolved automatically (it no longer is)
9. Re-adding a job/pipeline that publishes to a store — artifact-only is deliberate

## See Also

- [[infrastructure/ci-cd]] — CI jobs
- [[infrastructure/branch-workflow]] — merge policy
- [[infrastructure/environment]] — secrets
