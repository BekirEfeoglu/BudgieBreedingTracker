---
name: store-release
description: Orchestrate a store release end-to-end for BudgieBreedingTracker — version-bump consistency (pubspec ↔ iOS/Android), 3-language release notes for the system_settings.app_version JSON, go/no-go readiness gate, and the Codemagic/Release-Ready trigger checklist. Use when the user wants to cut a release, ship to TestFlight/Play, bump the version, or prepare release notes. It gates and prepares; it does not sign or publish on the user's behalf.
allowed-tools: Read, Grep, Glob, Bash, Edit, Task
---

# Store Release Orchestration

> Ties together the pieces that already exist (release-readiness-agent, post-push-verifier, release-ops.md) into one uncut path. App Store App ID `6759828211`; releases go via Codemagic (App Store TestFlight + Google Play alpha), not GitHub Actions.

## When to use
User wants to cut a release, bump the version, ship to TestFlight/Play, or draft release notes. Read `.claude/rules/release-ops.md`, `ci-actions.md`, and `branch-workflow.md` first.

## Step 1 — Confirm main is clean on the exact SHA
Release from a verified-green `main`. Never cut from a red or unverified commit.
```bash
python3 scripts/check_remote_status.py
```
Or dispatch `post-push-verifier`. Required `ci.yml` check-runs must be `completed:success` (Pages `deploy` transient is non-blocking). If not green, STOP — resolve CI first.

## Step 2 — Version bump (consistency is the gate)
- Edit `pubspec.yaml` `version: X.Y.Z+build` — semver: major=breaking, minor=feature, patch=fix; **always** increment the build number.
- Verify iOS and Android build numbers stay consistent with pubspec (release-ops.md § Version Bump). Grep native config if they can drift.
- Confirm no documented dependency cap was lifted (supabase_flutter <2.13.0 etc.) as part of the release prep.

## Step 3 — Release notes in 3 languages
The update prompt reads `system_settings.app_version` (see app-update.md): `release_notes_tr` / `release_notes_en` / `release_notes_de`.
- Draft concise notes in Turkish (master) first, then English + German — real translations, not machine-literal (mirror the l10n workflow / l10n-agent quality bar).
- If `minSupportedBuild` is being raised, treat it as a deliberate release decision (it hard-locks older users) — call it out explicitly, don't bump it silently.

## Step 4 — Go / no-go readiness gate
Dispatch `release-readiness-agent` for a read-only go/no-go:
- version+build bumped consistently across pubspec ↔ native config
- exact-SHA `main` fully green (incl. Pages-transient discrimination)
- Xcode Cloud `Build - iOS` + App Store Connect status success on the SAME commit (build-only workflow; archive/TestFlight export only if signing + registered devices are ready — do NOT flip that here)
- release-ready.yml / Codemagic preconditions hold

## Step 5 — Trigger the release (user-driven publish)
- **iOS/Android production**: Codemagic (`android-release` → Play alpha, `ios-release` → TestFlight). This is the user's action — surface the checklist and preconditions; do NOT publish on their behalf.
- **Manual signed Android AAB**: the `Release Ready` workflow is manual (`workflow_dispatch`); confirm its preconditions before the user triggers it.
- Environment discipline: secrets live in Codemagic env groups / CI secrets, never in code; the new Google OAuth `GOOGLE_*_CLIENT_ID` values must be set before a signed build (security.md OAuth migration).

## Step 6 — Post-release closure
- After the build runs, confirm Xcode Cloud + App Store Connect status are `success` on the exact commit; wait for late-arriving checks before declaring closed.
- Commit the version bump + release-notes migration/config together with a `chore(release): vX.Y.Z+build` message.
- Update `CLAUDE.md` / docs if any release metric drifted (`verify_rules.py --fix`).

## Handoff
Report: the version+build, the 3-language notes, the go/no-go verdict with evidence, what the user still needs to trigger manually (Codemagic/Release-Ready), and any minSupportedBuild lock decision. Respond in Turkish per chat.md.
