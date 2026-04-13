# CLAUDE.md

Comprehensive Flutter breeding tracker app for budgie breeders.
Flutter 3.41+ / Dart >=3.8.0 <4.0.0 / Riverpod 3 / GoRouter 17+ / Supabase / Drift 2.31+ / Freezed 3

Key deps: `supabase_flutter ^2.5.0` · `sentry_flutter ^9.0.0` · `fl_chart ^1.2.0` · `purchases_flutter ^9.14.0`

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

### Other Scripts
```bash
scripts/generate_ios_env.sh              # Generate iOS environment config from dart-defines
scripts/setup_push_env.sh               # Setup FCM push notification environment
scripts/monitor_pg_performance.sql       # PostgreSQL performance monitoring queries
scripts/verify_rls_staging.sql           # Verify Row-Level Security policies on staging
scripts/verify_push_setup.sql           # Verify FCM push notification DB setup
```

### Internal Modules (used by quality scripts)
```bash
scripts/_rules_collectors.py             # Data collectors for verify_rules.py
scripts/_rules_fixers.py                 # Auto-fix logic for verify_rules.py --fix
scripts/_rules_utils.py                  # Shared utilities for rules scripts
```

### Script Tests (CI: scripts-test job, >=98% coverage)
```bash
scripts/test_l10n_sync.py               # Tests for check_l10n_sync.py
scripts/test_l10n_sync_main.py          # Main entry tests for l10n sync
scripts/test_code_quality.py            # Tests for verify_code_quality.py
scripts/test_code_quality_main.py       # Main entry tests for code quality
scripts/test_verify_rules.py            # Tests for verify_rules.py
```

## Codebase Stats

| Metric | Value |
| --- | --- |
| Source files (lib/) | 855 Dart files |
| Test files (test/) | 820 test files, 10,093+ individual tests |
| Feature modules | 23 |
| Drift tables / DAOs / Mappers | 20 each |
| Repositories | 23 entity + base + sync_metadata |
| Remote sources | 26 entity + base + 2 caches + providers |
| Freezed models | 29 model files + statistics_models + supabase_extensions |
| Domain services | 16 directories |
| Routes | 72 |
| Custom SVG icons | 84 constants, 84 files on disk |
| Shared widgets | 20 (15 root + 2 buttons + 2 cards + 1 dialog) |
| Enum files | 15 |
| Supabase constants | 106 (tables + buckets + columns) |
| L10n keys | ~2,630 per language, 39 categories |
| DB schema version | 20 |

## CI/CD Pipeline

### GitHub Actions (`ci.yml`) — runs on PRs and main pushes
| Job | Purpose |
| --- | --- |
| `analyze` | `flutter analyze --no-fatal-infos` |
| `test` | Unit + widget tests, Codecov upload (excludes golden, e2e), timeout 25m |
| `golden-test` | Visual regression on Linux baseline |
| `scripts-test` | Python script tests (>=98% coverage) |
| `l10n-sync` | Translation key parity (--strict-keys) |
| `code-quality` | Anti-pattern scan (depends on scripts-test) |
| `rules-sync` | CLAUDE.md stats verification (--strict) |
| `auto-fix-stats` | Auto-PR for CLAUDE.md drift (main only) |
| `deploy-edge-functions` | Supabase Edge Function deployment (main only, needs analyze+test) |
| `android-build` | Debug APK build |
| `android-release` | Signed AAB (main only, needs analyze+test) |
| `ios-build` | iOS build (no code signing) |
| `pages` | GitHub Pages deployment from `docs/` |

### Codemagic (`codemagic.yaml`) — production releases
- `android-release`: AAB → Google Play (alpha track)
- `ios-release`: IPA → App Store TestFlight (App ID: 6759828211)

## Environment Variables (dart-define)

| Variable | Required | Default | Purpose |
| --- | --- | --- | --- |
| `SUPABASE_URL` | Yes | — | Supabase project URL |
| `SUPABASE_ANON_KEY` | Yes | — | Supabase anonymous key |
| `SENTRY_DSN` | No | — | Sentry error tracking DSN |
| `SENTRY_ENVIRONMENT` | No | `production` | Sentry environment tag |
| `REVENUECAT_API_KEY_IOS` | No | — | RevenueCat iOS |
| `REVENUECAT_API_KEY_ANDROID` | No | — | RevenueCat Android |
| `GOOGLE_WEB_CLIENT_ID` | No | — | Google OAuth (web) |
| `GOOGLE_IOS_CLIENT_ID` | No | — | Google OAuth (iOS) |
| `DEBUG_START_ROUTE` | No | — | Debug: open at specific route |
| `DEBUG_GENETICS_FIXTURE` | No | — | Debug: preset genetics state |

Config methods: `.env` + `--dart-define-from-file` (local) · GitHub Secrets (CI) · Codemagic env groups (release)

### CI-Only Secrets (GitHub Actions)

| Secret | Required For | How to Obtain |
| --- | --- | --- |
| `SUPABASE_ACCESS_TOKEN` | Edge Function deployment | Supabase Dashboard → Account → Access Tokens |
| `SUPABASE_PROJECT_REF` | Edge Function deployment | Supabase Dashboard URL project reference ID |

## Supabase

### Edge Functions (6)
| Function | Purpose |
| --- | --- |
| `mfa-lockout` | MFA brute-force lockout handling |
| `moderate-content` | Community content moderation |
| `revoke-oauth-token` | Google/Apple OAuth token revocation |
| `send-push` | FCM push notification delivery |
| `system-health` | Admin dashboard system health check |
| `validate-free-tier-limit` | Free tier entity limit enforcement |

### Migrations
116 SQL migration files in `supabase/migrations/`. Schema managed server-side; never modify RLS policies from client code.

## Rules

Comprehensive rules in `.claude/rules/` (auto-loaded):

| File | Scope |
| --- | --- |
| `architecture.md` | Tech stack, layers, folder structure, data flow, offline-first, performance, dependency mgmt |
| `data-layer.md` | Drift + Supabase + Repository + Sync strategy + Storage + Cache + migration guidelines |
| `coding-standards.md` | Naming, Freezed/enum, icon API, file organization, extensions, async/await |
| `providers.md` | Riverpod provider types, ref usage, AsyncNotifier, race conditions, error handling, keepAlive |
| `ui-patterns.md` | Widget types, AsyncValue, forms, GoRouter, shared widgets, lists, dialogs |
| `localization.md` | easy_localization, key structure, 39 categories, arg patterns, testing l10n |
| `testing.md` | Test patterns, mocking, golden tests, coverage, naming conventions |
| `test-stability.md` | Pump strategy, 18 anti-patterns, async patterns, resource cleanup |
| `error-handling.md` | Error hierarchy, Sentry, retry/backoff, user-facing messages, logging |
| `new-feature-checklist.md` | Full-stack entity addition, non-entity features, shared widgets |
| `git-rules.md` | Conventional commits, branch naming, PR workflow (develop-first) |
| `branch-workflow.md` | develop/main branch strategy, merge policy, hotfix exception |
| `ai-workflow.md` | Quality gates (canonical), task approach, prohibited actions, investigation |
| `chat.md` | Response language (Turkish), debugging approach, code review feedback |
| `ci-actions.md` | GitHub Actions design, Dependabot, billing failures, deployment safety |
| `release-ops.md` | Release channels, version bump, environment discipline, Supabase ops |
| `security.md` | Auth, RLS, route guards, credentials, data protection, OAuth |
| `performance.md` | Drift optimization, Riverpod rebuilds, widget perf, images, sync, startup |

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
19. Hardcoded colors/spacing -> use `Theme.of(context)` / `AppSpacing` (exceptions: genetics phenotype colors, budgie painter)

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

### Adding a new route
1. Add constant to `AppRoutes` in `lib/router/route_names.dart`
2. Add `GoRoute` in `app_router.dart` (specific paths BEFORE `:id` params)
3. Add guard if needed (auth/admin/premium)
4. Edit mode: use query param `?editId=xxx`

### Adding a custom SVG icon
1. Add SVG file to `assets/icons/<category>/`
2. Add constant to `lib/core/constants/app_icons.dart`
3. Use: `AppIcon(AppIcons.newIcon)` — NOT `Icon(Icons.x)`
4. Shared widgets accept `Widget icon` param (not `IconData`)

### Quick debug checklist
```bash
flutter analyze --no-fatal-infos          # Static analysis
flutter test test/path/to/file_test.dart  # Run specific test
dart run build_runner build --delete-conflicting-outputs  # Regenerate if .g.dart stale
```
- Drift query timing: `Stopwatch()..start()` + `AppLogger.debug('perf', 'query: ${sw.elapsed}')`
- Debug route: `--dart-define=DEBUG_START_ROUTE=/birds` to skip splash

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
Converters:    lib/data/local/database/converters/
Repos:         lib/data/repositories/
Remote:        lib/data/remote/api/
Services:      lib/domain/services/
Router:        lib/router/ (+ guards/)
Theme:         lib/core/theme/
Shared UI:     lib/core/widgets/ (buttons/, cards/, dialogs/)
Icons:         lib/core/constants/app_icons.dart
SVG Assets:    assets/icons/ (10 subdirs)
Translations:  assets/translations/ (tr.json, en.json, de.json)
Security:      lib/core/security/
Preferences:   lib/data/local/preferences/
EdgeFunctions: lib/data/remote/supabase/
Edge Fn (SB):  supabase/functions/
Migrations:    supabase/migrations/ (116 files)
Scripts:       scripts/
CI:            .github/workflows/ + codemagic.yaml
```
