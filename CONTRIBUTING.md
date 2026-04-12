# Contributing to BudgieBreedingTracker

Thank you for considering contributing! This document provides guidelines for contributing to BudgieBreedingTracker.

## Getting Started

### Prerequisites

- Flutter 3.16+ / Dart 3.8+
- A Supabase account (for backend features)
- Git

### Setup

```bash
git clone https://github.com/BekirEfeoglu/BudgieBreedingTracker.git
cd BudgieBreedingTracker
flutter pub get
dart run build_runner build --delete-conflicting-outputs
cp .env.example .env  # Fill in your Supabase credentials
flutter run
```

## Development Workflow

### Branch Naming

```
feat/<short-description>    # New feature
fix/<short-description>     # Bug fix
refactor/<short-description> # Refactoring
test/<short-description>    # Adding tests
chore/<short-description>   # CI/config/dependency updates
```

### Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(birds): add batch delete functionality
fix(sync): resolve conflict in egg push order
refactor(genetics): extract punnett calculator to service
```

### Pull Request Process

1. Create a branch from `main`
2. Make your changes following the coding standards below
3. Run quality checks:
   ```bash
   flutter analyze --no-fatal-infos
   flutter test --exclude-tags golden
   python scripts/check_l10n_sync.py
   python scripts/verify_code_quality.py
   ```
4. Push and open a PR against `main`
5. Fill in the PR template completely
6. Wait for CI checks to pass and review

## Coding Standards

### Architecture

- **Offline-first**: All writes go to local SQLite (Drift) first, then sync to Supabase
- **Feature-first folder structure**: Each feature has its own `providers/`, `screens/`, `widgets/`
- **Layer rules**: `core/` never imports from `features/` or `data/`

### Key Rules

- All user-facing text must use `.tr()` localization (Turkish, English, German)
- Use `AppSpacing` constants instead of hardcoded spacing values
- Use `Theme.of(context)` for colors and text styles
- Use `AppLogger` instead of `print()`
- Use `AppIcon(AppIcons.x)` for custom SVG icons
- Minimum touch target size: 44px
- Max 300 lines per file

### Anti-Patterns to Avoid

- `withOpacity()` -> use `withValues(alpha: x)`
- `print()` -> use `AppLogger`
- Hardcoded strings -> use `.tr()` localization
- `Icon(Icons.x)` for domain icons -> use `AppIcon(AppIcons.x)`

## Localization

All three language files must stay in sync:
- `assets/translations/tr.json` (Turkish - master)
- `assets/translations/en.json` (English)
- `assets/translations/de.json` (German)

Add new keys to all three files when introducing user-facing text.

## Reporting Issues

- Use the provided issue templates (Bug Report or Feature Request)
- Do **not** open blank issues
- For security vulnerabilities, see [SECURITY.md](SECURITY.md)

## License

This project uses a proprietary license. See [LICENSE](LICENSE) for details.
