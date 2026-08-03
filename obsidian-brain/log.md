# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-08-03] fix | Full-sync FK tombstones and payment-log redaction

Full reconciliation now keeps soft-delete tombstones in Drift so historical
children can resolve their FK parents; this fixes completed incubations failing
to pull after their breeding pair was soft-deleted. Unexpected repository pull
failures now reach the layer-isolating handler, preventing a false "pull
complete" result and checkpoint advance. RevenueCat logging is capped before
configuration so simulator StoreKit transaction/JWS dumps do not expose payment
artifacts.

## [2026-08-03] test | Breeding gate proves production boundaries

The breeding/egg focused gate now covers the real Drift transaction plus direct
notification/calendar tests instead of provider mocks alone. Executable scope
tests prove representative paths select the suite, whose manifest now rejects
skipped or slow-tag-excluded tests. Real-device scheduling, RLS deployment
state, biological authority, and translation layout remain explicit manual
residuals.

## [2026-08-03] rules | Risk-based checklists and breeding gate routing

Feature work now begins with authority, offline/sync, authorization, rollback,
side-effect, and proof decisions instead of a model-only scaffold list. The
breeding/egg rule gained entry, transition, destructive-flow, scenario, and
definition-of-done checklists with automated/manual evidence mapping. The local
quality gate now includes untracked files and automatically runs the focused
breeding regression suite for matching lifecycle paths.

## [2026-08-02] release | Sentry symbol discovery isolated per platform

The iOS 1.1.9 release exposed a dirty-workspace failure: the broad
`symbols_path: build` setting paired the fresh Dart obfuscation map with six
stale Android debug IDs under `build/release-artifacts`. The incorrect Sentry
maps were removed while native Android and current iOS symbols were preserved.

The canonical local release now passes `build/symbols/<platform>` explicitly
and quarantines known stale, cross-platform build roots only for the duration
of symbol upload, restoring them through an EXIT trap. The hosted Android path
uses the same narrow override, and security/CI contract tests reject a return
to broad discovery.

## [2026-08-01] premium | Package loading and activation races hardened

Debug iOS Simulator no longer skips RevenueCat initialization. Empty current
offerings now fall back to an aggregate, deduplicated view of all offerings, so
legacy dashboard order cannot hide the two supported plans. Purchase and restore
actions ignore duplicate submits; an active store entitlement receives two
short server-reconciliation retries before failure, without trusting client
premium state. Paywall guidance now explains the direct-Xcode StoreKit path.

## [2026-07-31] data | Breeding integrity and visible-range calendar

Drift v30 now preserves at most one active chick link per egg and backs
visible calendar queries with a user/delete/date index. Supabase receives the
matching partial unique chick index; automatic chicks reuse the egg UUID so
multi-device offline hatches converge.

Pair + incubation creation now commits both entities and pending-sync rows in
one Drift transaction before ordered remote push. The calendar watches only
the active month/week/day half-open UTC range, and month navigation keeps the
selected day inside that range. Added fresh-schema, v29→v30, transaction,
provider, DAO, and widget regressions.

## [2026-07-30] feature | Toolchain parity, complete DM history/push, portable restore

Pinned local, GitHub Actions, release-ready, and Xcode Cloud Flutter resolution
to the single `.fvmrc` 3.41.4 manifest; reconciled `pubspec.lock` under that SDK.
Xcode Cloud now validates and installs the manifest version into a
version-scoped SDK directory.

DM threads now load older 50-row cursor pages on scroll-up. Persisted sends
request best-effort push through a strict `messageId` mode: service-role logic
verifies ownership, filters left/muted/sender participants, honors quiet hours,
uses lock-screen-safe copy, and deep-links validated
`message:<conversationId>` payloads.

Manual backup/restore gained a free, cross-device `.portable.enc.json` path:
PBKDF2-HMAC-SHA256 100K, random salt/IV, separated AES/HMAC keys and
encrypt-then-MAC. Restore first performs a non-mutating date/entity-count
preview and explicitly confirms merge-upsert consequences. Removed the three
closed gaps; wipe/conflict choices and the DM memory cap remain open.

## [2026-07-29] admin | Build adoption telemetry added

Presence session starts now record the installed semantic version and build,
while metadata failures remain fail-open. Added an admin-gated 30-day
user-platform rollup and localized Monitoring cards that expose both adoption
share and legacy-client coverage. Documented the coverage gate for rollout
decisions; production deployment remains a separate release operation.

## [2026-07-27] ci | Dependabot open PR caps tightened

Reduced monthly Dependabot concurrency from 10 to 5 for `pub` and from 5 to 3
for GitHub Actions. Synchronized the CI rule, PR checklist, root guide, and
CI/CD wiki; compatibility holds remain unchanged.

## [2026-07-27] ci | Dependabot cadence reduced to monthly

Changed both `pub` and `github-actions` version-update schedules from weekly
Monday runs to monthly checks on the first day of each month. Kept the existing
PR caps and compatibility holds; synchronized the CI contract across
CLAUDE.md, ci-actions.md, the PR template, and the CI/CD wiki.

## [2026-07-26] correction | The diagnostic that undid its own fix

The module-verifier fix was correct, but the Archive failed again 7 minutes
later — on `sqflite_darwin` this time, exactly the walk-down-the-list behaviour
predicted for the setting still being ON.

Cause was mine. Proving the fix used
`xcodebuild -project ios/Pods/Pods.xcodeproj -target <pod>`, and that rewrote
the generated project: 74 of 95 targets went back to `ENABLE_MODULE_VERIFIER =
YES` at 22:50, between the `pod install` that set them all to `NO` (22:46) and
the Archive (22:57). The experiment that established causation also destroyed
the state it had just verified.

Two things made it invisible. `ios/Pods/` is gitignored, so the corruption never
appeared in `git status` — the habit of reading git status after builds, which
caught the entitlements and scheme rewrites, cannot catch this one. And the
verification measured the setting BEFORE the build, not after.

Re-running `pod install` restored 285/285 `NO`. Verified the safe way this time,
through the path an Archive actually uses:
`xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release`
→ before 285 NO, `BUILD SUCCEEDED`, after 285 NO. The setting survives a
workspace build; it does not survive a direct `-project` build of the Pods
project.

Recorded in release-ops.md: verify pod settings through the workspace, and
measure the setting again AFTER the build, not only before.

## [2026-07-26] fix | Xcode 26's module verifier blocks every Flutter plugin

An Archive died on `'Flutter/Flutter.h' file not found` →
`could not build module 'package_info_plus'`. Root cause: Xcode 26 turns
`ENABLE_MODULE_VERIFIER` on by default in the CocoaPods-generated project — 222
configurations came out `YES`, and neither the Podfile nor Flutter's
`podhelper.rb` sets it. The verifier compiles each pod's umbrella header
STANDALONE, where the Flutter framework search paths do not apply, so any plugin
importing `<Flutter/Flutter.h>` fails it.

Established by controlled experiment rather than inference: the same pod target
built with `ENABLE_MODULE_VERIFIER=YES` reproduced the reported errors and
BUILD FAILED; with the Podfile setting (`NO`) it was BUILD SUCCEEDED.

Also checked whether one pod would have been enough — it would not.
`share_plus` and `sqflite_darwin` fail identically, so Xcode just reports
whichever it reaches first and a per-pod fix would walk the failure down the
list. The setting therefore applies to all pod targets. It validates the module
hygiene of third-party headers we do not control and does not affect the
produced binary; the app target is untouched.

`Podfile.lock` moved only its checksum — no pod version changed. CI's
`ios-build` was unaffected throughout because its Xcode predates the default.

## [2026-07-26] follow-up | A stale xcconfig was overriding the fresh iOS defines

**The documented mitigation could not work.** Verifying that the version bump
reached the iOS config turned up a live release hazard. Current Flutter writes
the dart-defines into `Generated.xcconfig` as base64 `DART_DEFINES`; it does NOT
write `ios/Flutter/DartDefines.xcconfig`, which older versions used — a full
build refreshed the former and left the latter at its March mtime.
`Release.xcconfig` includes the legacy file AFTER the generated one and both
define `DART_DEFINES`, so the four-month-old copy silently **overrode** the
fresh values. Decoded, it carried the legacy Google project (118599620356, not
the current 720334450619) and **no `SENTRY_DSN`** — precisely the
crash-reporting-less release `build_release.sh` documents itself as preventing,
while the script never touches that file. Deleted; the claim was corrected in
seven places that all pointed readers at the wrong file.

**iOS builds mutate TRACKED files.** The same run rewrote
`Runner.entitlements` and emptied `com.apple.security.application-groups` —
the container the home widget shares with the app — and later runs bumped
`LastUpgradeVersion`. All reverted. `build_release.sh ios` runs a flutter build
too, so read `git status` after it.

**Silent failure paths closed.** Google/Apple native sign-in terminal branches
and both fail-closed moderation branches logged with `AppLogger.error`, which
only adds a breadcrumb. A moderation outage blocks every upload and post
app-wide while showing users a generic rejection, with zero production signal.

**Two docs describing things that never existed.** observability.md specified a
structured JSON edge-function log schema and the Dashboard filtering it would
enable — measured: all 36 `console.*` calls across all 12 functions are plain
prefixed strings. And `SupabaseConstants.geneticsHistoryTable` was declared but
never referenced, making a dormant table with a never-matching schema look
like a live surface. Both moved to known-gaps.
