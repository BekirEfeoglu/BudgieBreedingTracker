# New Feature Checklist

## Full-Stack Entity Addition

```
1.  Model (Freezed)      -> lib/data/models/
2.  Enum (if needed)     -> lib/core/enums/
3.  Table (Drift)        -> lib/data/local/database/tables/
4.  Converter            -> lib/data/local/database/converters/
5.  Mapper               -> lib/data/local/database/mappers/
6.  DAO                  -> lib/data/local/database/daos/
7.  DB Registration      -> app_database.dart (include DAO + table)
8.  Remote Source        -> lib/data/remote/api/
9.  Repository           -> lib/data/repositories/
10. Repository Provider  -> lib/data/repositories/repository_providers.dart
11. Feature Providers    -> lib/features/<name>/providers/
12. Screens              -> lib/features/<name>/screens/
13. Widgets              -> lib/features/<name>/widgets/
14. Routes               -> lib/router/routes/ (specific before :id)
15. L10n Keys            -> assets/translations/{tr,en,de}.json
16. Tests                -> test/ (mirror lib/ structure)
```

### Critical Reminders Per Step
- **Step 1**: Add `const Model._()` private constructor, `@JsonKey(unknownEnumValue:)` on enum fields
- **Step 3**: Import table directly, not via `app_database.dart`
- **Step 5**: Use `.equalsValue()` for enum columns
- **Step 8**: Use `SupabaseConstants` for table/column names, `.toSupabase()` for writes
- **Step 9**: Extend `BaseRepository`, add `SyncableRepository` if syncable
- **Step 14**: Specific routes BEFORE parameterized (`:id`), use `context.push()` not `context.go()`
- **Step 15**: Add to all 3 languages simultaneously, Turkish first (master)

## Non-Entity Feature (UI-only)
```
1. Feature Providers  -> lib/features/<name>/providers/
2. Screens            -> lib/features/<name>/screens/
3. Widgets            -> lib/features/<name>/widgets/
4. Routes             -> lib/router/routes/
5. L10n Keys          -> assets/translations/{tr,en,de}.json
6. Tests              -> test/features/<name>/
```

## Adding a Widget to Shared Library
```
1. Create widget       -> lib/core/widgets/ (or buttons/, cards/, dialogs/)
2. Accept Widget icon  -> NOT IconData (for domain flexibility)
3. Use Theme/AppSpacing -> no hardcoded colors or spacing
4. Add tests           -> test/core/widgets/
```

## Pre-Commit
Quality gates: see ai-workflow.md § Quality Gates

> **Related**: data-layer.md (Drift/Supabase details), localization.md (l10n workflow), coding-standards.md (naming, anti-patterns)
