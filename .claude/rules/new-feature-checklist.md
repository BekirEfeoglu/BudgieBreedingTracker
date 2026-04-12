# New Feature Checklist

## Full-Stack Entity Addition

```
1. Model (Freezed)     → lib/data/models/
2. Enum (if needed)    → lib/core/enums/
3. Table (Drift)       → lib/data/local/database/tables/
4. Converter           → lib/data/local/database/converters/
5. Mapper              → lib/data/local/database/mappers/
6. DAO                 → lib/data/local/database/daos/
7. DB Registration     → app_database.dart (include DAO + table)
8. Remote Source       → lib/data/remote/api/
9. Repository          → lib/data/repositories/
10. Repository Provider → lib/data/repositories/repository_providers.dart
11. Feature Providers   → lib/features/<name>/providers/
12. Screens            → lib/features/<name>/screens/
13. Widgets            → lib/features/<name>/widgets/
14. Routes             → lib/router/routes/ (specific before :id)
15. L10n Keys          → assets/translations/{tr,en,de}.json
16. Tests              → test/ (mirror lib/ structure)
```

## Pre-Commit Checklist
- [ ] `flutter analyze --no-fatal-infos` — 0 errors
- [ ] `python3 scripts/verify_code_quality.py` — 0 errors
- [ ] `python3 scripts/check_l10n_sync.py` — all languages synced
- [ ] `python3 scripts/verify_rules.py --fix` — CLAUDE.md stats updated
- [ ] `flutter test` — all tests pass
- [ ] Freezed models have `const Model._()`
- [ ] Enum fields have `@JsonKey(unknownEnumValue:)`
- [ ] Controllers disposed in `dispose()`
- [ ] No hardcoded text — all `.tr()`
- [ ] No `print()` — use `AppLogger`
