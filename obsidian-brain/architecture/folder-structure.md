# Folder Structure

Source: `.claude/rules/architecture.md`, `CLAUDE.md` § Key File Locations

## lib/ Topology

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_icons.dart         99 SVG icon path constants
│   │   ├── supabase_constants.dart  SupabaseConstants (151 string table/column/bucket constants)
│   │   └── app_spacing.dart       AppSpacing.xs/sm/md/lg/xl/xxl/xxxl
│   ├── enums/                     15 enum files
│   ├── errors/                    AppException hierarchy
│   ├── providers/                 Cross-feature providers (auth, connectivity)
│   ├── security/                  FlutterSecureStorage wrappers
│   ├── theme/                     AppTheme, AppColors
│   └── widgets/                   35 shared widgets (15 root + buttons/cards/dialogs/bottom_sheet/eggs below)
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
│   │   │   └── app_database.dart  schemaVersion=26, DriftDatabase class
│   │   └── preferences/           AppPreferences (SharedPreferences wrapper)
│   ├── remote/
│   │   ├── api/                   28 *_remote_source.dart files + base/caches/providers
│   │   ├── storage/               storage_service.dart
│   │   └── supabase/              edge_function_client.dart, supabase_client.dart
│   └── repositories/              23 entity repos + base + sync_metadata
│       └── repository_providers.dart
│
├── domain/
│   └── services/                  23 directories of business logic
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
├── router/                        See [[architecture/router-navigation]]
│   ├── app_router.dart
│   ├── route_names.dart           AppRoutes constants (74 routes)
│   ├── redirect_guards.dart       Session lock / auth / 2FA redirects
│   ├── route_utils.dart           UUID + editId deep-link validation
│   ├── router_notifier.dart       refreshListenable
│   ├── guards/
│   │   ├── admin_guard.dart
│   │   ├── founder_guard.dart
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
│   ├── tr.json    Master (3,050 keys, 41 categories)
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
