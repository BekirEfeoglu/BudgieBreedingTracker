# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-07-26] infrastructure | Correction: skill `allowed-tools` does not restrict the session

**Measured, and it disproves what two earlier entries today asserted.** With
`ui-ux-pro-max` active — declaring `allowed-tools: Read, Glob, Grep, Bash` — a
`Write` call succeeded. So in this harness a skill's `allowed-tools` does not
restrict the main session's tool set; the earlier claims that it "restricts a
session while the skill is active" and that "a restricted skill cannot edit
during its activation" are wrong, and the warning built on them was unnecessary.
Caveat on the caveat: this was observed under this project's permission mode, so
the safe reading is not "it never restricts" but "it cannot be relied on as a
boundary".

What survives: the field and the catalog column document what a skill's own
ritual does, and the CI check keeps them from contradicting each other. What
does not: any notion that an advisory skill is sandboxed. The declarations added
earlier today stay — they are honest intent, now correctly labelled — but
`skills-index` no longer implies enforcement. The agent read-only check is
different and remains a real boundary, because a subagent's `tools:` list IS its
complete tool set.

The lesson is the session's own theme aimed back at itself: I documented a
mechanism's behaviour from plausible reasoning instead of running it, and the
one-command probe took less time than the paragraph describing the risk.

## [2026-07-26] infrastructure | Registry collectors split out; archive merge direction matters

**`_rules_collectors.py` 1,101 → 748 lines.** The nine meta-layer registry and
inventory collectors moved to `_rules_registry.py` (369 lines) — they all answer
one question, "does this hand-maintained list still match the directory it
claims to enumerate", and they had grown to a third of a module about something
else. Imports go one way only, from `_rules_registry` into `_rules_collectors`,
never back. The split was caught being incomplete by the guard added hours
earlier: the new module was not named in CLAUDE.md and § Script inventory went
red immediately.

**Archive merge direction is load-bearing.** `-07-c` folded into `-07-b`, not
the reverse, because a dated entry in `-07-n` uses `log-archive-2026-07-b.md` as
its worked example of why `--rotate` picks a target by content rather than
filename. Merging the other way would have left that explanation pointing at a
file that no longer exists — the linter would not have caught it either, since
the reference is in backticks rather than a wikilink. 14 → 13 pages, 187 entries
preserved. Rule recorded in the catalog: grep the dated entries for an archive's
name before merging it.

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

