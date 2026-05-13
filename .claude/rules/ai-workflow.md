# AI Workflow

## Quality Gates (canonical — other files reference here)
```bash
scripts/run_local_quality_gate.sh         # Diff, rules, quality, conditional l10n/script tests
flutter analyze --no-fatal-infos          # Static analysis — 0 errors
flutter test                               # All tests pass
```
Run before every commit when the changed surface is broad. CI enforces analysis, tests, golden tests, script tests, l10n sync, code quality, rules sync, and platform build gates on `main` PRs/pushes.

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

## Clean Development Loop
- Begin with `git status --short --branch`; never overwrite unrelated local changes.
- When the worktree is dirty, build a quick dirty-state ledger from `git diff --name-status` and `git status --short`: classify each path as task-owned, pre-existing/user, generated/dependency, or rule/doc before editing.
- Keep the working set reviewable: separate feature code, rule/documentation updates, generated code, and release workflow changes unless they must ship together.
- Do not stage, stash, revert, format, regenerate, or rewrite unrelated dirty buckets without explicit user request. "Toparla" means make the state reviewable and documented, not silently discard or hide changes.
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
- Never import from `data/remote/` directly in UI — use Repository
- Never import across feature modules

## Anti-Pattern Enforcement
- `verify_code_quality.py` scans with 24 checkers (18 from CLAUDE.md + 6 extra)
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

> **Related**: git-rules.md (commit format), branch-workflow.md (merge policy), new-feature-checklist.md (entity steps)
