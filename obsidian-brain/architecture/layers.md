# Architecture Layers

Source: `.claude/rules/architecture.md`

## The 5 Layers

```
lib/
├── core/        Constants, enums, errors, security, theme, utils, shared widgets
├── data/        Models, local DB (Drift), remote API (Supabase), repositories
├── domain/      Business logic services (genetics, sync, incubation, etc.)
├── features/    24 feature modules (screens, widgets, providers)
└── router/      GoRouter config, route guards, route definitions
```

Additional:
- `lib/shared/` — curated facade exports for cross-feature reuse (thin layer only)
- `lib/test_support/` — package-visible helpers; imported by `test/` only

## Import Rules

| From | Can import | Cannot import |
|------|-----------|---------------|
| `features/` | `core/`, `data/`, `domain/`, `router/`, `shared/` | Other `features/` |
| `data/remote/` | `core/`, `data/models/` | `features/` |
| `core/` | Nothing from `data/`, `features/`, `shared/` | — |
| `domain/` | `core/`, `data/` | `features/` |
| `router/` | Everything (composition layer) | — |
| `test_support/` | `lib/` code | Must never be imported by production `lib/` |

## Resolving Cross-Feature Needs

When feature A needs something from feature B:

1. **Shared widget** → move to `lib/core/widgets/`
2. **Shared provider** (currentUser, theme) → move to `lib/core/providers/`
3. **Domain logic** → extract to `lib/domain/services/`
4. **Temporary** → add narrow `lib/shared/` facade export
5. **Never**: direct `features/b/...` import

## Shared Facade Rules

`lib/shared/` is a thin compatibility layer:
- Allowed: one-line export files exposing an intentionally shared widget/provider
- Not allowed: new business logic, persistence, remote calls, hidden orchestration
- Must not create cycles

## core/ Contents

- `constants/` — `AppIcons`, `AppSpacing`, `SupabaseConstants`
- `enums/` — 15 enum files
- `errors/` — `AppException` hierarchy
- `security/` — secure storage wrappers
- `theme/` — `AppTheme`, `AppColors`
- `utils/` — `AppLogger`, `RelativeTimeFormatter`, helpers
- `widgets/` — 35 shared widgets (15 root + buttons/4 + cards/2 + dialogs/2 + bottom_sheet/1 + eggs/5)
- `providers/` — cross-feature providers (auth state, connectivity, etc.)

## data/ Contents

- `models/` — 29 Freezed model files (+ statistics_models, supabase_extensions)
- `local/database/` — Drift tables (20), DAOs (20), mappers (20), converters, `app_database.dart`
- `local/preferences/` — `AppPreferences` (SharedPreferences wrapper)
- `remote/api/` — 27 remote source classes + base + 2 caches + providers
- `remote/storage/` — `StorageService`
- `remote/supabase/` — Edge function invokers
- `repositories/` — 23 entity repos + base + sync_metadata + `repository_providers.dart`

## See Also

- [[architecture/data-flow]] — runtime data path
- [[architecture/folder-structure]] — full lib/ topology
- [[data-layer/repositories]] — Repository contract
