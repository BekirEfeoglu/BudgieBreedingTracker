# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-07-25] infrastructure | Table-name guard; --sha already existed

**`check_remote_status.py --sha` has existed all along.** Three polls in this
session retargeted themselves and timed out, and I proposed adding a SHA
argument to fix it — the flag was already in `parse_args`. The failures were
misuse, not a missing feature: with no argument the script re-reads the CURRENT
local HEAD on every call, so a poll started before another commit follows the
new one. ci-actions.md's example now passes `--sha "$(git rev-parse HEAD)"` and
says why. No code was written for this.

**Supabase table names** — seventh guard. A `*Table` constant naming a table no
migration creates fails at query time with a Postgres error, never at build
time. One-way by design: migrations legitimately create tables the client never
names (`private.*` helpers, trigger-written audit tables). Keyed on the constant
NAME suffix, not its value — `adminExportAllTablesRpc` holds
`'admin_export_all_tables'` and a value-keyed regex flagged it as a missing
table before the rule was tightened. 77 constants, all provisioned. Verified
non-vacuous both ways: a ghost table turns it red, an RPC constant does not.

`_rules_collectors.py` reached 100% by marking the one uncovered line
`# pragma: no cover` — a `continue` that CPython emits no trace event for. The
test exists and the behavior is verified directly; the gap was the measurement,
not the coverage. Eight of eleven scripts are now at 100%, total 99%.

## [2026-07-25] infrastructure | 64-byte map mystery closed; route targets guarded

**The 64-byte difference is solved by downloading the file.** The map Sentry
stores is not the local map: `sentry_dart_plugin` prepends two entries to the
JSON array — `"SENTRY_DEBUG_ID_MARKER"` and the paired binary's debug id.
Compact that is 25 + 39 = exactly 64 bytes, and entries 3..133,112 are identical
to the local array. This independently confirms the triple upload is structural:
each copy carries a *different* debug id, so they are three distinct files.

**Route targets** — sixth guard, and the first that is deliberately NOT a
bijection. GoRouter composes nested paths from relative literals, so
`/chicks/:id` is never a `path:` value and 12 constants are never referenced by
name; they are reached by `context.push('/chicks/$id')`. A "every constant must
be referenced" rule would flag all 12 — the missing-name != missing-feature trap
this wiki's contract warns about. Two sound checks instead: no two constants may
share a path value, and every string navigation target must resolve to a
declared route (a typo'd `context.push` compiles and 404s only at runtime).
Both verified non-vacuous; the repo is currently clean on both.

`check_obsidian_brain.py` reached 100% — and writing the tests found dead code:
the `if not moved` guard in `rotate_log` is unreachable, because the caps were
already checked against the same text. Removed rather than left untestable.
Scripts total 99%.

## [2026-07-25] infrastructure | Icon bijection guarded; the triple map upload is correct, not waste

**Chased the triple obfuscation-map upload and the suggestion was wrong.** The
CI log settles it: `sentry_dart_plugin` pairs the map with each ABI symbol file
and registers it under that binary's own debug id — three uploads, three debug
ids, `attempted=3, succeeded=3`. A crash carries the debug id of the
architecture it came from, so collapsing to one upload would break
de-obfuscation on the other two ABIs. Recorded in release-ops.md as a
do-not-optimize. **The 64-byte size difference is now explained too**, by
downloading the uploaded file: `sentry_dart_plugin` prepends two entries to the
JSON array — the literal `"SENTRY_DEBUG_ID_MARKER"` and the paired binary's
debug id. Compact, that is 25 + 39 = exactly 64 bytes, and the remaining 133,110
entries are byte-identical to the local map. This independently proves the
triple upload is structural: each copy embeds a *different* debug id, so they
are three distinct files, not three copies of one.

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
other two ABIs. Do not "optimize" it. The 64-byte size difference was chased in
the entry above and is explained: the plugin prepends a debug-id marker pair to
the JSON array.

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

