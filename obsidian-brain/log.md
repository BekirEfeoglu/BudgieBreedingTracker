# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-07-25] infrastructure | Storage bucket ids guarded; migration-drift coverage 93% → 100%

Third member of the repeated-literal family after release artifacts and Edge
Function names. A bucket id is written in `SupabaseConstants`, provisioned by a
migration, and described in `assets-images.md`, with nothing tying the three
together — and a constant naming an unprovisioned bucket fails at *upload* time,
not at build time. `verify_rules.py` § Storage Buckets now compares constants ↔
migrations two-way (reading both real shapes: `storage.buckets` DDL/DML and
`bucket_id = '…'` in objects policies) and requires every constant to appear in
`assets-images.md`. The doc direction is one-way on purpose: that rule
deliberately names `health-records` and `chat-attachments` as buckets that do
NOT exist, so a reverse check would flag its own warnings. All three surfaces
currently agree on exactly eight buckets; both checks verified non-vacuous.

`verify_migration_drift.py` went 93% → 100% with tests for every
`load_applied_baseline` rejection branch (field count, sha256 shape, malformed
filename, remote-version shape, duplicate local, duplicate remote), the
malformed-JSON ledger fallback, and both `main()` baseline-path branches. Script
total holds at 98%.

## [2026-07-25] infrastructure | Edge Function names guarded, obfuscation map shipped, --fix hint made honest

Three follow-ups to the entry below. (1) `release-ready.yml` now uploads
`build/app/obfuscation.map.json` alongside the native debug symbols. **The
justification first committed here was wrong** and is corrected in a follow-up:
`flutter symbolize` does NOT consume the map — `flutter symbolize --help` shows
it takes only `--debug-info` (the split-debug-info symbols file) and `--input`.
The map is the separate identifier name-mapping Sentry reads via
`sentry: dart_symbol_map_path`; it ships in the artifact because it is the only
build output carrying that mapping and would otherwise be discarded after the
upload. Two paths make `build/` the artifact root — **verified by running
`release-ready.yml`** rather than reasoning about it: the artifact holds exactly
`app/obfuscation.map.json` (2.1 MB, 133,110 entries) plus the three ABI symbol
files at `symbols/android/`, so the map ships and the root change did not drop
the symbols.
(2) `verify_rules.py` gained an **Edge Functions** section: directories under
`supabase/functions/` ↔ `config.toml` `[functions.*]` ↔ the `ci.yml` deploy list
compared two-way, plus every name literal in `edge_function_client.dart`
(including `_rateLimitExempt`, where a stale entry fails silently by just not
exempting) resolving to a real function. Client direction is one-way — webhook /
trigger / cron functions have no client caller by design. Each of the three
checks was verified non-vacuous by mutating its surface. (3) The summary no
longer suggests `--fix` for cross-surface failures, which `--fix` cannot repair;
those now print a "sync the surfaces by hand" hint instead.

Sweeping for the same drift class found two more stale iOS claims this wiki
still carried — `build_release.sh ios → IPA` and `xcrun altool` distribution —
now corrected to the archive. Note the limit of the new guard: it compares path
*tokens*, so it catches a wrong path but not a wrong prose claim about what a
script produces. Those still need the manual semantic pass.

## [2026-07-25] infrastructure | Release artifact paths are now a CI-enforced cross-surface check

Follow-up to the entry below. Correcting the iOS artifact path updated
release-ops.md, ci-cd.md and the store-release skill but missed CLAUDE.md
§ Release Builds — the surface loaded into every session — and every existing
gate stayed green, because all of them count things and none encodes "these
surfaces must name the same artifact". `verify_rules.py` gained a **Release
Artifacts** section (`extract_markdown_section` + `extract_release_artifact_paths`
in `_rules_collectors.py`): every `build/…` path claimed in CLAUDE.md § Release
Builds must appear in release-ops.md **and** in a real producer
(`scripts/build_release.sh` / `release-ready.yml`). Both checks are tracked, so
they fail `rules-sync`, not just warn. Verified non-vacuous by restoring the old
`build/ios/ipa/*.ipa` line and confirming the run goes red.

Also corrected in the same pass: four surfaces described the build as using
`--obfuscate --split-debug-info --save-obfuscation-map`, but
`--save-obfuscation-map` is **not** a `flutter build` flag — `flutter build
appbundle --help` has no such option; it reaches the Dart native compiler only
via `--extra-gen-snapshot-options`. The map lands at
`build/app/obfuscation.map.json`, which is what `pubspec.yaml`'s
`sentry: dart_symbol_map_path` points at. Re-verified as correct in the same
sweep: the release-ready.yml artifact names, and the claim that
`build_release.sh` regenerates `DartDefines.xcconfig` (true, via `flutter build`).

## [2026-07-25] release-ops | First real release build corrected the iOS artifact path

Ran `scripts/build_release.sh ios` end to end with a real Sentry token. Symbol
upload works: 127 debug files + the Dart obfuscation map uploaded, release
`com.budgiebreeding.tracker@1.1.7+56` created and finalized. But the build stops
at `build/ios/archive/Runner.xcarchive` — `flutter build ipa` cannot export an
IPA without an export-options plist, which Codemagic used to generate via
`xcode-project use-profiles` and nothing replaces locally. The script (and
release-ops.md, ci-cd.md, the store-release skill, CLAUDE.md § Release Builds)
claimed `build/ios/ipa/*.ipa`, a path that does not exist in this setup; the
script now reports whichever artifact was actually produced and fails if neither
is there. Found only by running it — every static check passed while the guidance
was wrong. CLAUDE.md was missed in the first pass and corrected in a follow-up:
release/deploy changes must land the owning rule AND CLAUDE.md together
(documentation-sync.md).

## [2026-07-25] security | TLS pin rotation lead time is now a CI gate

`security.md` required replacement fingerprints ≥14 days before expiry, but
nothing enforced it — a lapsed pin set leaves the app unable to reach the
backend at all, fixable only by a store release. `check_certificate_pin_freshness`
reads the earliest `valid <start> through <end>` comment above the pins and
fails `security-audit` inside that window (harsher message once expired);
39 → 40 controls. Writing the tests exposed a bug in the check itself: those
comments wrap, so the RSA leaf's date sits behind a `//` on the next line and
the first regex skipped it — both pins share an expiry, so the output looked
right while only one was read. Comment markers are now stripped before
whitespace is collapsed. Also audited GitHub secrets after the Codemagic
removal: all 12 are still referenced by workflows, nothing orphaned (the Play
credential lived in Codemagic's own env group, never on GitHub).

## [2026-07-25] release-ops | Codemagic removed; docs moved to script + artifact-only releases

Docs-only. `codemagic.yaml` was deleted (user decision), so all three workflows
it described (`android-release` → Play alpha, `android-verify-only`,
`ios-release` → TestFlight) are gone and **no hosted release pipeline remains** —
nothing publishes to a store automatically. Rewrote the release surface across
13 files: iOS is now `scripts/build_release.sh ios` + manual Organizer/`altool`
distribution; Android is `release-ready.yml` (artifact-only) with
`scripts/build_release.sh android` as the local equivalent. Documented the new
script's contract (fail-fast on `SENTRY_DSN` in `.env` / exported
`SENTRY_AUTH_TOKEN`, obfuscation + `sentry_dart_plugin` symbol upload with a
per-platform `SENTRY_RELEASE` matching `PackageInfo`) and the hazard it exists
for: `ios/Flutter/DartDefines.xcconfig` is gitignored and only a `flutter build`
rewrites it, so a raw Xcode Archive can ship a stale config — a found copy had
the legacy Google web client ID and **no** `SENTRY_DSN`. Called out that Play
version codes are package-global and are no longer resolved automatically
(now a manual pre-release check). Preserved the Flutter `3.41.4` pin rationale
(2026-07-18 `stable` drift to 3.44.6 broke locked `lucide_icons`) where it still
applies, on `release-ready.yml` + Xcode Cloud. Security controls 37→39.
known-gaps: artifact-only publishing recorded as a deliberate absence. Rotated
ten 07-17/07-18 entries into [[log-archive-2026-07-m]].

## [2026-07-25] audit-followup2 | Founder demotion-to-NULL failed open

Verifying the founder promotion fix end-to-end (rollback-wrapped simulation on
prod) surfaced a second, worse bug in the same trigger: demoting a privileged
user by setting `profiles.role = NULL` did NOT revoke their `admin_users` row.
`NEW.role NOT IN ('admin','founder')` is NULL — not TRUE — when NEW.role is
NULL, and NULL is the ordinary-member role here (162 of 164 profiles), so this
is the normal demotion path, not an edge case. The pre-existing
`NEW.role <> 'admin'` had the same hole, meaning revocation this way never
worked. Unlike 20260725043351 (failed closed) this fails OPEN. Fixed with
COALESCE in migration `20260725060242`; all four transitions re-verified by
simulation; zero stranded rows needed backfill. Also updated the GitHub
`GOOGLE_*_CLIENT_ID` secrets to the new OAuth project and closed issues
#25/#28/#29 as already-fixed.

## [2026-07-25] audit-followup | Closed the audit's deferred items

Second batch after the aspirational-contract sweep. Founder role never synced
into `admin_users` (promotion also DELETED an existing admin row) — both
trigger functions now mirror the role; migration `20260725043351` applied to
prod and repaired one live stranded account. Sync PUSH path gained
`reportPushFailure` (it had no counterpart to `reportPullFailure`, so
corruption-class failures looped silently); mfa-lockout, conflict
snapshot/restore and the AAL2 inner catch now reach Sentry with payload-free
synthetic exceptions. Weekly `E2E and Community Test` had been red since
2026-07-13: the 800x600 test surface is shorter than the register form, so its
submit button laid out off-viewport and `tap()` hit the scrollable — fixed with
a portrait surface. Edge handler tests 257→267 (send-push authorization,
Apple/502 revoke branches, scan-image-safety 413 remap), each verified
non-vacuous by mutation. Retired the expired Supabase leaf pin after
confirming both live leaves match. Genetics `depthLimited` now propagates
through nested F_A. Migration count 217→218.

## [2026-07-25] audit | Aspirational-contract sweep: rules/wiki reconciled to code

Docs-only. Rewrote claims that asserted current behavior the code never had:
gamification XP table (real 11-entry `xpValues` + 3 daily caps), no level cap,
leaderboard is all-time top-100 only (no monthly/self-rank/TTL/materialized
view), XP award is a network write; marketplace monetization tier (boost, renew,
expiry, 7-day edit window, premium photo quota, phone opt-in) does not exist and
soft-delete is `is_deleted`; notification channels are the five
`NotificationChannelConfig` ids + `default` with no per-channel importance, and
send-push is `BATCH_SIZE=50` within `MAX_TOKENS=500`; deeplink payload is a
`'<type>:<id>'` string resolved by `payloadToRoute`, not JSON with a `route`;
calendar event types come from the real 18-member `EventType`, the feed uses
`watchAll` + in-memory month filtering on `eventDate` (no `start_at` range
query); DM push is not shipped. Constants corrected: community cache 5 min /
`maxScroll - 200` px / no like cache, DM page 50 with `content`+`created_at`
columns, admin health 5 min, `EggStatus` has 9 members. Fixed 6 wrong migration
timestamps and the auth logout order (FCM deactivation runs before `signOut` for
RLS). Recorded this session's code changes: genetics `calculationVersion` v9,
Drift shared-index `_tableExists` guard, ads on `effectivePremiumProvider`
(param renamed `premiumAccessProvider`), release builds ignore `ALLOW_PROXY`,
new Sentry reports for exhausted decrypt keys / `getFactors` fail-open, and the
signed-URL logging precedent. known-gaps +8.
