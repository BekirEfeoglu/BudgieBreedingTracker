# Architecture

## Tech Stack
Flutter 3.41+ · Dart >=3.8.0 <4.0.0 · Riverpod 3 · GoRouter 17+ · Supabase · Drift 2.31+ · Freezed 3 · easy_localization · Sentry · RevenueCat

## Layers

```
lib/
├── core/           # Constants, enums, errors, security, theme, utils, shared widgets
├── data/           # Models, local DB (Drift), remote API (Supabase), repositories
├── domain/         # Business logic services (genetics, sync, etc.)
├── features/       # 23 feature modules (screens, widgets, providers)
└── router/         # GoRouter config, route guards, route definitions
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
- Features import from: `core/`, `data/`, `domain/`, `router/`
- Features NEVER import from other features (no cross-feature imports)
- `data/remote/` never imported directly in UI — always through Repository
- Exception: `admin/` feature can use `client.from()` directly

### Resolving Cross-Feature Need
When feature A needs something from feature B:
1. If it's a shared widget → move to `lib/core/widgets/`
2. If it's a shared provider (e.g., currentUser, theme) → move to `lib/core/providers/`
3. If it's domain logic → extract to `lib/domain/services/`
4. Never shortcut with a direct `features/b/...` import — audit flagged `statistics → home`, `auth → birds`, `profile → admin/settings` as drift

## 23 Feature Modules
admin, auth, birds, breeding, calendar, chicks, community, eggs, feedback, gamification, genealogy, genetics, health_records, home, marketplace, messaging, more, notifications, premium, profile, settings, splash, statistics

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
