# Project-Local Agent Profiles

Catalog of `.claude/agents/*.md` workflows. Profiles narrow a task; they do not
grant authority beyond the user's request or bypass dirty-worktree, security,
deployment, or approval rules.

## Routing Rules

1. Use the smallest profile matching the task; do not run every auditor.
2. Read-only profiles report evidence and never edit.
3. Write-enabled profiles edit only their declared surface and still follow
   `AGENTS.md` plus owning rules.
4. `doc-sync-agent` runs after meaningful behavior/rule/CI changes, not as a
   substitute for implementing or reviewing them.
5. For related profiles, sequence implementation → focused auditor → doc sync →
   push/release verification.

## Catalog

| Profile | Use when | Mode |
|---------|----------|------|
| `antipattern-manual-sweeper` | Manual-only anti-pattern sweep beyond CI scanners | Read-only |
| `code-reviewer` | Project-specific Flutter/Dart/Drift/Supabase diff review | Read-only |
| `dependency-bump-agent` | Pub dependency + lockfile + CocoaPods chain | Write-enabled |
| `doc-sync-agent` | Reconcile rules, managed stats, wiki, gaps, and log | Docs-only write |
| `edge-function-auditor` | JWT, validation, tests, config, deploy registration | Read-only |
| `entity-scaffolder` | Full-stack offline-first entity or non-entity feature | Write-enabled |
| `genetics-guardian` | Genetics output/evidence/version/regression audit | Read-only |
| `l10n-agent` | tr/en/de parity and localized UI text | Write-enabled |
| `migration-auditor` | Drift/Supabase migration safety and parity | Read-only |
| `pii-observability-auditor` | Logs/Sentry/console PII and severity audit | Read-only |
| `post-push-verifier` | Exact-SHA GitHub/Xcode Cloud closure | Read-only |
| `release-readiness-agent` | Store-release GO/NO-GO | Read-only |
| `sibling-path-hunter` | Search twin code paths after a diagnosed bug | Read-only |
| `test-stability-auditor` | Flakes, cleanup, pump strategy, skip policy | Read-only |
| `ui-ux-designer` | Visual/usability/accessibility critique | Read-only; external profile |

## Common Sequences

| Task | Suggested sequence |
|------|--------------------|
| New entity | `entity-scaffolder` → `code-reviewer` → focused auditors → `doc-sync-agent` |
| Genetics engine change | implementation → `genetics-guardian` → `test-stability-auditor` → `doc-sync-agent` |
| Migration + Edge Function | implementation → both focused auditors → `pii-observability-auditor` → `doc-sync-agent` |
| Release | `release-readiness-agent`; after push use `post-push-verifier` |

## Maintenance

- Adding/removing/renaming a project-local profile updates this page and
  `.claude/rules/ai-workflow.md` in the same change.
- Dynamic codebase counts belong in `CLAUDE.md`; agent prompts should reference
  the managed source instead of copying counts that immediately drift.
- Review profiles must not declare `Write`/`Edit` tools.

## See Also

- [[sources/rules-index]]
- [[infrastructure/branch-workflow]]
- [[CLAUDE.md]]
- [[index]]
