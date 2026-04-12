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

## Branch Naming
```
feature/short-description
fix/short-description
docs/short-description
chore/short-description
```

## PR Workflow
1. Branch from `main`
2. Implement with conventional commits
3. Run quality gates locally (analyze, test, l10n, code-quality)
4. Open PR — CI runs: analyze, test, golden-test, l10n-sync, code-quality, rules-sync
5. Review and merge to `main`
