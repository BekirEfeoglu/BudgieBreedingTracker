# Project-Local Skills

Catalog of `.claude/skills/*/SKILL.md` workflows. Skills are user-invocable
rituals (slash-command style); they orchestrate work but grant no authority
beyond the user's request. Complement to [[sources/agents-index]] — skills
*sequence* a task, agent profiles *execute* a lane inside one.

## Catalog

| Skill | Use when | Writes? |
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
- Skill `allowed-tools` must match the declared write posture above (advisory
  skills stay read-only). Unlike the agent profiles' read-only mode, this one is
  not machine-checked yet — skills declare a looser, prose write posture
  ("Yes (fixes)", "Yes (prep)") that does not map cleanly onto a tool list.

## See Also

- [[sources/agents-index]] — agent profiles the skills dispatch
- [[sources/rules-index]] — rules → wiki map
- [[cheat-sheet]] — task-oriented navigation
- [[index]]
