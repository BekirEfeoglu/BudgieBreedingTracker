# Folder Structure

Source: `.claude/rules/architecture.md`, `CLAUDE.md` § Key File Locations

## lib/ Topology

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_icons.dart         84 SVG icon path constants
│   │   └── app_spacing.dart       AppSpacing.xs/sm/md/lg/xl/xxl/xxxl
│   ├── enums/                     15 enum files
│   ├── errors/                    AppException hierarchy
│   ├── providers/                 Cross-feature providers (auth, connectivity)
│   ├── security/                  FlutterSecureStorage wrappers
│   ├── theme/                     AppTheme, AppColors
│   └── widgets/                   29 shared widgets
│       ├── buttons/               4 button widgets
│       ├── cards/                 2 card widgets
│       ├── dialogs/               2 dialog widgets
│       ├── bottom_sheet/          1 bottom sheet widget
│       └── eggs/                  5 egg widgets
│
├── data/
│   ├── models/                    29 Freezed model files
│   ├── local/
│   │   ├── database/
│   │   │   ├── tables/            20 Drift table definitions
│   │   │   ├── daos/              20 DAO classes
│   │   │   ├── mappers/           20 Mapper classes
│   │   │   ├── converters/        enum_converters.dart
│   │   │   └── app_database.dart  schemaVersion=25, DriftDatabase class
│   │   └── preferences/           AppPreferences (SharedPreferences wrapper)
│   ├── remote/
│   │   ├── api/                   26 remote source classes
│   │   ├── storage/               storage_service.dart
│   │   └── supabase/              Edge function invokers, SupabaseConstants
│   └── repositories/              23 entity repos + base + sync_metadata
│       └── repository_providers.dart
│
├── domain/
│   └── services/                  22 directories of business logic
│       ├── genetics/
│       ├── sync/
│       ├── incubation/
│       ├── local_ai/
│       └── ...
│
├── features/                      24 feature modules
│   └── <name>/
│       ├── screens/
│       ├── widgets/
│       └── providers/
│
├── router/
│   ├── app_router.dart
│   ├── route_names.dart           AppRoutes constants (73 routes)
│   ├── guards/
│   │   ├── admin_guard.dart
│   │   └── premium_guard.dart
│   └── routes/                    Route files by domain
│       ├── admin_routes.dart
│       ├── auth_routes.dart
│       ├── community_routes.dart
│       └── ...
│
├── shared/                        Thin facade exports (cross-feature compatibility)
└── test_support/                  Test helpers (not imported by production code)
```

## assets/ Topology

```
assets/
├── translations/
│   ├── tr.json    Master (~2,992 keys, 41 categories)
│   ├── en.json
│   └── de.json
├── images/
│   └── app_icon.png, app_icon_ios.png  (finalized 2026-04-06, do not modify)
└── icons/             10 subdirectories
    ├── navigation/
    ├── birds/
    ├── breeding/
    ├── eggs/
    ├── chicks/
    ├── genetics/
    ├── admin/
    └── ...
```

## test/ Topology

```
test/
├── core/
├── data/
├── domain/
├── features/
├── router/
├── helpers/          mocks.dart, pump_helpers.dart, fixtures
├── golden/
└── e2e/
```

Mirrors `lib/` structure.

## See Also

- [[architecture/layers]] — import rules
- [[data-layer/drift]] — tables, DAOs details
- [[patterns/assets-images]] — SVG icon system
