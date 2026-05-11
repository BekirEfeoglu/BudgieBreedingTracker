# Architecture

## Tech Stack
Flutter 3.41+ · Dart >=3.8.0 <4.0.0 · Riverpod 3 · GoRouter 17+ · Supabase · Drift 2.31+ · Freezed 3 · easy_localization · Sentry · RevenueCat

## Layers

```
lib/
├── core/           # Constants, enums, errors, security, theme, utils, shared widgets
├── data/           # Models, local DB (Drift), remote API (Supabase), repositories
├── domain/         # Business logic services (genetics, sync, etc.)
├── features/       # 25 feature modules (screens, widgets, providers)
├── router/         # GoRouter config, route guards, route definitions
├── shared/         # Curated facade exports for cross-feature reuse
└── test_support/   # Package-visible helpers imported by test/ only
```

## Data Flow
```
UI (Features) -> Providers (Riverpod) -> Repositories -> Local (Drift DAOs) + Remote (Supabase API)
```

### Offline-First Architecture
- Drift (local SQLite) is the source of truth for UI rendering
- Supabase (remote) is the sync target and backup
- Repositories orchestrate local <-> remote synchronization
- UI always reads from local DB via providers — never directly from Supabase

## Import Rules
- Features import from: `core/`, `data/`, `domain/`, `router/`, and curated `shared/` facades
- Features NEVER import from other features (no cross-feature imports)
- `data/remote/` never imported directly in UI — always through Repository
- Exception: `admin/` feature can use `client.from()` directly
- `router/` is the composition layer and may import feature screens/providers to assemble routes and guards
- `core/` must not import from `data/`, `features/`, or `shared/`
- `data/` must not import from `features/`
- `lib/test_support/` must only be imported from `test/`; production `lib/` code must not depend on test helpers

### Resolving Cross-Feature Need
When feature A needs something from feature B:
1. If it's a shared widget → move to `lib/core/widgets/`
2. If it's a shared provider (e.g., currentUser, theme) → move to `lib/core/providers/`
3. If it's domain logic → extract to `lib/domain/services/`
4. If immediate migration is too broad, add a narrow `lib/shared/` facade export as a temporary compatibility surface
5. Never shortcut with a direct `features/b/...` import — audit flagged `statistics → home`, `auth → birds`, `profile → admin/settings` as drift

### Shared Facade Rules
`lib/shared/` exists because older feature code already reuses selected widgets/providers across feature boundaries. Keep it as a thin facade layer:
- Allowed: one-line export files that expose an intentionally shared provider, widget, or adapter
- Allowed: compatibility exports that prevent direct `features/x` imports while a component is being migrated
- Not allowed: new business logic, persistence, remote calls, stateful UI implementation, or hidden feature orchestration
- New reusable implementation belongs in `core/widgets`, `core/providers`, `domain/services`, or `data/providers`
- A shared facade export must not create cycles. If two features need each other, extract the dependency downward instead of adding more exports.

## Online-First Exemption

A class named `*Repository` MUST be offline-first (Drift table + DAO + `SyncMetadata` entry) UNLESS it serves a **cross-user public feed or realtime multi-party stream** where the server is the source of truth by design and a local mirror would not improve UX.

Exempt classes MUST declare the exemption in the first doc block:

```dart
/// Online-first: <reason>. No local Drift mirror by design.
```

Currently exempt:
- `CommunityPostRepository` — cross-user public feed, chronological
- `MessagingRepository` — realtime multi-party conversations

Online-only classes that are NOT cross-user/multi-party streams (e.g. a single-user remote-only resource) MUST use `*RemoteService` or `*OnlineSource` naming instead of `*Repository`.

Canonical example: `LocalAiService` (`lib/domain/services/local_ai/local_ai_service.dart`) — LLM inference via Ollama/OpenRouter. Network is mandatory (inference happens on the remote endpoint), so offline-first does not apply; correctly named as `*Service`. Applies short-lived in-memory caching for repeated prompts but does not persist to Drift.

## 25 Feature Modules
admin, app_update, auth, birds, breeding, calendar, chicks, community, eggs, feedback, gamification, genealogy, genetics, health_records, home, marketplace, messaging, more, notifications, premium, profile, settings, splash, statistics, update

## Security
- RLS policies managed server-side (Supabase)
- Never modify RLS from client code
- Auth guards on protected routes (`AdminGuard`, `PremiumGuard`)
- Supabase credentials via dart-define, never hardcoded
- Sensitive data encrypted at rest (secure storage for tokens)
- See security.md for detailed security patterns

## Performance Considerations
- **Drift queries**: Use indexed columns for filters, avoid `SELECT *` on large tables
- **Widget rebuilds**: Minimize `ref.watch()` scope — watch specific fields, not entire models
- **Image loading**: Use cached network images with proper sizing, lazy load in lists
- **List rendering**: Use `ListView.builder` (lazy) over `ListView` (eager) for long lists
- **Provider caching**: Use `ref.keepAlive()` for expensive computations
- **Startup**: Lazy-initialize heavy services, defer non-critical work

## Dependency Management
- Version constraints in `pubspec.yaml` use caret syntax: `^X.Y.Z`
- Major version bumps require testing all affected features
- Run `flutter pub upgrade --major-versions` cautiously, one package at a time
- Lock file (`pubspec.lock`) committed to repo

> **Related**: data-layer.md (Drift/Supabase details), providers.md (Riverpod patterns), security.md (security rules)
