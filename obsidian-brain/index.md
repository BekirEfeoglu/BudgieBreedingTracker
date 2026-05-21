# Wiki Index

Full catalog of every page in the obsidian-brain wiki.

## Root

| Page | Description |
|------|-------------|
| [[README]] | Entry point, quick navigation |
| [[CLAUDE.md]] | Wiki schema and maintenance contract |
| [[index]] | This page |
| [[cheat-sheet]] | Task-oriented "how do I…" / "where is…" / "when does…" |
| [[log]] | Chronological change log |
| [[overview]] | High-level synthesis — what the app does, architecture diagram, key decisions |

## Architecture

| Page | Description |
|------|-------------|
| [[architecture/tech-stack]] | Flutter/Dart versions, all packages from pubspec.yaml |
| [[architecture/layers]] | 5 layers, import rules, core/ and data/ contents |
| [[architecture/data-flow]] | Runtime read/write paths, sync cycle |
| [[architecture/offline-first]] | Local-first philosophy, sync triggers, SyncMetadata |
| [[architecture/online-first-exemption]] | When *Repository ≠ offline-first (Community, Messaging) |
| [[architecture/folder-structure]] | Full lib/ and assets/ topology |

## Features (25 modules)

| Page | Module |
|------|--------|
| [[features/_features-index]] | Map of all 25 modules, entity lifecycle |
| [[features/admin]] | Admin dashboard, system management |
| [[features/app_update]] | In-app update prompting |
| [[features/auth]] | Login, register, MFA, OAuth |
| [[features/birds]] | Bird CRUD, profile, photo gallery |
| [[features/breeding]] | Breeding pairs, incubation management |
| [[features/calendar]] | Event calendar |
| [[features/chicks]] | Chick tracking |
| [[features/community]] | Community feed (online-first) |
| [[features/eggs]] | Egg tracking, status transitions |
| [[features/feedback]] | In-app feedback |
| [[features/gamification]] | Badges, leaderboard |
| [[features/genealogy]] | Family tree |
| [[features/genetics]] | Punnett calculator, MUTAVI |
| [[features/health_records]] | Bird health events |
| [[features/home]] | Dashboard |
| [[features/marketplace]] | Bird listings |
| [[features/messaging]] | Direct messages (online-first) |
| [[features/more]] | Secondary navigation hub |
| [[features/notifications]] | Notification settings |
| [[features/premium]] | Subscription, RevenueCat |
| [[features/profile]] | User profile |
| [[features/settings]] | App settings |
| [[features/splash]] | Startup, deep link |
| [[features/statistics]] | Breeding analytics and charts |
| [[features/update]] | Forced update screen |

## Data Layer

| Page | Description |
|------|-------------|
| [[data-layer/drift]] | Local SQLite, 20 tables, DAOs, schema v24 |
| [[data-layer/supabase]] | Remote Postgres, SupabaseConstants, storage, .toSupabase() |
| [[data-layer/repositories]] | BaseRepository, SyncableRepository, ValidatedSyncMixin |
| [[data-layer/sync-strategy]] | Push/pull, idempotency, conflict resolution, retry |
| [[data-layer/migrations]] | Drift onUpgrade + Supabase SQL migrations |
| [[data-layer/tables-catalog]] | All 20 Drift tables with FK parents |

## Domain Services

| Page | Description |
|------|-------------|
| [[domain/services-index]] | Map of all 23 domain services |
| [[domain/auth-service]] | Login, session refresh, MFA |
| [[domain/calendar-service]] | Event scheduling |
| [[domain/data-io]] | Backup (JSON, AES), Excel import/export, PDF export |
| [[domain/eggs-service]] | EggActionsNotifier — lifecycle, chick auto-create, parent closure |
| [[domain/encryption-service]] | AES-256-CBC + HMAC, key rotation, payload codec |
| [[domain/gamification-service]] | XP, level curve, badge progress, verified breeder |
| [[domain/genetics-engine]] | Punnett, MUTAVI, inbreeding, calculationVersion |
| [[domain/home-widget-service]] | iOS / Android home + lock-screen widget bridge |
| [[domain/incubation-service]] | Day math, milestones, species config, environment monitor |
| [[domain/local-ai]] | LLM image+text (Ollama/OpenRouter) |
| [[domain/moderation-service]] | Text + image safety, fail-closed pipeline |
| [[domain/notification-service]] | FCM + local notifications |
| [[domain/premium-service]] | RevenueCat + entitlement |
| [[domain/presence-service]] | Online/last-seen sessions, heartbeat, TTL |
| [[domain/sync-service]] | Background sync orchestration |

## Infrastructure

| Page | Description |
|------|-------------|
| [[infrastructure/ci-cd]] | GitHub Actions jobs, Codemagic, Xcode Cloud |
| [[infrastructure/edge-functions]] | 8 Supabase functions, JWT enforcement, deployment |
| [[infrastructure/environment]] | dart-define vars, Edge Function secrets |
| [[infrastructure/scripts]] | Quality scripts, anti-pattern checkers |
| [[infrastructure/branch-workflow]] | main-only strategy, commit format, quality gates |
| [[infrastructure/release-ops]] | Store releases, version bump, Supabase ops |
| [[infrastructure/marketing-site]] | GitHub Pages product site, anchor navigation, SEO, web QA |

## Patterns

| Page | Description |
|------|-------------|
| [[patterns/anti-patterns]] | All 24 anti-patterns + audit-flagged extras |
| [[patterns/providers]] | Riverpod types, ref usage, AsyncNotifier, race conditions |
| [[patterns/ui-patterns]] | Widget types, AsyncValue, GoRouter, forms, shared widgets |
| [[patterns/testing]] | Test stability, pump strategy, golden tests, 18 anti-patterns |
| [[patterns/l10n]] | Localization workflow, 42 categories, key naming |
| [[patterns/error-handling]] | Exception hierarchy, retry, Sentry usage |
| [[patterns/observability]] | AppLogger + Sentry, PII rules, sample rate budget |
| [[patterns/accessibility]] | WCAG 2.1 AA, 48dp touch targets, semantic labels |
| [[patterns/performance]] | Performance budgets, Drift, Riverpod, images |
| [[patterns/security]] | Auth, RLS, secure storage, MFA lockout |
| [[patterns/datetime-format]] | UTC at boundary, tz.TZDateTime, incubation day math |
| [[patterns/assets-images]] | Photo pipeline, SVG icons, 10MB guard, CachedNetworkImage |
| [[patterns/forms-validation]] | Form skeleton, validators, ValidationException |
| [[patterns/empty-loading-error-states]] | EmptyState/LoadingState/ErrorState/SkeletonLoader |
| [[patterns/feature-flags]] | Compile-time / runtime / entitlement / kill switch |

## Sources

| Page | Description |
|------|-------------|
| [[sources/rules-index]] | Map of .claude/rules/*.md files → wiki pages |
