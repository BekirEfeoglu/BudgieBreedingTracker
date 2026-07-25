# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-07-26] infrastructure | Gate parity guarded, test noise silenced, security script measured

**Gate parity** — eighth family, and it reproduces a bug that was real
yesterday: `verify_migration_drift.py` ran in CI's `code-quality` but not in
`run_local_quality_gate.sh`, so a migration structure problem only surfaced
after push. Nothing tied the two lists together. Now compared one-way (the gate
may run more — `verify_rules.py` lives in `rules-sync`). Verified non-vacuous by
deleting the line again and watching it go red.

**Test stdout: 5,161 lines → 49.** Three suites drive scripts whose whole job is
printing a report, so the pre-commit gate log ended with a fixture run's
legitimate `HATA: ... bulunamadi` — a red-looking line under a green gate.
Silenced per module; unittest writes results to stderr, and the tests that
assert on output still capture into their own buffer.

**`verify_security.py` is now measured** instead of excluded. Its exclusion
comment claimed "not unit-testable business logic"; it has 31 unit tests. The
new test asserts a real property rather than chasing lines: every check that
asserts a file's CONTENT must fail when that file is missing — the expensive
failure mode is a moved file leaving `security-audit` green. Deliberately split
out the one check that asserts an *absence* (`no_service_role_in_client`), which
correctly passes on an empty tree. 89% → 92%, and the total still clears 99%
with it included.

Also corrected in the public README: the coverage threshold (98→99), the test
count (8,930+ → 11,700+) and the anti-pattern category count (21 → 28). The
98→99 sweep had missed it because the search was scoped to CLAUDE.md,
`.claude/rules` and the wiki — never the repo root.

## [2026-07-25] infrastructure | Spacing scale derived, local gate matched to CI, coverage 100%

**The Spacing scanner now derives its scale from `AppSpacing`** instead of
hardcoding it — and it had already drifted: `AppSpacing.xxs = 2` existed while
the scanner's set stopped at `4.0`, so a hardcoded `2.0` was never reported.
Deriving removes the drift class rather than guarding it, which is the better
answer when two surfaces *can* be unified. The old set stays as a floor: a parse
failure must never shrink the set and silently switch the scanner off. Adding
`2.0` produced zero new violations, verified before the change.

**The local gate was missing a CI check.** `run_local_quality_gate.sh` ran four
of `code-quality`'s five checks; `verify_migration_drift.py` was CI-only, so a
migration structure or baseline problem only surfaced after push. Added. The
guards themselves were already covered locally via `verify_rules.py --strict` —
that half of the suspicion was wrong.

**Script coverage is 100% across all eleven files** and the CI threshold moves
98 → 99. Not 100: leaving one line of headroom means a single new branch does
not turn the build red before its test lands.

## [2026-07-25] infrastructure | Column guard, quality-scanner coverage, guards tabulated

**Column names** — eighth check, seventh family. A `*Col<Name>` constant naming
a column no migration declares fails at query time, same as the table guard one
level down. Deliberately NOT table-scoped: the same `user_id` constant is reused
across tables, so it answers "does this column exist anywhere". That is weaker
than a per-table check but catches the typo class, which is the part that
reaches production. 101 constants, all declared; a typo'd one turns it red.

**`verify_code_quality.py` 99% → 100%.** The gap was entirely in *skip*
branches — the paths where a scanner stays silent. A scanner that goes quiet in
the wrong place is worse than one that over-reports: CI stays green and nobody
looks. Covered the layer-import ValueError path (a relative import resolving
outside the repo), the IconButton window heuristics, the ProviderContainer
no-closing-paren window, and the no-match early exits.

Three `continue` lines there — plus one in `_rules_collectors` — are marked
`# pragma: no cover`. They are the same CPython artifact: a `continue` closing
an `if` inside a `for` emits no trace event, so the line reads as uncovered
while its `if` above is covered and the tests prove the branch is taken. Ten of
eleven scripts are now at 100%.

**The guards are now one table** in documentation-sync.md instead of seven
prose bullets, with an explicit direction column — two-way vs one-way was the
thing that could not be seen at a glance. It also records the two deliberate
non-rules (route constants need not be referenced; columns are not
table-scoped), both instances of missing-name != missing-feature.

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

