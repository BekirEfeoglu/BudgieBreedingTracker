# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

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

## [2026-07-26] release | Version bumped to 1.1.8+60

Two surfaces, because the version name is duplicated: `pubspec.yaml` (the source
iOS and Android both derive from) and `AppConstants.appVersion` (a hand-kept
copy rendered in the About section). `app_constants_test` asserts they match, so
they cannot drift silently — but a bump has to touch both.

Build number jumps 56 → 60 at the user's request. Play version codes are
package-global and Codemagic no longer resolves this, so exceeding the highest
code across ALL tracks is a manual pre-upload check.

Note `ios/Flutter/Generated.xcconfig` still reads the OLD version after a bump:
it is gitignored and only a `flutter build` rewrites it — `flutter pub get` does
not. Archiving from Xcode without running `scripts/build_release.sh ios` first
would package the previous version, the same staleness trap that shipped a
DSN-less release once.

## [2026-07-26] follow-up | The reverse-leg guard, the last unguarded ALTER, and an unreachable fix

**Two new cross-surface families (49 checks).** `check_rule_symbol_drift` proves
every symbol a doc NAMES exists; nothing proved a set the CODE defines is still
fully named. Both of the day's doc-drift findings were exactly that shape, so
guard classes must now be named in security.md § Route Guards and `FeatureFlags`
members in feature-flags.md. One-way — a rule may discuss a removed guard, not
omit a live one. Verified by deleting a mention of each and watching CI fail.

**The last unguarded column add.** `event_reminders` is created in v2→v3, and
`Migrator.createTable` materializes TODAY's definition — already carrying
`user_id`/`is_deleted`/`updated_at`. The v5→v6 step then ALTERed the same three,
so a database entering `onUpgrade` at v1 or v2 died on `duplicate column name`
and never opened. Window is exactly {1,2}; at v29 the live base is ~zero, so
this is hygiene, not an incident. Reproduced first — and the first fixture
failed on `birds.color_mutation` instead, because materializing the current
schema means a v2 fixture must strip every column the UNGUARDED v5/v7/v13/v15/
v17 steps add. Only then did the failure land on the statement under test.

**An "untested fix" that turns out to be unreachable.** `5845415` threaded
`onDepthLimit` into the nested `_inbreedingOf` traversal with no test, and the
existing depth test cannot fail (its shared ancestor is parentless, so the
nested path never runs). Measuring rather than assuming: that traversal restarts
depth at 0 but walks a SUBSET of the chain the top-level pass already walked,
starting deeper in absolute terms — so anything long enough to trip it there has
already tripped it here. Sweeping chain lengths 0..16 with and without the
propagation gave byte-identical results. No isolating test is possible; one
would pass regardless, which is the same vacuous-assertion trap fixed earlier
today. The propagation stays (it stops being redundant if the two bounds ever
stop sharing a chain), the finding is recorded in the source, and the test that
CAN fail — the `depthLimited` cutoff boundary — was added instead.

**Image-scan budget raised 10 → 30/min.** The scan runs once per image and the
largest legitimate burst is a premium post at 10 photos, so one attempt consumed
the whole per-user budget; any retry in the same minute returned 429, which
`ImageSafetyService` fails CLOSED into "image rejected". Same shape as the
client cooldown fixed hours earlier, one layer out. The Deno test pins the
relationship to the photo cap, not the number.
