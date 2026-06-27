# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Start Here
- **Knowledge base**: `obsidian-brain/` is the comprehensive wiki (architecture, features, data layer, domain services, patterns) — read the relevant page before touching a subsystem. `obsidian-brain/index.md` is the full catalog. `AGENTS.md` is the compact agent contract; this file + `.claude/rules/*.md` are the detailed rulebook.
- **Quality gates** (run before every commit): `.claude/rules/ai-workflow.md` — canonical entry is `scripts/run_local_quality_gate.sh`
- **New entity/feature steps**: `.claude/rules/new-feature-checklist.md`
- **24 anti-patterns** (must avoid): see § Critical Anti-Patterns below
- **Branch policy**: permanent remote branch is `main`; short-lived branches target `main` (see `.claude/rules/branch-workflow.md`). Verify pushed commits with `python3 scripts/check_remote_status.py`

## Project
Comprehensive Flutter breeding tracker app for budgie breeders.
Flutter 3.41+ / Dart >=3.8.0 <4.0.0 / Riverpod 3 / GoRouter 17+ / Supabase / Drift 2.31+ / Freezed 3

Key deps: `supabase_flutter ^2.5.0` · `sentry_flutter ^9.0.0` · `fl_chart ^1.2.0` · `purchases_flutter ^10.0.2`

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
python3 scripts/check_platform_targets.py # Verify unsupported Flutter web target is absent
python3 scripts/check_obsidian_brain.py  # Verify obsidian-brain index, links, and page length
python3 scripts/verify_code_quality.py    # Anti-pattern scan (27 checkers, 19/24 CLAUDE.md patterns + 9 extra documented scanners)
python3 scripts/verify_rules.py          # Validate CLAUDE.md stats against codebase (single source of truth)
python3 scripts/verify_rules.py --fix    # Auto-fix CLAUDE.md stats + rule inline references
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
scripts/test_check_platform_targets.py  # Tests for platform target policy
scripts/test_check_obsidian_brain.py    # Tests for obsidian-brain wiki lint
```

## Codebase Stats

| Metric | Value |
| --- | --- |
| Source files (lib/) | 987 Dart files |
| Test files (test/) | 903 test files, 11,099+ individual tests |
| Feature modules | 24 |
| Drift tables / DAOs / Mappers | 20 each |
| Repositories | 23 entity + base + sync_metadata |
| Remote sources | 26 entity + base + 2 caches + providers |
| Freezed models | 29 model files + statistics_models + supabase_extensions |
| Domain services | 22 directories |
| Routes | 73 |
| Custom SVG icons | 89 constants, 89 files on disk |
| Shared widgets | 29 (15 root + 4 buttons + 2 cards + 2 dialog + 1 bottom_sheet + 5 eggs) |
| Enum files | 15 |
| Supabase constants | 142 (tables + buckets + columns) |
| L10n keys | ~2,995 per language, 41 categories |
| DB schema version | 25 |

## CI/CD Pipeline

### GitHub Actions (`ci.yml`) — runs on PRs and main pushes
| Job | Purpose |
| --- | --- |
| `analyze` | `flutter analyze --no-fatal-infos` |
| `test` | Unit + widget tests, Codecov upload (excludes golden, e2e, community), timeout 25m |
| `golden-test` | Visual regression on Linux baseline |
| `edge-functions-test` | `deno test --allow-env --allow-net supabase/functions` (deploy gate) |
| `e2e-community-test` | E2E + community tagged tests |
| `scripts-test` | Python script tests (>=98% coverage) |
| `l10n-sync` | Translation key parity (--strict-keys) |
| `code-quality` | Anti-pattern scan + platform target policy + obsidian-brain lint (depends on scripts-test) |
| `rules-sync` | CLAUDE.md stats verification (--strict) |
| `security-audit` | Security posture verification (cert pinning, secrets) |
| `auto-fix-stats` | Auto-PR for CLAUDE.md drift (main only) |
| `deploy-edge-functions` | Supabase Edge Function deployment (main only, needs analyze+test+edge-functions-test) |
| `android-build` | Debug APK build |
| `ios-build` | iOS build (no code signing) |

Other workflow files: `release-ready.yml` (manual signed Android AAB), `release.yml`, `pages.yml` (GitHub Pages from `docs/`), `dependabot-auto-merge.yml`, `stale*.yml`, `auto-label.yml`.

Workflow changes must be validated locally before push: parse the edited YAML, quote or block-scalar `run:` commands containing `:`, and ensure each triggering event has at least one non-skipped job.

Xcode Cloud is separate from GitHub Actions. Its Flutter iOS setup lives in `ios/ci_scripts/ci_post_clone.sh`; the script must remain executable, retry network-dependent setup, preserve real command exit codes, and fail fast if `Generated.xcconfig` or `Pods-Runner-*.xcfilelist` files are not generated.

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
| `REVENUECAT_SECRET_API_KEY` | Edge Function secret | — | Server-side RevenueCat subscription verification |
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
| `REVENUECAT_SECRET_API_KEY` | `sync-premium-status` + `revenuecat-webhook` Edge Function runtime | RevenueCat Dashboard → Project settings → API keys → Secret API keys |
| `REVENUECAT_WEBHOOK_AUTH_TOKEN` | `revenuecat-webhook` shared secret | Generated by you (32+ random bytes), set in Supabase Edge Function secrets AND in RevenueCat → Integrations → Webhooks → Authorization header |

## Supabase

### Edge Functions (12)
| Function | Purpose |
| --- | --- |
| `create-community-comment` | Moderated server-side community comment creation |
| `create-community-post` | Moderated server-side community post creation |
| `mfa-lockout` | MFA brute-force lockout handling |
| `moderate-content` | Community content moderation |
| `revenuecat-webhook` | RevenueCat subscription events → server-side premium sync (shared-secret auth, `verify_jwt=false`) |
| `revoke-oauth-token` | Google/Apple OAuth token revocation |
| `scan-image-safety` | Photo upload safety scan |
| `send-push` | FCM push notification delivery |
| `system-health` | Admin dashboard system health check |
| `sync-premium-status` | Server-side RevenueCat premium status verification (client-initiated pull) |
| `upload-community-photo` | Community photo moderation, storage upload, and signed URL creation |
| `validate-free-tier-limit` | Free tier entity limit enforcement |

### Migrations
174 SQL migration files in `supabase/migrations/`. Schema managed server-side; never modify RLS policies from client code.

## Rules

Comprehensive rules in `.claude/rules/` (auto-loaded):

| File | Scope |
| --- | --- |
| `architecture.md` | Tech stack, layers, folder structure, data flow, offline-first, performance, dependency mgmt |
| `data-layer.md` | Drift + Supabase + Repository + Sync strategy + Storage + Cache + migration guidelines |
| `coding-standards.md` | Naming, Freezed/enum, icon API, file organization, extensions, async/await |
| `providers.md` | Riverpod provider types, ref usage, AsyncNotifier, race conditions, error handling, keepAlive |
| `ui-patterns.md` | Widget types, AsyncValue, forms, GoRouter, shared widgets, lists, dialogs |
| `localization.md` | easy_localization, key structure, 41 categories, arg patterns, testing l10n |
| `testing.md` | Test patterns, mocking, golden tests, coverage, naming conventions |
| `test-stability.md` | Pump strategy, 18 anti-patterns, async patterns, resource cleanup |
| `error-handling.md` | Error hierarchy, Sentry, retry/backoff, user-facing messages, logging |
| `new-feature-checklist.md` | Full-stack entity addition, non-entity features, shared widgets |
| `git-rules.md` | Conventional commits, branch naming, PR workflow (main-first) |
| `branch-workflow.md` | main-only branch strategy, merge policy, hotfix exception |
| `ai-workflow.md` | Quality gates (canonical), task approach, prohibited actions, investigation |
| `chat.md` | Response language (Turkish), debugging approach, code review feedback |
| `ci-actions.md` | GitHub Actions design, Dependabot, billing failures, deployment safety |
| `release-ops.md` | Release channels, version bump, environment discipline, Supabase ops |
| `edge-functions.md` | Edge fn inventory, auth/validation, MFA policy, invocation, testing, deploy |
| `security.md` | Auth, RLS, route guards, credentials, data protection, OAuth |
| `performance.md` | Drift optimization, Riverpod rebuilds, widget perf, images, sync, startup |
| `accessibility.md` | WCAG 2.1 AA, touch targets, semantic labels, contrast, font scaling |
| `observability.md` | AppLogger + Sentry, breadcrumb, tag conventions, PII protection, sample rate budget, structured schema |
| `code-review.md` | Self-review + reviewer checklist, anti-pattern spot-check, approval rules |
| `premium-revenuecat.md` | PremiumGuard, entitlement, grace period, sync-premium-status, free tier limits, env vars |
| `notifications.md` | FCM, send-push, local notifications, scheduling, deeplink payload, permissions |
| `forms-validation.md` | Form pattern, validator hierarchy, async validation, ValidationException flow |
| `assets-images.md` | Photo upload, scan-image-safety, 10MB guard, CachedNetworkImage, storage buckets, SVG icons |
| `background-sync.md` | SyncService, connectivity-aware retry, debounce/batch, conflict accounting, ValidatedSyncMixin |
| `datetime-format.md` | UTC at boundary, local display, incubation day math, locale-aware DateFormat, tz.TZDateTime |
| `local-ai.md` | LocalAiService, Ollama/OpenRouter routing, cache, cost guards, fallback, PII redaction |
| `feature-flags.md` | dart-define debug flags, runtime toggles, kill switches, premium gating, lifecycle |
| `empty-loading-error-states.md` | EmptyState/LoadingState/ErrorState/SkeletonLoader catalog, AsyncValue mapping |
| `migrations.md` | Drift schemaVersion bump, onUpgrade, Supabase SQL migration, RLS, idempotent SQL, rollback |
| `breeding-eggs.md` | Bird→BreedingPair→Incubation→Egg→Chick lifecycle, write atomicity, side effects, free tier guards |
| `genetics.md` | Punnett, MUTAVI rates, calculationVersion, allelic series, sex-linked linkage, lethal combos, inbreeding |
| `encryption.md` | AES-256-CBC + HMAC, secure storage key mgmt, key rotation, payload codec, what-to-encrypt |
| `moderation.md` | Two-layer text pipeline, image safety, fail-closed, context-aware threshold, report flow |
| `community.md` | Online-first feed exemption, post lifecycle, comment, like, report, block/mute, RLS policy |
| `messaging.md` | Online-first DM, conversation model, delivery status, read receipts, typing, attachments |
| `admin.md` | AdminGuard, audit logs, destructive guards, moderation queue, monitoring, race mitigation |
| `marketplace.md` | Listing lifecycle, strict moderation, premium gates, ad placement, contact flow, RLS |
| `gamification.md` | XP rules, level curve, badges, leaderboard, verified breeder, anti-gambling, streak |
| `statistics.md` | fl_chart patterns, aggregation in Drift, performance budget, premium gating, accessibility |
| `calendar.md` | Event generation, reminder schedule, notification ID stability, deeplink, sync integration |
| `data-io.md` | Backup (PBKDF2 + AES), Excel import/export, PDF pedigree, free vs premium, restore safety |
| `home-widget.md` | iOS/Android widget bridge, shared storage schema, refresh triggers, deeplink, limitations |
| `presence.md` | Online/away/offline TTL, heartbeat, privacy visibility, typing, last-seen, battery rules |

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
Shared UI:     lib/core/widgets/ (buttons/, cards/, dialogs/, bottom_sheet/)
Icons:         lib/core/constants/app_icons.dart
SVG Assets:    assets/icons/ (10 subdirs)
Translations:  assets/translations/ (tr.json, en.json, de.json)
Security:      lib/core/security/
Preferences:   lib/data/local/preferences/
EdgeFunctions: lib/data/remote/supabase/
Edge Fn (SB):  supabase/functions/
Migrations:    supabase/migrations/ (174 files)
Scripts:       scripts/
CI:            .github/workflows/ + codemagic.yaml
```
