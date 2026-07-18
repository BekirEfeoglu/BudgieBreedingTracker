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
| `scripts-test` | Python script tests (≥98% coverage) | PR merge |
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

## Codemagic (`codemagic.yaml`)

Release and verification workflows:
- `android-release`: AAB → Google Play (alpha track)
- `android-verify-only`: signed AAB + Sentry symbols → Codemagic artifacts only;
  no `publishing` block, Google Play credential, or latest-build query
- `ios-release`: IPA → App Store TestFlight (App ID: 6759828211)
- All three workflows require `SENTRY_DSN` in `app_env_vars`; missing monitoring
  configuration fails before the store build starts.
- All three workflows require the `org:ci`-scoped `SENTRY_AUTH_TOKEN`, generate the
  Dart obfuscation map, and run `sentry_dart_plugin` before publishing.

## Release Ready (`release-ready.yml`)

Manual workflow for signed AAB readiness. Does not run on main push (to avoid
slowing CI). It requires the GitHub Actions `SENTRY_DSN` secret and injects the
`production` environment into the release build. Its `SENTRY_AUTH_TOKEN` is
used only for symbol upload and is never passed into the app binary.

## Xcode Cloud

- Build-only (`Build - iOS`, scheme `Runner`, Any iOS Simulator)
- Archive/TestFlight only when Apple signing + provisioning profile + registered device ready
- `ios/ci_scripts/ci_post_clone.sh`: installs Flutter, runs `flutter pub get`, `dart run build_runner build`, `pod install`; must stay executable, retry/backoff on network steps
- **Flutter install = curl+unzip of the pinned arch-aware SDK zip** (`flutter_macos[_arm64]_3.41.4-stable.zip`) — NEVER `git clone flutter/flutter`: that clone is known-flaky on Xcode Cloud (flutter/flutter#163198) and was the true root cause of the recurring ~40s `Build - iOS` action_required (2026-07-09). First curl-based build passed with a full ~9-min build.
- drift_dev's "Circular error when deserializing drift modules" is a **non-fatal WARNING** (simolus3/drift#3227) — it never fails `build_runner`; do not chase it as a post-clone failure cause. The clean-and-retry loop (cap 8) remains as belt-and-braces.
- The script prints `>>> STEP N:` markers before every step; Xcode Cloud only surfaces a generic "script failed (exited with code 1)", so the LAST marker in the log names the failing step. Keep the markers.
- Rapid successive main pushes can make Xcode Cloud supersede intermediate builds (`action_required` on middle commits) — judge only the newest commit's build.

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

## See Also

- [[infrastructure/edge-functions]] — deploy pipeline
- [[infrastructure/branch-workflow]] — branch protection
- [[infrastructure/scripts]] — quality scripts
