# Dependency Upgrade Notes

Running analysis of dependency bumps that are blocked, capped, or need a
coordinated upgrade. Update when a blocker clears or a new one appears. This is
a planning aid, not an authority — the pinned constraints in `pubspec.yaml` and
the caps documented in `CLAUDE.md` / `.claude/rules/architecture.md` remain the
source of truth.

Last reviewed: 2026-07-13.

## Blocked / held

### drift `^2.34.1` (Dependabot #150) — HARD BLOCK, hold at `^2.31.0`
Unsolvable transitive version conflict on the current toolchain:
- drift 2.34 → `drift_dev` → `analyzer ^13.0.0`
- `analyzer 13.x` → `meta ^1.18.0`
- but `flutter_test` (Flutter SDK 3.41.4) pins **`meta 1.17.0`**, and
  `riverpod_generator ^4.0.0` requires **`analyzer ^12.0.0`**

`flutter pub get` fails outright ("version solving failed"); pub itself
recommends `drift:^2.31.0`. **Preconditions to unblock, in order:**
1. A `riverpod_generator` release that accepts `analyzer ^13`.
2. A Flutter SDK bump whose bundled `flutter_test` allows `meta ^1.18`.
Only then can drift move to 2.34. Until both land, keep drift/drift_dev at
`^2.31.0`. Re-evaluate when the Flutter SDK pin (currently 3.41.4) is raised.

### supabase_flutter `2.13+` (Dependabot #149) — CAPPED, do not lift
Pinned `>=2.5.0 <2.13.0` for iOS CI. 2.13+ pulls passkeys →
`device_info_plus 12.4.0` (visionOS selector) which breaks the iOS CI build and
is not locally reproducible. See the `pubspec.yaml` comment + memory
`project_supabase_flutter_ios_cap`. Do NOT bump past the cap.

### sentry_flutter `10.0.0-alpha.2` (Dependabot #152) — SKIP (pre-release)
Alpha of a major (9.x → 10.x). Hold until a stable 10.x ships, then evaluate the
9→10 migration as its own task.

### supabase/setup-cli `v3.0.0` (Dependabot #147) — HOLD, do not merge as-is
CI-action major bump (v1.6.0 → v3.0.0). Two problems:
1. **PR CI never exercised it.** setup-cli is only used in the `deploy-edge-functions`
   job, which is `main`-only (`if: github.ref == 'refs/heads/main'`) and therefore
   SKIPS on the PR. The PR's green checks are a false comfort — the first real run
   of v3.0.0 would be on `main`, where a break blocks edge-function deployment.
2. **Pinned by tag, not SHA** (`@v3.0.0`), violating the repo convention
   (`.claude/rules/ci-actions.md`: pin actions by commit SHA).
To land safely: verify supabase/setup-cli v3 CLI-version compatibility with the
`supabase functions deploy` step, re-pin to the v3.0.0 commit SHA, and validate on
a throwaway `main`-targeting run (or accept the risk and watch the next `main`
deploy closely). Until then, hold #147.

## Landed (kept for context)

### purchases_flutter `10.3.0 → 10.4.1` — DONE (main `f92fda6`, 2026-07-13)
Bump was CI-red on the raw Dependabot PR. Root cause: purchases_flutter 10.4.x
exports its own `SubscriptionInfo`, colliding (`ambiguous_import`) with the app's
`SubscriptionInfo` (`lib/domain/services/payment/purchase_models.dart`) across
every file importing both. Fix: `hide SubscriptionInfo` on every
`purchases_flutter` import (5 lib + 13 test files — the app never uses the SDK
type). The bump also required `pod update PurchasesHybridCommon`
(18.15.1 → 18.19.0); the Dependabot pub bump did not sync `ios/Podfile.lock`,
which is why iOS Build failed too. Pattern for the next collision-class bump:
apply the source fix + lock bump together on the PR branch (a `hide X` of a
not-yet-exported name is a fatal warning under `--no-fatal-infos`, so it cannot
land on `main` ahead of the lock).

## Local environment note (not a repo issue)

`flutter --version` shows channel `[user-branch]` because the local SDK at
`~/development/flutter` is a **detached HEAD at the exact `3.41.4` tag**
(commit `ff37bef603`, byte-identical to CI's pinned stable 3.41.4). The label is
cosmetic; do NOT `flutter upgrade` to "fix" it — that would move past the 3.41.4
pin. A local `flutter pub get` can rewrite transitive test deps
(`meta`/`test`/`test_api`) versus the committed `pubspec.lock`; do not commit a
locally-regenerated lock — restore it to HEAD and let CI/Dependabot own it.
