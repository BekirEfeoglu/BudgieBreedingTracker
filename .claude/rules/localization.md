# Localization

## Setup
- Package: `easy_localization`
- Languages: Turkish (master), English, German
- Files: `assets/translations/{tr,en,de}.json`
- ~2,604 keys per language, 39 categories

## Key Naming
```
category.key_name
```
- Lowercase snake_case
- Dot notation for namespace: `'birds.add_bird'.tr()`
- With args: `'birds.count'.tr(args: ['5'])`

## 39 Categories
nav, common, auth, birds, breeding, eggs, chicks, home, calendar, settings, backup, more, profile, statistics, notifications, premium, genealogy, genetics, admin, user_guide, sync, errors, validation, incubation, environment, health_records, error, feedback, splash, export, import, ads, community, marketplace, messaging, badges, gamification, leaderboard, legal

## Workflow
1. Add key to `tr.json` (master) first
2. Add same key to `en.json` and `de.json`
3. Use: `'category.key_name'.tr()`
4. Verify: `python3 scripts/check_l10n_sync.py`

## Rules
- NEVER hardcode user-visible text — always use `.tr()`
- Turkish is the master language — all keys must exist in tr.json first
- CI job `l10n-sync` enforces key parity across all 3 languages
- Keep keys concise but descriptive
