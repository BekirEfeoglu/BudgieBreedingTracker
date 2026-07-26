# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-07-26] infrastructure | Skill posture settled, wiki inventories guarded, stub archives folded in

**`ui-ux-pro-max`'s posture was decided by its body, not its description.** The
catalog said `No` while the skill advertised "build, create, implement,
refactor" — a contradiction left open earlier. The body settles it: four steps
of analyze → run `search.py` → read guidelines, both scripts opening files
read-only, output documented as a terminal ASCII box or Markdown. Those verbs
are the skill's **trigger** ("When user requests UI/UX work (design, build,
create…), follow this workflow"), not its actions; it supplies a design system
the surrounding session implements, exactly like `mobile-design`. Both it and
`supabase-postgres-best-practices` gained `allowed-tools: Read, Glob, Grep,
Bash`, so all six skills now declare one. The posture check was then tightened:
an advisory row with no declaration is now itself a violation, because
`allowed-tools` restricts rather than grants — a `No` means nothing without it,
and these two are vendored, so a re-vendor would otherwise drop the line
silently. Consequence recorded rather than hidden: a restricted skill cannot
edit during its activation; deleting one line reverts it.

**Four wiki inventories guarded, none of which was actually drifting.** The
features index (24/24), services index (23/23) and tables catalog (20/20) were
complete — my first three probes said otherwise and were all my own regex's
fault, since those pages use `[[wikilinks]]` and full filenames rather than bare
backticked names. They are guarded anyway because `scripts.md` was 11 of 15
yesterday: same shape, same rot. Each page is matched by the exact token IT
uses, never a bare directory name — "more" and "home" are real feature modules
and a substring check would pass on any prose containing them.

**17 archive pages → 14, and deliberately not to 9.** The three hand-made stubs
(`06-early` 2 entries, `07-i` 1, `07-k` 5) folded into their chronological
neighbours; all 186 entries preserved, verified by comparing the date multiset
before and after. Merging the ~190-line pages would have gone further but was
rejected on evidence: dated entries still name those files (one in `07-f`
records rotating work "to [[log-archive-2026-07-f]]"), and fixing the link means
rewriting a dated entry, which this contract forbids. With the catalog no longer
riding in every session's context, the remaining benefit was tidiness. Two stale
navigation footers were corrected — both already wrong, one listing itself.

## [2026-07-26] infrastructure | Semantic sweep found three rotted inventories; archive cap raised

**The sweep's yield was inventories, not contracts.** Spot-checking constants
(`calculationVersion` 9, `maxAncestorDepth` 10, presence 2/5/10 min, comment
limit 1000), prose counts (EventType 18, EggStatus 9, XP 11 + 3 daily limits, 5
notification channels) and every `known-gaps.md` entry found **zero** drift —
those surfaces are accurate. Three hand-maintained *lists* had rotted instead:
CLAUDE.md § Script Tests named 13 of 15 test files, the wiki's script page 11 of
15, and `ai-workflow.md` had no routing row for `antipattern-manual-sweeper` or
`ui-ux-designer`, so nothing would ever route to them. All three fixed, then
guarded — a directory versus a prose list is precisely the shape the
cross-surface families exist for, and nothing had tied them together.

Also corrected: "all 11 scripts currently 100%" in CLAUDE.md and ci-actions.md
was wrong on both halves. There are 12 measured files and two are not at 100%
(`verify_security.py` 92%, `_rules_collectors.py` 99%). It went stale when
`verify_security.py` was brought into measurement earlier the same day and the
sibling surfaces were not updated — the exact half-landed-update class again.

**Skill write posture is now machine-read**, matching the agent read-only check.
A limit worth stating: `allowed-tools` *restricts* a session, so omitting it
grants nothing — unlike an agent profile, whose `tools:` list IS its complete
tool set. Two vendored reference skills declare none, so nothing holds them to
their `No` posture; that is recorded in skills-index rather than papered over,
because `ui-ux-pro-max`'s own description advertises "build, create, implement"
and which surface is accurate is a product decision, not a lint fix.

**Archive cap 200 → 400 lines**, archives only. The 200-line rule keeps a
working page scannable; an append-only archive nobody reads top to bottom does
not need it, and the shared cap was the entire churn driver — measured, entries
grew from ~8 lines to 25-37, so an archive filled after 5-8 of them and 13 pages
appeared in 23 days. Also documented that the 30-entry log cap has never bound:
the line cap is reached first, around 13 entries.

## [2026-07-26] infrastructure | Meta-layer guarded, archive catalog split out of index.md

**Agent & Skill Registry — tenth cross-surface family.** Every other family
exists because the same literal is repeated across two surfaces with nothing
tying the copies together; the layer governing those guards had none of its own.
`documentation-sync.md` mandates three-place registration for a new agent or
skill and `agents-index.md` states "review profiles must not declare
Write/Edit", but `verify_rules.py` had zero references to `.claude/agents/` or
`.claude/skills/`. Four checks now: agents ↔ agents-index two-way, skills ↔
skills-index two-way, rules ↔ CLAUDE.md § Rules table two-way, and — the sharp
one — a profile whose index **Mode** says read-only must declare no
`Write`/`Edit`/`NotebookEdit`. That makes the Mode column machine-read instead of
decorative: an auditor silently gaining an edit tool could modify the code it was
dispatched to inspect. Nothing was drifting at the time (56/56 rules, all 15
profiles correct); this is enforcement, not repair. Each check was proven
non-vacuous against a fixture that introduces exactly the drift it targets.

**Archive rows moved out of `index.md`.** The `SessionStart` hook injects
`index.md` verbatim into every session, and 17 of its 147 lines were
`log-archive-*` rows — 12% of a permanent context cost for a lookup nobody makes
by description, growing about one row every two days. They now live in
`log-archive-index.md`, which the linter treats as a named **index delegate**:
one hop, one named page, so "every page is listed in index.md" still holds.
Deliberately not general transitivity — if any page linked from any indexed page
counted, the no-orphan-pages invariant would dissolve; a test asserts a page
linked from an ordinary indexed page is still reported. `index.md` 147 → 131
lines.

**Collector convention fix found on the way.** An absent catalog section
returned `{}`, which read as "present but empty" and would have reported every
name on the other side as drifted; it now returns `None` like every other
collector in the module, which is what "absent surface → skip" has always meant
here. That surfaced as 11 unrelated suites going red against partial fixtures —
the fixtures were right and the collector was wrong.

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

**README had rotted by up to 40%** and nothing could see it. Its "Project at a
Glance" table uses its OWN row labels ("Test suite", "Localization keys"), so
the inline fixer — which keys on CLAUDE.md's labels and prose phrasings — never
touched it: 826 vs 1030 source files, ~2,243 vs ~3,167 l10n keys, schema 20 vs
29, eight rows in all, on the one surface outsiders read. Corrected from the
live collector, then guarded as a ninth family so it cannot silently rot again.
The CI-pipeline table in the same file was stale too (98→99 coverage, 8,930+ →
11,700+ tests, 21 → 28 checkers); the 98→99 sweep had missed the file entirely
because the search was scoped to CLAUDE.md, `.claude/rules` and the wiki —
never the repo root.

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

