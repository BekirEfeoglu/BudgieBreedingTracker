# Change Log Archive — July 2026 O

Archived July 2026 entries (07-26 to 07-26) rotated out of [[log]] during the
2026-07-26 six-lane audit. Covers the agent read-only measurement, the skill
`allowed-tools` correction, and the registry-collector split.

---
## [2026-07-26] infrastructure | Agent read-only measured: a real gate, but not a sandbox

**Probed rather than assumed, and it corrects a claim from hours earlier.** A
`code-reviewer` run reported its actual tools. `Write` was emitted and refused
by the harness — *"No such tool available: Write. Write exists but is not
enabled in this context."* — with no file created. So the agent-side exclusion
is a genuine gate, unlike a skill's `allowed-tools`, which the same day's probe
showed restricts nothing.

Two findings that change how the guard should be read:

- **`Bash` is available, so read-only is behavioural, not technical.** `sed -i`,
  `echo >`, `git commit` and `rm` all stay reachable. The tool gate raises the
  cost of mutating; it does not prevent it. A read-only profile is not a
  containment measure.
- **The declared list is not the realized list.** `code-reviewer` declares
  `Read, Bash, Glob, Grep`; the running agent had only `Read` and `Bash`. The
  frontmatter diverges in *both* directions — it over-declares `Glob`/`Grep`
  while the harness independently withholds `Write`/`Edit`. My earlier phrasing,
  "a subagent's `tools:` list IS its complete tool set", is therefore wrong;
  read it as intent, not inventory. Single-context sample.

The registry check still earns its place: it keeps the **declaration** honest
and reviewable, which is what a human or agent reads before dispatching. It was
never able to prove a profile cannot write, and the docs now say so.

Also: the skills catalog column is renamed `Writes?` → **`Ritual writes?`**, so
it names what it actually asserts — what the skill's own steps do — rather than
implying a capability. The check parses the row's last cell, not the header, so
the rename is behaviour-neutral; proven against three different headers.

**Push batching recorded** in branch-workflow.md. Four successive pushes this
session left two intermediate commits superseded, one showing commit status
`failure` although every job was `cancelled`, not failed. Verification correctly
targets the tip, but an intermediate commit that never completes a round leaves
no evidence for `git bisect` or later review.

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

