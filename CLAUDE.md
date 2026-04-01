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
python3 scripts/check_l10n_sync.py       # Verify tr/en/de translation keys are in sync
python3 scripts/verify_code_quality.py    # Anti-pattern scan (21 checkers, 16/17 CLAUDE.md patterns + 5 extra)
python3 scripts/verify_rules.py          # Validate CLAUDE.md stats against codebase (single source of truth)
python3 scripts/verify_rules.py --fix    # Auto-fix CLAUDE.md stats table with actual values
```

## Codebase Stats

| Metric | Value |
| --- | --- |
| Source files (lib/) | 728 Dart files |
| Test files (test/) | 683 test files, 8,139+ individual tests |
| Feature modules | 20 |
| Drift tables / DAOs / Mappers | 20 each |
| Repositories | 20 entity + base + sync_metadata |
| Remote sources | 20 entity + base + 2 caches + providers |
| Freezed models | 21 model files + statistics_models + supabase_extensions |
| Domain services | 14 directories |
| Routes | 60 |
| Custom SVG icons | 83 constants, 84 files on disk |
| Shared widgets | 19 (14 root + 2 buttons + 2 cards + 1 dialog) |
| Enum files | 12 |
| Supabase constants | 94 (tables + buckets + columns) |
| L10n keys | ~1,963 per language, 34 categories |
| DB schema version | 19 |

## Rules

Comprehensive rules in `.claude/rules/` (auto-loaded):

| File | Scope |
| --- | --- |
| `architecture.md` | Tech stack, layers, folder structure, data flow, security, performance |
| `data-layer.md` | Drift + Supabase + Repository + Sync + Storage + Cache |
| `coding-standards.md` | Naming, 24 anti-patterns, Freezed/enum, icon API, file organization |
| `providers.md` | Riverpod provider types, dependency chain, ref usage |
| `ui-patterns.md` | Widget types, AsyncValue, forms, GoRouter routes (60), guards |
| `localization.md` | easy_localization, key structure, 34 categories, sync workflow |
| `testing.md` | Test patterns, mocking, golden tests, coverage |
| `error-handling.md` | Error hierarchy, Sentry, retry/backoff, localized errors |
| `new-feature-checklist.md` | Step-by-step guide for adding new features |
| `git-rules.md` | Conventional commits, branch naming, PR workflow |
| `ai-workflow.md` | Task approach, quality gates, prohibited actions |
| `chat.md` | Response language (Turkish), post-coding suggestions |

## Critical Anti-Patterns (24 rules — must avoid)

### Flutter API & Riverpod
1. `withOpacity()` -> use `withValues(alpha: x)`
2. `value` on DropdownButtonFormField -> use `initialValue` (deprecated since Flutter 3.33)
3. `setState` after `dispose` -> check `mounted` first
4. `ref.watch()` in callbacks -> use `ref.read()`

### Drift & Data Layer
5. `.equals()` on enum Drift column -> use `.equalsValue()`
6. Import table via app_database for DAO -> import DIRECTLY from table file
7. `client.from()` in feature/UI layer -> use Repository (exception: admin/)
8. Hardcoded Supabase table/column names -> use `SupabaseConstants`
9. Sending `created_at`/`updated_at` to Supabase -> use `.toSupabase()`

### Text, Icons & Logging
10. `print()` -> use `AppLogger`
11. Hardcoded text -> use `.tr()` (easy_localization, 3 languages: tr/en/de)
12. `Icon(Icons.x)` for domain icons -> use `AppIcon(AppIcons.x)` (SVG via flutter_svg)
13. Hardcoded SVG paths -> use `AppIcons` constants from `app_icons.dart`
14. `IconData` param in shared widgets -> use `Widget` param (EmptyState, InfoCard, StatCard, etc.)

### Enum Safety
15. Missing `@JsonKey(unknownEnumValue: X.unknown)` on enum fields in Freezed models
16. `switch` without `unknown` case for server-side enums

### Navigation & Style
17. `context.go()` for forward navigation -> use `context.push()` (go replaces stack)
18. Parameterized route before specific in GoRouter -> specific FIRST (`form` before `:id`)
19. Hardcoded colors/spacing -> use `Theme.of(context)` / `AppSpacing`

### Code Quality
20. Missing `controller.dispose()` -> ALWAYS dispose in ConsumerStatefulWidget
21. Missing `const Model._()` in Freezed -> ALWAYS add private constructor
22. Bare `catch (e)` without logging -> use `AppLogger.error`
23. Critical errors without Sentry -> use `Sentry.captureException`
24. `LucideIcons` for domain icons -> use `AppIcon(AppIcons.x)` (LucideIcons only for generic UI)

## Common Workflows

### Adding a new entity (full stack)
```
Model → Enum → Table → Converter → Mapper → DAO → DB registration → RemoteSource → Repository → Provider → Screen → Routes → L10n
```
See `new-feature-checklist.md` for detailed steps.

### Adding a localization key
1. Add to `assets/translations/tr.json` (master)
2. Add to `assets/translations/en.json`
3. Add to `assets/translations/de.json`
4. Use: `'feature.key_name'.tr()`
5. Verify: `python3 scripts/check_l10n_sync.py`

### Pre-commit quality check
```bash
flutter analyze --no-fatal-infos && python3 scripts/verify_code_quality.py && python3 scripts/check_l10n_sync.py
```

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
