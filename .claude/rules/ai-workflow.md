# AI Workflow

## Quality Gates (canonical — other files reference here)
```bash
flutter analyze --no-fatal-infos          # Static analysis — 0 errors
python3 scripts/verify_code_quality.py    # Anti-pattern scan — 0 violations
python3 scripts/check_l10n_sync.py        # 3-language key parity
python3 scripts/verify_rules.py --fix     # CLAUDE.md stats sync
flutter test                               # All tests pass
```
Run before every commit. CI enforces all five gates on PRs.

## Code Generation
Run after modifying Freezed models, Drift tables, or Riverpod providers:
```bash
dart run build_runner build --delete-conflicting-outputs
```
If generation gets stuck: `dart run build_runner clean` first.

## Task Approach
1. **Read first** — understand existing code and patterns before modifying
2. **Follow conventions** — don't invent new patterns; match what exists
3. **Minimal changes** — no drive-by refactoring, no unrelated improvements
4. **Test what you build** — add/update tests for changed behavior
5. **Run quality gates** — after every significant change, before declaring done
6. **Update stats** — if codebase metrics change, run `verify_rules.py --fix`

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
- `verify_code_quality.py` scans for 21 patterns (16 from CLAUDE.md + 5 extra)
- CI `code-quality` job blocks PRs with violations
- Full list: CLAUDE.md § "Critical Anti-Patterns (24 rules)"

## L10n Workflow
- Master language: Turkish (`tr.json`)
- Add keys to all 3 files (tr, en, de) simultaneously
- Verify: `python3 scripts/check_l10n_sync.py`
- CI `l10n-sync` job blocks PRs with missing keys
- Details: see localization.md

> **Related**: git-rules.md (commit format), branch-workflow.md (merge policy), new-feature-checklist.md (entity steps)
