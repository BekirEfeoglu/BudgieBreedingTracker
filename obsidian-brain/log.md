# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-07-25] infrastructure | Icon bijection guarded; the triple map upload is correct, not waste

**Chased the triple obfuscation-map upload and the suggestion was wrong.** The
CI log settles it: `sentry_dart_plugin` pairs the map with each ABI symbol file
and registers it under that binary's own debug id — three uploads, three debug
ids, `attempted=3, succeeded=3`. A crash carries the debug id of the
architecture it came from, so collapsing to one upload would break
de-obfuscation on the other two ABIs. Recorded in release-ops.md as a
do-not-optimize. The 64-byte size difference remains unexplained and unchased.

**SVG icon bijection** — fifth cross-surface family. The two counts were already
compared (99 constants == 99 files), but *which* constant points at *which* file
was not, so a renamed asset keeps both counts right and fails only at runtime,
where flutter_svg renders nothing rather than throwing. Now two-way. Verified
non-vacuous by typo'ing one path: the count check stays green and the bijection
goes red. Writing it also surfaced a stale `/// 93 icons` doc comment in
`app_icons.dart` (real count 99) — unmanaged by the inline fixer, which only
walks CLAUDE.md and `.claude/rules/`.

`check_platform_targets.py` 93% → 100%: the empty-`web/`-directory branch (a
bare `web/` is not a Flutter web target) and each of the three markers now have
cases. Scripts total 99%.

## [2026-07-25] infrastructure | Log rotation automated, l10n category names guarded

Two more follow-ups plus one external verification.

**`check_obsidian_brain.py --rotate`.** The 200-line / 30-entry caps were
enforced but rotated by hand — three re-derived edits every time (move the
oldest entries, widen the archive's date range, widen the index row), done
twice in this session alone. `--rotate` does exactly those three and refuses
rather than overflowing the target archive, because a NEW archive page needs an
index row and a description a script should not invent. The target archive is
chosen **by content**, not filename: `log-archive-2026-07-b.md` sorts before
`log-archive-2026-07.md` lexicographically, so filename order would pick the
wrong one. Coverage 89% → 97%.

**L10n category names.** Fourth cross-surface family. The category *count* was
already verified against `tr.json`; the *names* were not, so a renamed category
kept the count right while `localization.md`'s list rotted. Now compared
two-way. Verified non-vacuous by renaming one entry — count stays 41, check goes
red.

**Sentry upload confirmed** for the release build: `sentry api .../files/dsyms/`
shows the three ABI symbol files and `obfuscation.map.json` at 14:43–14:44 UTC.
The map is uploaded three times per run, which this entry first recorded as
waste. **It is not** — the CI log settles it: `sentry_dart_plugin` pairs the map
with each ABI symbol file and registers it under that binary's own debug id
(`attempted=3, succeeded=3`). A crash carries the debug id of the architecture
it came from, so collapsing this to one upload would break de-obfuscation on the
other two ABIs. Do not "optimize" it. Still unexplained and not chased: Sentry
reports the map 64 bytes larger than the local file while all three symbol files
match byte-for-byte.

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

