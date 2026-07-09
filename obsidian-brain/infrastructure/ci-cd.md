# CI/CD

Source: `.claude/rules/ci-actions.md`, `.claude/rules/release-ops.md`, `CLAUDE.md`

## GitHub Actions (`ci.yml`)

Runs on PRs and main pushes.

| Job | Purpose | Blocker |
|-----|---------|---------|
| `analyze` | `flutter analyze --no-fatal-infos` | PR merge |
| `test` | Unit + widget tests (step timeout 30m, job-level 40m) | PR merge |
| `golden-test` | Visual regression (Linux baseline) | PR merge |
| `edge-functions-test` | `deno test` on `supabase/functions` | PR merge + Edge deploy gate |
| `e2e-community-test` | E2E + community tagged tests | `workflow_dispatch`/`schedule` |
| `scripts-test` | Python script tests (≥98% coverage) | PR merge |
| `l10n-sync` | Translation key parity (--strict-keys) | PR merge |
| `code-quality` | Anti-pattern scan + platform target policy + wiki lint + migration structure drift (`verify_migration_drift.py`) | PR merge |
| `rules-sync` | CLAUDE.md stats verification | PR merge |
| `security-audit` | `python scripts/verify_security.py` — cert pinning, secrets | PR merge |
| `auto-fix-stats` | Auto-PR for CLAUDE.md drift | main only |
| `deploy-edge-functions` | Supabase Edge Function deploy | main only, needs analyze+test+edge-functions-test |
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
- Workflow YAML must be locally parsed before push: `ruby -e 'require "yaml"; YAML.load_file(ARGV[0])' .github/workflows/ci.yml`

## Codemagic (`codemagic.yaml`)

Production releases:
- `android-release`: AAB → Google Play (alpha track)
- `ios-release`: IPA → App Store TestFlight (App ID: 6759828211)

## Release Ready (`release-ready.yml`)

Manual workflow for signed AAB readiness. Does not run on main push (to avoid slowing CI).

## Xcode Cloud

- Build-only (`Build - iOS`, scheme `Runner`, Any iOS Simulator)
- Archive/TestFlight only when Apple signing + provisioning profile + registered device ready
- `ios/ci_scripts/ci_post_clone.sh`: runs `flutter pub get`, `dart run build_runner build`, `pod install`
- Must be executable. Retry/backoff on pod download failures.
- `build_runner` is wrapped in a clean-and-retry loop (cap 5, `build_runner clean` between attempts) — the drift_dev 2.31 "Circular error" codegen flake failed post-clone (action_required, ~47s) when it was a bare call. Keep both ci.yml AND this post-clone retry-hardened; they are separate systems.

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
