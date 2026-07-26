# Change Log Archive — July 2026 O

Archived July 2026 entries (07-26 to 07-26) rotated out of [[log]] during the
2026-07-26 six-lane audit. Covers the agent read-only measurement, the skill
`allowed-tools` correction, and the registry-collector split.

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

