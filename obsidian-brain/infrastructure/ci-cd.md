# CI/CD

Source: `.claude/rules/ci-actions.md`, `.claude/rules/release-ops.md`, `CLAUDE.md`

## GitHub Actions (`ci.yml`)

Runs on PRs and main pushes.

| Job | Purpose | Blocker |
|-----|---------|---------|
| `analyze` | `flutter analyze --no-fatal-infos` | PR merge |
| `test` | Unit + widget tests, shuffled via `--test-randomize-ordering-seed random`; a shuffled-order red = new order-dependency, NOT flakiness — reproduce with the logged seed, never disable ordering (ci-actions.md § Random Test Ordering). Step timeout 30m, job-level 40m | PR merge |
| `golden-test` | Visual regression (Linux baseline) | PR merge |
| `edge-functions-test` | `deno test` on `supabase/functions` | PR merge + Edge deploy gate |
| `e2e-community-test` | E2E + community tagged tests | `workflow_dispatch`/`schedule` |
| `scripts-test` | Python script tests (≥99% coverage) | PR merge |
| `l10n-sync` | Translation key parity (--strict-keys) | PR merge |
| `code-quality` | Anti-pattern scan + platform target policy + wiki lint + migration structure drift (`verify_migration_drift.py`) + rule symbol drift (`check_rule_symbol_drift.py --target all --classes --strict`, rules + wiki) | PR merge |
| `rules-sync` | CLAUDE.md stats verification | PR merge |
| `security-audit` | `python scripts/verify_security.py` — cert pinning, secrets | PR merge |
| `auto-fix-stats` | Auto-PR for CLAUDE.md drift | main only |
| `edge-function-changes` | Edge source/config/deploy-workflow path guard | main push |
| `deploy-edge-functions` | Supabase Edge Function deploy | main only, path-gated, needs analyze+test+edge-functions-test |
| `android-build` | Debug APK smoke gate | main |
| `android-release` | Signed AAB (`release-ready.yml`) | manual trigger only |
| `ios-build` | iOS build (no code signing) | main |
| `pages` | GitHub Pages deployment from `docs/` | main |

## GitHub Pages Site

The public marketing site lives in `docs/`. Pages deploys on `main` pushes, so
web changes should be verified against the exact pushed commit like app changes.
See [[infrastructure/marketing-site]] for anchor-navigation, accessibility, SEO,
and visual QA checks.

The Flutter app does not ship a Flutter Web target. `check_platform_targets.py`
keeps `web/` absent so the static `docs/` site remains the only web surface.

## CI Rules

- Action versions pinned to commit SHA (not tags)
- `pull_request` for code-running validation; `pull_request_target` for bot/fork metadata
- Minimum permissions: `contents: read`, `pull-requests: read`
- Secret-requiring jobs: main push only
- Edge deploy runs only for `supabase/functions/**`, `supabase/config.toml`, or
  `.github/workflows/ci.yml`; documentation-only pushes skip production deploy.
- Workflow YAML must be locally parsed before push: `ruby -e 'require "yaml"; YAML.load_file(ARGV[0])' .github/workflows/ci.yml`
- Install hooks through `scripts/install_git_hooks.sh` so `core.hooksPath` stays
  worktree-relative. The pre-commit hook clears repository-local Git variables
  for Flutter subprocesses, allowing the SDK to resolve its own version.

## Dependabot

`.github/dependabot.yml` checks both Flutter/Dart (`pub`) and GitHub Actions
dependencies monthly, on the first day of the month. Open PR caps remain 10
for `pub` and 5 for Actions. Compatibility holds live beside the schedule and
are removed only after their documented SDK/package preconditions clear.

## Release Builds (no hosted pipeline)

Codemagic was removed 2026-07-25 (`codemagic.yaml` deleted). Nothing publishes
to a store automatically; every upload is a manual user action.

| Platform | Path | Produces |
|----------|------|----------|
| Android | `release-ready.yml` (manual) | Signed AAB + debug symbols and the Dart obfuscation map as artifacts |
| Android (local) | `scripts/build_release.sh android` | Same build, for verification |
| iOS | `scripts/build_release.sh ios` | `build/ios/archive/Runner.xcarchive` |

### `scripts/build_release.sh <ios|android>`

Canonical release build. Fails fast when `SENTRY_DSN` (in `.env`) or the
`org:ci`-scoped `SENTRY_AUTH_TOKEN` (environment) is missing — neither absence
breaks the build, so both would otherwise ship silently broken: no DSN means a
release with no crash reporting, no token means unreadable obfuscated stack
traces. It then builds with `--obfuscate --split-debug-info` plus
`--save-obfuscation-map` (passed through `--extra-gen-snapshot-options`; it is
not a `flutter build` flag) and uploads symbols via `dart run sentry_dart_plugin`
with a per-platform `SENTRY_RELEASE` matching runtime `PackageInfo` naming. iOS
re-runs `scripts/generate_ios_env.sh` first.

**Never Archive straight from Xcode.** The iOS defines sit in gitignored
generated xcconfigs that only a `flutter build` refreshes; Archive reads
whatever is there. Current Flutter writes them into `Generated.xcconfig`
(base64 `DART_DEFINES`), not into `ios/Flutter/DartDefines.xcconfig` — and
because `Release.xcconfig` includes that legacy file afterwards, a leftover
copy overrides the fresh values. One found on 2026-07-26 carried the legacy
Google project and no `SENTRY_DSN`; it was deleted.

**Play version codes are package-global.** The `pubspec.yaml` build number must
exceed the highest code across ALL tracks and the artifact library. Codemagic
resolved this automatically; it is now a manual pre-release check.

### Release Ready (`release-ready.yml`)

Manual workflow (`workflow_dispatch`) for signed AAB readiness. Does not run on
main push (to avoid slowing CI). It requires the GitHub Actions `SENTRY_DSN`
secret and injects the `production` environment into the release build; its
`SENTRY_AUTH_TOKEN` is used only for symbol upload and never passed into the
app binary. It carries no `publishing` block or Google Play credential — you
download the artifact and upload it yourself. It pins Flutter `3.41.4` to match
GitHub Actions and Xcode Cloud: on 2026-07-18 a release builder on the moving
`stable` channel resolved to 3.44.6 and broke release compilation against
locked `lucide_icons 0.257.0` (`IconData` became final). Upgrade the SDK only
together with dependency compatibility and all release builders.

## Xcode Cloud

- Build-only (`Build - iOS`, scheme `Runner`, Any iOS Simulator)
- Archive/TestFlight only when Apple signing + provisioning profile + registered device ready
- `ios/ci_scripts/ci_post_clone.sh`: installs Flutter, runs `flutter pub get`, `dart run build_runner build`, `pod install`; must stay executable, retry/backoff on network steps
- **Flutter install = curl+unzip of the pinned arch-aware SDK zip** (`flutter_macos[_arm64]_3.41.4-stable.zip`) — NEVER `git clone flutter/flutter`: that clone is known-flaky on Xcode Cloud (flutter/flutter#163198) and was the true root cause of the recurring ~40s `Build - iOS` action_required (2026-07-09). First curl-based build passed with a full ~9-min build.
- drift_dev's "Circular error when deserializing drift modules" is a **non-fatal WARNING** (simolus3/drift#3227) — it never fails `build_runner`; do not chase it as a post-clone failure cause. The clean-and-retry loop (cap 8) remains as belt-and-braces.
- The script prints `>>> STEP N:` markers before every step; Xcode Cloud only surfaces a generic "script failed (exited with code 1)", so the LAST marker in the log names the failing step. Keep the markers.
- Rapid successive main pushes can make Xcode Cloud supersede intermediate builds (`action_required` on middle commits) — judge only the newest commit's build.
- Xcode Cloud reports as a **legacy commit status context** (`BudgieBreedingTracker | Default`), not a `ci.yml` check-run — so it alone drives the "Status:" line in `check_remote_status.py`.
- It builds **only the push tip**. Intermediate commits of a multi-commit push never get a context, and GitHub returns `state: pending` for any commit with zero status contexts (`total_count: 0`) — so those middle commits stay `pending` forever. Chase only the tip SHA.
- The context can land **~1 hour after** every GitHub Actions job is already green. All check-runs `completed:success` with `in_progress: 0` and only the commit status `pending` = waiting on Xcode Cloud, not a failure.
- There is **no path filter**: docs-only and test-only push tips trigger builds too. Do not conclude "no source changed, so Xcode Cloud skipped it" (a 2026-07-23 sweep formed exactly that wrong theory; a 20-commit scan refuted it — the non-triggering commits were all push intermediates, and a 0-`lib/` tip still built). The workflow definition lives in App Store Connect, not the repo, so this is empirical, not config-read.

## Post-Push Verification

Do not declare CI green from UI badge alone. Verify exact commit SHA:
```bash
python3 scripts/check_remote_status.py
```

Success = commit status `success` + all **required `ci.yml`** check-runs
`completed:success` (known/intentional skips OK). The branch badge (e.g.
`17/19`) also turns red when a **non-required** check fails: the auto-generated
`pages-build-deployment` / `deploy` job (GitHub Pages site from `docs/`)
commonly fails transiently — `Deployment failed, try again later.` or a legacy
build stuck in `building`. That is a GitHub-side Pages-infra transient, not a
code failure and non-blocking; re-run at most once, it self-heals on the next
push. Do not chase it or count it against the push. Stale green from an earlier
commit is not evidence. (Rule: `ci-actions.md` § Non-Required / Transient
Checks.)

One intentional main-CI skip has an additional safety dependency:
`Deploy Edge Functions` may be `completed:skipped` for a path-gated push only
when `Edge Function Changes` is `completed:success` on the same exact commit.
`check_remote_status.py` enforces this pairing; a failed or missing detector
keeps the remote state unclean.

## See Also

- [[infrastructure/edge-functions]] — deploy pipeline
- [[infrastructure/branch-workflow]] — branch protection
- [[infrastructure/scripts]] — quality scripts
