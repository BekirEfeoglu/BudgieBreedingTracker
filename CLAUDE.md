# CLAUDE.md

Comprehensive Flutter breeding tracker app for budgie breeders.
Flutter 3.16+ / Dart 3.8+ / Riverpod 3 / GoRouter 17+ / Supabase / Drift 2.31+ / Freezed 3

## Build & Development Commands

```bash
# Install dependencies
flutter pub get

# Code generation (Freezed, Drift, JSON Serializable, Riverpod)
dart run build_runner build --delete-conflicting-outputs

# Clean generated files (if stuck)
dart run build_runner clean

# Run app (requires Supabase credentials)
flutter run --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<key>

# Static analysis
flutter analyze --no-fatal-infos

# Run all tests (excludes golden tests on CI)
flutter test
flutter test --exclude-tags golden

# Run single test file
flutter test test/path/to/file_test.dart

# Format code
dart format .

# Apply automatic fixes
dart fix --apply
```

### Quality Scripts
```bash
python scripts/check_l10n_sync.py       # Verify tr/en/de translation keys are in sync
python scripts/verify_code_quality.py    # Anti-pattern scan (21 checkers, 16/17 CLAUDE.md patterns + 5 extra)
python scripts/verify_rules.py          # Validate CLAUDE.md stats against codebase (single source of truth)
python scripts/verify_rules.py --fix    # Auto-fix CLAUDE.md stats table with actual values
```

## Codebase Stats

| Metric | Value |
| --- | --- |
| Source files (lib/) | 720 Dart files |
| Test files (test/) | 679 test files, 8,018+ individual tests |
| Feature modules | 20 |
| Drift tables / DAOs / Mappers | 20 each |
| Repositories | 20 entity + base + sync_metadata |
| Remote sources | 20 entity + base + 2 caches + providers |
| Freezed models | 21 model files + statistics_models + supabase_extensions |
| Domain services | 14 directories |
| Routes | 60 |
| Custom SVG icons | 82 constants, 82 files on disk |
| Shared widgets | 19 (14 root + 2 buttons + 2 cards + 1 dialog) |
| Enum files | 12 |
| Supabase constants | 94 (tables + buckets + columns) |
| L10n keys | ~1,940 per language, 34 categories |
| DB schema version | 17 |

## Rules

Comprehensive rules in `.claude/rules/` (auto-loaded):

| File | Scope |
| --- | --- |
| `architecture.md` | Tech stack, layers, folder structure, data flow, security, performance |
| `data-layer.md` | Drift + Supabase + Repository + Sync + Storage + Cache |
| `coding-standards.md` | Naming, 24 anti-patterns, Freezed/enum, icon API, file organization |
| `providers.md` | Riverpod provider types, dependency chain, ref usage |
| `ui-patterns.md` | Widget types, AsyncValue, forms, GoRouter routes (60), guards |
| `localization.md` | easy_localization, key structure, 35 categories, sync workflow |
| `testing.md` | Test patterns, mocking, golden tests, coverage |
| `error-handling.md` | Error hierarchy, Sentry, retry/backoff, localized errors |
| `new-feature-checklist.md` | Step-by-step guide for adding new features |
| `git-rules.md` | Conventional commits, branch naming, PR workflow |
| `ai-workflow.md` | Task approach, quality gates, prohibited actions |
| `chat.md` | Response language (Turkish), post-coding suggestions |

## Critical Anti-Patterns (must avoid)

1. `withOpacity()` -> use `withValues(alpha: x)`
2. `value` on DropdownButtonFormField -> use `initialValue` (deprecated since Flutter 3.33)
3. `.equals()` on enum Drift column -> use `.equalsValue()`
4. `ref.watch()` in callbacks -> use `ref.read()`
5. `print()` -> use `AppLogger`
6. Hardcoded text -> use `.tr()` (easy_localization, 3 languages: tr/en/de)
7. `Icon(Icons.x)` for domain icons -> use `AppIcon(AppIcons.x)` (SVG via flutter_svg)
8. Missing `@JsonKey(unknownEnumValue: X.unknown)` on enum fields in Freezed models
9. `switch` without `unknown` case for server-side enums
10. `context.go()` for forward navigation -> use `context.push()` (go replaces stack)
11. Import table via app_database for DAO -> import DIRECTLY from table file
12. Parameterized route before specific in GoRouter -> specific FIRST (`form` before `:id`)
13. Hardcoded colors/spacing -> use `Theme.of(context)` / `AppSpacing`
14. Missing `controller.dispose()` -> ALWAYS dispose in ConsumerStatefulWidget
15. Missing `const Model._()` in Freezed -> ALWAYS add private constructor
16. Hardcoded SVG paths -> use `AppIcons` constants from `app_icons.dart`
17. `IconData` param in shared widgets -> use `Widget` param (EmptyState, InfoCard, StatCard, etc.)

## Key File Locations

```
Providers:     lib/features/<feature>/providers/
Screens:       lib/features/<feature>/screens/
Widgets:       lib/features/<feature>/widgets/
Models:        lib/data/models/
Enums:         lib/core/enums/
Tables:        lib/data/local/database/tables/
DAOs:          lib/data/local/database/daos/
Mappers:       lib/data/local/database/mappers/
Repos:         lib/data/repositories/
Remote:        lib/data/remote/api/
Services:      lib/domain/services/
Router:        lib/router/
Theme:         lib/core/theme/
Shared UI:     lib/core/widgets/
Icons:         lib/core/constants/app_icons.dart
SVG Assets:    assets/icons/
Translations:  assets/translations/
Security:      lib/core/security/
Preferences:   lib/data/local/preferences/
EdgeFunctions: lib/data/remote/supabase/
```
