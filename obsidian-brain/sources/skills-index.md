# Project-Local Skills

Catalog of `.claude/skills/*/SKILL.md` workflows. Skills are user-invocable
rituals (slash-command style); they orchestrate work but grant no authority
beyond the user's request. Complement to [[sources/agents-index]] — skills
*sequence* a task, agent profiles *execute* a lane inside one.

## Catalog

| Skill | Use when | Ritual writes? |
|-------|----------|---------|
| `audit` | Comprehensive multi-agent audit sweep (the 2026-07-02/07-04 ritual): parallel read-only lanes → sibling-path hunt → fix → gates → commit → push → exact-SHA verify | Yes (fixes) |
| `screenshot-debug` | User sends a simulator/device screenshot of a bug (their standard bug-report channel); traces UI → Provider → Repository → DAO/Remote, hunts siblings before fixing | Yes (fix) |
| `store-release` | Cut a store release: version-bump consistency, 3-language release notes for `system_settings.app_version`, GO/NO-GO gate, `build_release.sh`/Release-Ready checklist. Gates and prepares; never signs/publishes | Yes (prep) |
| `mobile-design` | Mobile-first design decisions (touch, platform conventions, perf patterns) while building Flutter UI | No |
| `ui-ux-pro-max` | UI/UX design intelligence: styles, palettes, font pairings, review/fix passes on visual work | No |
| `supabase-postgres-best-practices` | Writing/reviewing/optimizing Postgres queries, schema, or config | No |

## Routing Notes

- `audit` dispatches the read-only agent profiles from [[sources/agents-index]]
  (antipattern-manual-sweeper, edge-function-auditor, migration-auditor,
  genetics-guardian, pii-observability-auditor, test-stability-auditor,
  sibling-path-hunter) and closes with `doc-sync-agent` + `post-push-verifier`.
- `store-release` pairs with the `release-readiness-agent` profile; the skill
  owns the sequence, the profile owns the GO/NO-GO evidence.
- `screenshot-debug` honors the sibling-path lesson (2026-07-02 audit): no fix
  is complete until twin paths are swept.
- Design skills (`mobile-design`, `ui-ux-pro-max`) advise; UI changes still go
  through the normal quality gates and `.claude/rules/ui-patterns.md`.

## Maintenance

- Adding/removing/renaming a skill under `.claude/skills/` updates this page
  and, when routing changes, [[sources/agents-index]] in the same change. The
  catalog above is **CI-enforced** two-way against `.claude/skills/*/SKILL.md`
  by `verify_rules.py` § Agent & Skill Registry (`rules-sync` job).
- Skill `allowed-tools` must match the declared write posture above: a skill
  the **Ritual writes?** column calls `No` must not hand itself `Write`/`Edit`/
  `NotebookEdit`. Also CI-enforced by the same family.

### `allowed-tools` is declared intent, not an enforced boundary

**Measured 2026-07-26**: with `ui-ux-pro-max` active — which declares
`allowed-tools: Read, Glob, Grep, Bash` — a `Write` call still succeeded. In
this harness and session configuration a skill's `allowed-tools` does **not**
restrict the main session's tool set. (Caveat: observed under this project's
permission mode; a different mode or a skill dispatched into a subagent may
behave differently. What is certain is that it cannot be relied on as a
boundary.)

So the column and the field document **what the skill's own ritual does**, and
the CI check keeps the two from contradicting each other. Neither prevents a
write. Treat an advisory posture as a statement of intent that reviewers and
agents can trust, never as a sandbox.

An agent profile differs: its `Write`/`Edit` exclusion **is** honoured by the
harness (measured the same day — see [[sources/agents-index]] § What "read-only"
actually buys). So the two checks look alike but mean different things: the agent
one rides on a real gate, this one does not. Neither yields a sandbox, since a
read-only agent still has `Bash`.

All three advisory skills now declare `allowed-tools: Read, Glob, Grep, Bash`,
so the column is real for every row. `ui-ux-pro-max` and
`supabase-postgres-best-practices` gained it on 2026-07-26, resolving a
contradiction: `ui-ux-pro-max`'s `description` advertises "build, create,
implement, refactor" while the catalog said `No`. The body settles it — its four
steps are analyze → run `.claude/skills/ui-ux-pro-max/scripts/search.py` → read
guidelines, both scripts open files read-only (`open(filepath, 'r')`), and the
documented output formats are a
terminal ASCII box or Markdown. Those verbs are the skill's **trigger
conditions**, not its actions: "When user requests UI/UX work (design, build,
create, implement…), follow this workflow." The skill supplies a design system;
the surrounding session implements it, exactly like `mobile-design`.

Two consequences worth knowing:

- **Implementation during activation is NOT blocked.** An earlier draft of this
  page warned that a restricted skill could not edit files during its
  activation; the probe above disproved it. Invoking `ui-ux-pro-max` and then
  editing works normally.
- **These two skills are vendored.** Re-vendoring upstream would drop the added
  line; the registry check turns red rather than letting the posture rot back.

## See Also

- [[sources/agents-index]] — agent profiles the skills dispatch
- [[sources/rules-index]] — rules → wiki map
- [[cheat-sheet]] — task-oriented navigation
- [[index]]
