---
name: audit
description: Run a comprehensive multi-agent audit sweep of BudgieBreedingTracker — the recurring ritual behind the 2026-07-02 (9-agent) and 2026-07-04 (8-agent) sweeps. Dispatches the specialized read-only auditors in parallel lanes, hunts sibling paths for every finding, then fixes → runs quality gates → commits → pushes → verifies exact-SHA green. Use when the user says "audit", "kapsamlı denetim", "sweep the codebase", or asks for a full-scope review before a release.
allowed-tools: Read, Grep, Glob, Bash, Edit, Write, Task
---

# Comprehensive Audit Sweep

> Codifies the proven audit ritual (see memory: project_audit_2026_07_02_second_pass, project_audit_2026_07_04). The value is in **breadth + sibling hunting + exact-SHA closure**, not any single agent.

## When to use
User asks for a comprehensive audit / "kapsamlı denetim" / full-scope review, or a pre-release sweep. For a single diagnosed bug, use `systematic-debugging` + `sibling-path-hunter` directly instead.

## Phase 0 — Baseline (before touching anything)
1. `git status --short --branch` — capture the starting worktree. Build a dirty-state ledger (task-owned / pre-existing / generated / rule-doc) if not clean.
2. Confirm you are on `main` (branch-workflow.md main-only). If unrelated dirty files exist, do NOT sweep them into the audit.
3. Establish the green baseline: note the current HEAD SHA.

## Phase 1 — Parallel audit lanes (dispatch, don't hand-roll)
Spawn the specialized **read-only** auditors in parallel — one `Task` call per lane, batched. Only the auditors relevant to the changed/target surface; a full sweep uses all. They report file:line findings; they do not edit.

| Lane | Agent | Beat |
|------|-------|------|
| Anti-patterns (manual) | `antipattern-manual-sweeper` | #8/#9/#13/#23/#24 + import/upsert/mixin extras |
| PII & observability | `pii-observability-auditor` | log/Sentry/console leaks, logout chain |
| Edge functions | `edge-function-auditor` | JWT, validation, tests, orphan detection |
| Migrations | `migration-auditor` | idempotency, RLS, drift |
| Genetics | `genetics-guardian` | calculationVersion, MUTAVI, regression tests |
| Tests | `test-stability-auditor` | 18 anti-patterns, skip policy |

Also apply your own judgement passes for surfaces without a dedicated agent (feature contracts vs the owning `.claude/rules/*.md`).

## Phase 2 — Triage + sibling hunt
1. Collect all findings; rank by severity (release-blocker → correctness → quality). Discard false positives with a one-line reason (the 07-03 marketing audit had a false-positive "vanishing pricing card" — verify before fixing).
2. For EVERY confirmed finding, launch `sibling-path-hunter` to enumerate twin paths before fixing — the 07-02 lesson was half-fixed bugs whose siblings were missed. Fix the whole family, not one file.

## Phase 3 — Fix
- One root-cause fix per commit; keep feature code, tests, generated files, and rule/doc updates in separate commits unless a rule requires shipping together.
- After any Freezed/Drift/Riverpod change, `dart run build_runner build --delete-conflicting-outputs`.
- Update the docs that describe changed behavior in the SAME change (documentation-sync.md): owning rule file + obsidian-brain page + `log.md` entry. Consider the `doc-sync-agent` as the last step.

## Phase 4 — Quality gates (before commit)
```bash
scripts/run_local_quality_gate.sh
flutter analyze --no-fatal-infos
flutter test
python3 scripts/verify_rules.py --fix && python3 scripts/verify_rules.py --strict
```
Do not claim done from local success alone when CI/release/branch state is involved.

## Phase 5 — Push + exact-SHA verification
> **Authorization gate:** committing and pushing to `main` is an outward-facing,
> hard-to-reverse action. Do it only when the user has authorized it — either a
> standing/durable authorization (project convention or memory, e.g. an
> autonomous-workflow preference) or an explicit go-ahead this session. Absent
> that, stop after Phase 4 with the changes staged/committed locally and report
> "changes ready, awaiting go-ahead to push" instead of pushing.
1. Commit with conventional messages; push to `main` (or a short-lived branch + PR if review is wanted).
2. Verify the EXACT pushed SHA — never the branch badge alone:
   ```bash
   python3 scripts/check_remote_status.py
   ```
   Or dispatch `post-push-verifier`, which correctly separates the GitHub Pages `deploy` transient (the #1 false-positive) from real ci.yml failures and waits for late main-only/Xcode Cloud checks.
3. Done only when commit status is `success` AND all required `ci.yml` check-runs are `completed:success` (accepted skips OK).

## Handoff
Report: findings-by-severity (fixed / deferred / false-positive), commits (SHAs), the exact-SHA CI result, remaining `git status`, and any intentional skips with their reason. Save a project memory entry for the sweep (date, agent count, key fixes, commit range) matching the existing audit-memory style.
