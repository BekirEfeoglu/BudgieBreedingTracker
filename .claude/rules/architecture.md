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
UI (Features) → Providers (Riverpod) → Repositories → Local (Drift DAOs) + Remote (Supabase API)
```

## Import Rules
- Features import from: `core/`, `data/`, `domain/`, `router/`
- Features NEVER import from other features (no cross-feature imports)
- `data/remote/` never imported directly in UI — always through Repository
- Exception: `admin/` feature can use `client.from()` directly

## 23 Feature Modules
admin, auth, birds, breeding, calendar, chicks, community, eggs, feedback, gamification, genealogy, genetics, health_records, home, marketplace, messaging, more, notifications, premium, profile, settings, splash, statistics

## Security
- RLS policies managed server-side (Supabase)
- Never modify RLS from client code
- Auth guards on protected routes (AdminGuard, PremiumGuard)
- Supabase credentials via dart-define, never hardcoded
