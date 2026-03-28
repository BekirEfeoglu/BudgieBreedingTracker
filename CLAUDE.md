# CLAUDE.md

Muhabbet kusu yetistiricileri icin kapsamli Flutter ureme takip uygulamasi.
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

# Run tests matching a name pattern
flutter test --name "pattern"

# Format code
dart format .

# Apply automatic fixes
dart fix --apply
```

### Quality Scripts (Python)
```bash
python scripts/check_l10n_sync.py       # Verify tr/en/de translation keys are in sync
python scripts/verify_code_quality.py    # Anti-pattern scan (21 checkers, 16/17 CLAUDE.md patterns + 5 extra)
python scripts/verify_rules.py          # Validate CLAUDE.md stats against codebase (single source of truth)
python scripts/verify_rules.py --fix    # Auto-fix CLAUDE.md stats table with actual values
```

## Codebase Stats

| Metric | Value |
| --- | --- |
| Source files (lib/) | 717 Dart files |
| Test files (test/) | 680 test files, 7,974+ individual tests |
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
| L10n keys | ~3 per language, 35 categories |
| DB schema version | 17 |

## Architecture Overview

**Flutter offline-first app** for budgie breeders. Drift (SQLite) is the primary data source; Supabase provides cloud sync with server-wins conflict resolution.

### Data Flow
```
UI (ConsumerWidget) -> ref.watch(provider) -> Repository -> { DAO (Drift) + RemoteSource (Supabase) }
```

All writes go to local SQLite first, then sync to Supabase in the background. All queries are user-scoped (`userId` + `isDeleted` filters).

### Layer Hierarchy (import rules enforced)
```
core/       -> No imports from data/, domain/, features/
data/       -> No imports from features/
domain/     -> Can import data/
features/   -> Can import core/, data/, domain/
router/     -> Can import features/ (screens only)
```

### Key Patterns

**Entity data path** (full chain for any entity):
`Freezed Model -> Drift Table -> Enum Converter -> Mapper -> DAO -> RemoteSource -> Repository -> Provider -> Widget`

**Provider chain** (filter/search):
`StreamProvider (raw) -> NotifierProvider (filter state) -> Provider.family (filtered) -> Provider.family (searched+filtered)`

**Form pattern**: `NotifierProvider<FormNotifier, FormState>` with `isLoading/error/isSuccess` fields, `ref.listen` in widget for navigation/snackbar side effects.

**Two empty states**: "no data yet" (with action button to add) vs "no search results" (search icon, no action).

**Local-only entities** (no remote sync): GeneticsHistory, UserPreferences, NotificationSettings — providers access DAO directly, skipping Repository.

### Sync Architecture
- Push order follows FK dependencies: Profile -> Birds+Nests -> BreedingPairs -> Clutches -> Eggs -> Chicks -> ...
- Conflict resolution: server-wins via `insertOnConflictUpdate()`
- ProfileRepository is special: push-before-pull (single-record)
- SyncOrchestrator runs every 15 min, full reconciliation every 6h
- Retry: max 5 retries, exponential backoff (30s → 10min cap)

### Code Generation (build.yaml)
- `json_serializable`: `field_rename: snake`, `explicit_to_json: true`
- `freezed`: `from_json: true`, `to_json: true`
- `drift_dev`: `store_date_time_values_as_text: true`
- Generated files: `*.g.dart`, `*.freezed.dart` (excluded from git)

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

## Project-Specific Conventions

- **Spacing**: `AppSpacing` constants (xs=4, sm=8, md=12, lg=16, xl=20, xxl=24, xxxl=32)
- **Touch targets**: minimum 44px (`AppSpacing.touchTargetMin`)
- **Colors/styles**: always via `Theme.of(context)`, never hardcoded
- **Icons**: 82 custom SVG icons via `AppIcons` constants + `AppIcon` widget; LucideIcons for generic UI icons
- **Shared widgets accepting `Widget icon`** (not IconData): EmptyState, InfoCard, StatCard, FabButton, PrimaryButton, StatusBadge
- **Localization**: `'feature.key'.tr()` — master file is `tr.json` (~1,935 keys, 35 categories)
- **Database**: Schema version 17, migration via for-loop + switch pattern
- **Riverpod 3**: No StateProvider (use NotifierProvider), no `.valueOrNull` (use `.value`)
- **Freezed 3**: Always add `const Model._()` private constructor
- **Supabase**: Table/column names via `SupabaseConstants` (94 constants), never hardcoded
- **File limit**: 300 lines per file; split using `part` directive if needed
- **Error tracking**: Sentry for critical errors, `AppLogger` for all logging
- **Responsive**: `NavigationBar` (< 600px) / `NavigationRail` (>= 600px) in MainShell

## CI Pipeline

Five required checks on PRs to `main`:
1. **Flutter Analyze** — `flutter analyze --no-fatal-infos`
2. **Flutter Test** — `flutter test --exclude-tags golden`
3. **Localization Sync** — `python scripts/check_l10n_sync.py`
4. **Code Quality** — `python scripts/verify_code_quality.py`
5. **Rules Sync** — `python scripts/verify_rules.py` (CLAUDE.md stats vs codebase)

Golden tests are tagged and excluded from CI (platform-dependent).

## Key File Locations

```
Providers:     lib/features/<feature>/providers/
Screens:       lib/features/<feature>/screens/
Widgets:       lib/features/<feature>/widgets/
Models:        lib/data/models/                 (21 Freezed models + statistics_models + supabase_extensions)
Enums:         lib/core/enums/                  (12 enum files)
Security:      lib/core/security/               (certificate_pinning, inactivity_guard)
Extensions:    lib/core/extensions/             (context_extensions, num_extensions)
Tables:        lib/data/local/database/tables/  (20 Drift tables)
DAOs:          lib/data/local/database/daos/    (20 DAOs)
Mappers:       lib/data/local/database/mappers/ (20 mappers)
Repos:         lib/data/repositories/           (20 entity repos + base + sync_metadata)
Remote:        lib/data/remote/api/             (20 entity sources + base + 2 caches + providers)
Services:      lib/domain/services/             (14 dirs: ads, auth, backup, calendar, encryption, export,
                                                 genetics, import, incubation, moderation, notifications,
                                                 payment, premium, sync)
Router:        lib/router/                      (60 routes, 2 guards: admin, premium; auth inline)
Theme:         lib/core/theme/                  (4 files: colors, spacing, typography, theme)
Shared UI:     lib/core/widgets/                (19 widgets: 14 root + 2 buttons + 2 cards + 1 dialog)
Icons:         lib/core/constants/app_icons.dart (82 SVG path constants)
SVG Assets:    assets/icons/                    (10 subdirectories, 82 SVG files)
Preferences:   lib/data/local/preferences/      (AppPreferences)
EdgeFunctions: lib/data/remote/supabase/        (EdgeFunctionClient)
Translations:  assets/translations/             (~3 leaf keys per language, 35 categories)
Database:      schemaVersion 17 (switch-based migration, 30+ perf indexes)
```

## Detailed Rules

Comprehensive rules are in `.claude/rules/` (auto-loaded as project instructions):
- `architecture.md` — tech stack, folder structure, data flow, sync, storage, security, encryption
- `coding-standards.md` — naming, style, anti-patterns, model/enum rules, testing
- `providers.md` — Riverpod provider types, dependency chain, ref usage
- `database.md` — Drift tables/DAOs/mappers, migration pattern, repository
- `widgets.md` — widget types, AsyncValue handling, form/card/list patterns
- `navigation.md` — GoRouter routes (60), guards, edit mode, route ordering
- `localization.md` — easy_localization setup, key structure, sync workflow
- `supabase_rules.md` — auth, remote source, sync, RLS, storage, edge functions
- `new-feature-checklist.md` — step-by-step guide for adding new features
- `ai-workflow.md` — task approach, quality gates, prohibited actions
- `chat.md` — response language (Turkish), post-coding suggestion format
- `git-rules.md` — conventional commits, branch naming, PR workflow
