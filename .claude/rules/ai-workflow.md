# AI Workflow

## Quality Gates (canonical — other files reference here)
```bash
scripts/run_local_quality_gate.sh         # Staged/unstaged/untracked diff, rules/quality, conditional l10n/script/breeding tests
flutter analyze --no-fatal-infos          # Static analysis — 0 errors
flutter test                               # All tests pass
```
Run before every commit when the changed surface is broad. The script mirrors CI's
`code-quality` job check-for-check; keep them in step — `verify_migration_drift.py`
ran in CI but not locally until 2026-07-25, so migration structure problems only
surfaced after push. CI enforces analysis, tests, golden tests, script tests, l10n sync, code quality, rules sync, and platform build gates on `main` PRs/pushes.

Rule/docs/CI changes are not "just docs": run `scripts/run_local_quality_gate.sh` before commit/push, then use the smallest extra command that proves the changed contract. If a rule update changes codebase metrics or inline references, run `python3 scripts/verify_rules.py --fix` first, then `python3 scripts/verify_rules.py --strict`.

The gate derives conditional checks from staged, unstaged, and untracked files.
Breeding/egg/chick lifecycle and their scheduler/calendar integration paths
additionally trigger
`scripts/run_breeding_egg_regression.sh`. Executable scope-contract tests pass
representative scheduler/calendar paths through the real router. The focused
manifest covers the transaction, notifier, notification, and calendar
boundaries and refuses skipped/excluded tests. A green conditional gate proves
only those scenarios; the owning rule's manual residual checklist still applies.

Install the tracked hooks with `scripts/install_git_hooks.sh`; `core.hooksPath` must remain worktree-relative (`.githooks`). The pre-commit hook removes repository-local `GIT_*` variables only around Flutter subprocesses so the SDK can resolve its own Git version instead of reporting `0.0.0-unknown`.

## Code Generation
Run after modifying Freezed models, Drift tables, or Riverpod providers:
```bash
dart run build_runner build
```
If generation gets stuck: `dart run build_runner clean` first.

## Task Approach
1. **Read first** — understand existing code and patterns before modifying
2. **Follow conventions** — don't invent new patterns; match what exists
3. **Minimal changes** — no drive-by refactoring, no unrelated improvements
4. **Test what you build** — add/update tests for changed behavior
5. **Run quality gates** — after every significant change, before declaring done
6. **Update stats** — if codebase metrics change, run `verify_rules.py --fix`

## Rule Authoring Contract

Rules are executable engineering contracts, not collections of preferences.
When adding or changing one:

1. **Own the scope** — name the paths/entities/workflows the rule governs and
   link the matching wiki source. Avoid a rule that silently applies everywhere.
2. **Classify the claim** — distinguish current shipped behavior, mandatory
   policy/invariant, biological evidence, and explicitly unshipped work. Never
   phrase a future design as current behavior.
3. **State the boundary** — for writes, identify source of truth, transaction or
   rollback boundary, server authorization, retry/idempotency, and optional side
   effects. For UI, identify loading/error/empty/accessibility states.
4. **Use testable language** — prefer “must” plus the failure mode and evidence
   over “should” without an owner. Name concrete commands only when they exist.
5. **Map evidence** — separate automated checks from manual residual review.
   Automation is preferred; a manual rule must identify what a reviewer observes.
6. **Prevent drift** — update owning rule, `CLAUDE.md`, wiki synthesis, log, tests,
   and checker documentation together when their claims or coverage change.
7. **Keep it operational** — include an entry checklist and definition of done
   for high-risk domains; do not duplicate low-level facts owned by another rule.

Before accepting a rule-only change, test that it does not contradict the
production path, another owning rule, or an automated checker. Green Markdown
links and symbol resolution do not validate semantics.

## First-Party Agent Routing

Agent profiles under `.claude/agents/` are focused workflows, not generic
personas. Use the smallest profile that matches the task; do not run every
auditor by default.

| Change / need | Profile | Mode |
|---------------|---------|------|
| General Flutter/Dart diff review | `code-reviewer` | Read-only |
| Anti-patterns the CI scanner does not cover (#8, #9, #13, #23, #24) | `antipattern-manual-sweeper` | Read-only |
| Genetics engine/rate/viability change | `genetics-guardian` | Read-only |
| Supabase migration or Edge Function audit | `migration-auditor` / `edge-function-auditor` | Read-only |
| PII/logging or test-flake sweep | `pii-observability-auditor` / `test-stability-auditor` | Read-only |
| Duplicate bug path hunt | `sibling-path-hunter` | Read-only |
| Entity, dependency, or l10n implementation | `entity-scaffolder` / `dependency-bump-agent` / `l10n-agent` | Write-enabled |
| Behavior/rule/CI change finished | `doc-sync-agent` | Write-enabled, docs only |
| Visual/usability/accessibility critique | `ui-ux-designer` | Read-only |
| Push/release closure | `post-push-verifier` / `release-readiness-agent` | Read-only |

Read-only profiles report findings and must not edit. Write-enabled profiles
still obey the user's scope, dirty-worktree buckets, and approval boundaries.
The complete catalog and routing notes live in
`obsidian-brain/sources/agents-index.md`.

## Clean Development Loop
- Begin with `git status --short --branch`; never overwrite unrelated local changes.
- When the worktree is dirty, build a quick dirty-state ledger from `git diff --name-status` and `git status --short`: classify each path as task-owned, pre-existing/user, generated/dependency, or rule/doc before editing.
- Re-run `git status --short --branch` after mutating commands such as code generation, Flutter/Xcode/CocoaPods builds, formatting, quality gates, git hooks, or maintenance scripts. Classify any newly dirty files before the next edit, commit, or push.
- Keep the working set reviewable: separate feature code, rule/documentation updates, generated code, and release workflow changes unless they must ship together.
- Do not stage, stash, revert, format, regenerate, or rewrite unrelated dirty buckets without explicit user request. "Toparla" means make the state reviewable and documented, not silently discard or hide changes.
- Before committing or pushing, inspect `git diff --name-status` and `git diff --cached --name-status`; the cached set must contain only the intended bucket and no task-owned changes may remain unstaged.
- After a requested push or completion handoff, run `git status --short --branch` again. If task-owned files are still dirty, resolve them before reporting completion; if unrelated pre-existing/user files must be hidden to satisfy a clean-tree request, preserve them with a named stash or branch and report the exact ref.
- If the current task intentionally crosses buckets, record the coupling in the handoff and run the smallest checks that prove each touched bucket.
- Prefer one root-cause fix per commit. If a second issue appears, gather evidence and decide whether it needs a separate commit.
- Do not call work complete from local success alone when the task touched CI, release, signing, or branch state.
- For pushed fixes, verify the exact commit SHA, not the branch name alone.
- Prefer `python3 scripts/check_remote_status.py` for exact SHA GitHub status/check-run verification.
- Stale green checks from an earlier commit or workflow run are not completion evidence.

## Investigation Before Fix
- Read error messages fully before acting
- Check if the issue is in generated code (`.g.dart`, `.freezed.dart`) — regenerate first
- Trace the data flow: UI -> Provider -> Repository -> DAO/Remote
- Use `AppLogger.debug()` for temporary tracing, remove before commit

## Prohibited Actions
- Never modify RLS policies from client code
- Never hardcode Supabase credentials
- Never skip auth guards on protected routes
- Never add `print()` — use `AppLogger`
- Never commit `.env` or credential files
- Never use `context.go()` for forward navigation
- Never use `withOpacity()` — use `withValues(alpha:)`
- Never send `created_at`/`updated_at` to Supabase — use `.toSupabase()`
- Never import from `data/remote/` directly in feature/UI code — use `data/providers`, Repository, or domain service boundaries
- Never import across feature modules — use `shared/`, `core/`, `domain/`, or `data/providers` facades

## Anti-Pattern Enforcement
- `verify_code_quality.py` scans with 28 checkers (19/24 CLAUDE.md patterns plus 10 documented extra scanners; some scanners overlap)
- CI `code-quality` job blocks PRs with violations
- Full list: CLAUDE.md § "Critical Anti-Patterns (24 rules)"

## L10n Workflow
- Master language: Turkish (`tr.json`)
- Add keys to all 3 files (tr, en, de) simultaneously
- Verify: `python3 scripts/check_l10n_sync.py`
- CI `l10n-sync` job blocks PRs with missing keys
- Details: see localization.md

## Handoff Evidence
Before reporting completion, capture:
- `git status --short --branch`
- dirty-state ledger by bucket when the worktree is not clean
- relevant local verification command outputs
- pushed commit SHA when a push was requested
- GitHub status/check-run summary for the pushed commit when CI is part of the task
- remaining skipped checks with the reason they are acceptable

> **Related**: git-rules.md (commit format), branch-workflow.md (merge policy), new-feature-checklist.md (entity steps), documentation-sync.md (claim authority + doc sync), `obsidian-brain/sources/agents-index.md` (agent catalog)
