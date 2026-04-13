# Git Rules

## Commit Message Format
```
type(scope): description
```

### Types
| Type | Usage |
|------|-------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code restructuring (no behavior change) |
| `perf` | Performance improvement |
| `docs` | Documentation |
| `chore` | Maintenance, dependencies |
| `test` | Test additions/fixes |
| `style` | Formatting, naming |
| `ci` | CI/CD changes |

### Scope
Feature name or core area: `feat(birds):`, `fix(l10n):`, `refactor(theme):`, `fix(admin):`

### Examples
```
feat(local-ai): add 10MB file size guard before image analysis
refactor(theme): move AI confidence badge colors to AppColors with dark mode support
fix(l10n): replace hardcoded Turkish strings with .tr() keys
fix: align app metadata and ad bootstrap updates
```

### Commit Message Guidelines
- Imperative mood: "add", "fix", "refactor" — not "added", "fixes", "refactoring"
- Lowercase first letter after colon
- No period at end
- Max 72 characters for subject line
- Body (optional): explain why, not what — the diff shows what

## Branch Naming
```
feature/short-description
fix/short-description
docs/short-description
chore/short-description
```
- Always branch from `develop` (not `main` — see branch-workflow.md)
- Keep branch names short and descriptive

## PR Workflow
1. Branch from `develop`
2. Implement with conventional commits
3. Run quality gates locally (see ai-workflow.md § Quality Gates)
4. Open PR targeting `develop`
5. CI runs: analyze, test, golden-test, l10n-sync, code-quality, rules-sync
6. Review and merge to `develop`
7. Periodically merge tested `develop` into `main` for release

> **Related**: branch-workflow.md (branch strategy, hotfix), ai-workflow.md (quality gates), ci-actions.md (CI jobs)
