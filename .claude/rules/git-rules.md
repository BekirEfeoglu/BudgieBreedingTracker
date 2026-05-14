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
- Default base branch is `main` (see branch-workflow.md)
- Use short-lived branches only when a PR/review flow is needed; otherwise keep local work on `main` and push after gates pass
- Agent-created branches use `codex/<short-description>` unless the user asks for another prefix
- Keep branch names short and descriptive

## Working Tree Organization
- Before staging or committing, inspect `git status --short --branch` and classify dirty files as task-owned, pre-existing/user, generated/dependency, or rule/doc.
- Re-check `git status --short --branch` after commands that may mutate files, including code generation, Flutter/Xcode/CocoaPods builds, formatters, quality gates, git hooks, and maintenance scripts.
- Stage by explicit path or pathspec for one coherent bucket. Do not use `git add .` in a dirty mixed worktree.
- Do not stash, revert, reset, or checkout unrelated changes unless the user explicitly asks for that operation.
- Before push, verify `git diff --name-status` has no uncommitted task-owned files and `git diff --cached --name-status` is empty after the final commit.
- If the user requests a clean tree, move unrelated pre-existing/user buckets to a descriptive stash or separate branch and report the exact ref; never drop them silently.
- Keep feature logic, tests, generated files, dependency lockfiles, CI/release changes, and rule/doc updates in separate commits unless a rulebook entry requires them to ship together.
- Commit messages must describe the staged bucket. If multiple buckets are intentionally staged together, explain the coupling in the commit body or PR summary.

## PR Workflow
1. Branch from current `main`
2. Implement with conventional commits
3. Run quality gates locally (see ai-workflow.md § Quality Gates)
4. Open PR targeting `main`
5. CI runs: analyze, test, golden-test, l10n-sync, code-quality, rules-sync
6. Review and merge to `main`
7. Delete the short-lived remote branch after merge

> **Related**: branch-workflow.md (branch strategy, hotfix), ai-workflow.md (quality gates), ci-actions.md (CI jobs)
