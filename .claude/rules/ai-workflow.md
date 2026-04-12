# AI Workflow

## Quality Gates (run before commit)
```bash
flutter analyze --no-fatal-infos
python3 scripts/verify_code_quality.py
python3 scripts/check_l10n_sync.py
python3 scripts/verify_rules.py --fix
flutter test
```

## Task Approach
1. Read and understand existing code before modifying
2. Follow existing patterns — don't invent new conventions
3. Make minimal, focused changes — no drive-by refactoring
4. Run quality gates after every significant change
5. Update CLAUDE.md stats if codebase metrics change

## Code Generation
Run after modifying Freezed models, Drift tables, or Riverpod providers:
```bash
dart run build_runner build --delete-conflicting-outputs
```

## Prohibited Actions
- Never modify RLS policies from client code
- Never hardcode Supabase credentials
- Never skip auth guards on protected routes
- Never add `print()` — use `AppLogger`
- Never commit `.env` or credential files
- Never use `context.go()` for forward navigation
- Never use `withOpacity()` — use `withValues(alpha:)`

## Anti-Pattern Enforcement
- `verify_code_quality.py` scans for 21 patterns (16 from CLAUDE.md + 5 extra)
- CI `code-quality` job blocks PRs with violations
- Run locally before pushing

## L10n Workflow
- Master language: Turkish (tr.json)
- Add keys to all 3 files (tr, en, de)
- Verify with `check_l10n_sync.py`
- CI `l10n-sync` job blocks PRs with missing keys
