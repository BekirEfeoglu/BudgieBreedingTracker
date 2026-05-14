# Branch Workflow

Source: `.claude/rules/branch-workflow.md`, `.claude/rules/git-rules.md`

## Strategy

**Main-only**: `main` is the only permanent branch on GitHub remote. Active development works directly on `main` or short-lived feature branches.

## Branch Rules

- Base branch: `main` (always)
- Short-lived branches: only for PR/review flow or risky experiments
- Agent-created branches: `codex/<short-description>` prefix
- PR default target: `main`
- Delete remote branch after merge

## Quality Gates Before Push

```bash
flutter analyze --no-fatal-infos
python3 scripts/verify_code_quality.py
python3 scripts/check_l10n_sync.py
flutter test
```

All must pass before pushing to main.

## Commit Message Format

```
type(scope): description
```

Types: `feat`, `fix`, `refactor`, `perf`, `docs`, `chore`, `test`, `style`, `ci`

Examples:
```
feat(local-ai): add 10MB file size guard before image analysis
fix(l10n): replace hardcoded Turkish strings with .tr() keys
refactor(theme): move AI confidence badge colors to AppColors
```

Rules: imperative mood, lowercase after colon, no period, max 72 chars.

## PR Workflow

1. Branch from `main`
2. Implement with conventional commits
3. Run quality gates locally
4. Open PR targeting `main`
5. CI runs all checks
6. Review and merge
7. Delete remote branch

## Hotfix Exception

Critical production bugs: minimal change directly on `main`, run tests, push, verify with `python3 scripts/check_remote_status.py`.

## Verification After Push

```bash
python3 scripts/check_remote_status.py
```

Success requires: status `success` + all check-runs `completed`. Stale green from earlier commits is not evidence.

## Working Tree Hygiene

Before staging:
- `git status --short --branch` to classify dirty files
- Stage by explicit path, not `git add .`
- Never stash/revert unrelated changes without explicit user request
- After mutating commands (build_runner, formatters), re-check `git status`

## See Also

- [[infrastructure/ci-cd]] — CI jobs
- [[infrastructure/release-ops]] — store releases
