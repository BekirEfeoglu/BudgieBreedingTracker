# Localization

## Setup
- Package: `easy_localization`
- Languages: Turkish (master), English, German
- Files: `assets/translations/{tr,en,de}.json`
- ~2,663 keys per language, 39 categories

## Key Naming
```
category.key_name
```
- Lowercase snake_case
- Dot notation for namespace: `'birds.add_bird'.tr()`

## Argument Patterns
```dart
// Positional args
'birds.count'.tr(args: ['5'])              // "5 kus"

// Named args
'birds.welcome'.tr(namedArgs: {'name': userName})  // "Hosgeldin, Ali"

// Plural (if needed)
'birds.item_count'.plural(count)           // "1 kus" / "5 kus"
```

## 39 Categories
nav, common, auth, birds, breeding, eggs, chicks, home, calendar, settings, backup, more, profile, statistics, notifications, premium, genealogy, genetics, admin, user_guide, sync, errors, validation, incubation, environment, health_records, error, feedback, splash, export, import, ads, community, marketplace, messaging, badges, gamification, leaderboard, legal

## Workflow
1. Add key to `tr.json` (master) first
2. Add same key to `en.json` and `de.json`
3. Use: `'category.key_name'.tr()`
4. Verify: `python3 scripts/check_l10n_sync.py`

## JSON Structure
```json
{
  "birds": {
    "add_bird": "Kus Ekle",
    "count": "{} kus",
    "no_birds_found": "Hic kus bulunamadi"
  },
  "errors": {
    "network_unavailable": "Internet baglantisi yok",
    "unknown_error": "Bilinmeyen bir hata olustu"
  }
}
```

## Rules
- NEVER hardcode user-visible text — always use `.tr()`
- Turkish is the master language — all keys must exist in `tr.json` first
- CI job `l10n-sync` enforces key parity across all 3 languages
- Keep keys concise but descriptive
- Error messages go in `errors` category
- Validation messages go in `validation` category
- Reusable labels (Save, Cancel, Delete) go in `common` category

## Testing L10n
- Widget tests: mock translations or use `pumpWidget` which includes l10n setup
- Verify no hardcoded Turkish/English text in widget files
- `verify_code_quality.py` checks for hardcoded text violations

> **Related**: ai-workflow.md (l10n workflow), error-handling.md (error message keys), coding-standards.md (no hardcoded text)
