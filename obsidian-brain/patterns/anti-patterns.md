# Anti-Patterns (24 Rules)

Source: `CLAUDE.md` § Critical Anti-Patterns, `.claude/rules/coding-standards.md`

Enforced by `python3 scripts/verify_code_quality.py` (27 checkers — covers 19/24 CLAUDE.md anti-patterns + 8 audit-flagged extras).

## Flutter API & Riverpod

**#1** `withOpacity()` → use `withValues(alpha: x)` (Flutter deprecation)
```dart
// WRONG
color.withOpacity(0.5)
// CORRECT
color.withValues(alpha: 0.5)
```

**#2** `value` on `DropdownButtonFormField` → use `initialValue` (deprecated since Flutter 3.33)

**#3** `setState` after `dispose` → check `mounted` first
```dart
if (!mounted) return;
setState(() { ... });
```

**#4** `ref.watch()` in callbacks → use `ref.read()`
```dart
// WRONG — unintended rebuilds
onPressed: () { final x = ref.watch(provider); }
// CORRECT
onPressed: () { final x = ref.read(provider); }
```

## Drift & Data Layer

**#5** `.equals()` on enum Drift column → use `.equalsValue()`

**#6** Import table via `app_database` for DAO → import DIRECTLY from table file

**#7** `client.from()` in feature/UI layer → use Repository (exception: admin/)

**#8** Hardcoded Supabase table/column names → use `SupabaseConstants`

**#9** Sending `created_at`/`updated_at` to Supabase → use `.toSupabase()`

## Text, Icons & Logging

**#10** `print()` → use `AppLogger`

**#11** Hardcoded text → use `.tr()` (3 languages: tr/en/de)

**#12** `Icon(Icons.x)` for domain icons → use `AppIcon(AppIcons.x)` (SVG)

**#13** Hardcoded SVG paths → use `AppIcons` constants from `app_icons.dart`

**#14** `IconData` param in shared widgets → use `Widget` param

## Enum Safety

**#15** Missing `@JsonKey(unknownEnumValue: X.unknown)` on enum fields in Freezed models

**#16** `switch` without `unknown` case for server-side enums

## Navigation & Style

**#17** `context.go()` for forward navigation → use `context.push()`

**#18** Parameterized route before specific in GoRouter → specific FIRST (`form` before `:id`)

**#19** Hardcoded colors/spacing → use `Theme.of(context)` / `AppSpacing`
- Exceptions: genetics phenotype colors, budgie painter

## Code Quality

**#20** Missing `controller.dispose()` → ALWAYS dispose in ConsumerStatefulWidget

**#21** Missing `const Model._()` in Freezed → ALWAYS add private constructor

**#22** Bare `catch (e)` without logging → use `AppLogger.error`

**#23** Critical errors without Sentry → use `Sentry.captureException`

**#24** `LucideIcons` for domain icons → use `AppIcon(AppIcons.x)` (LucideIcons only for generic UI)

## Audit-Flagged Extra Rules (not numbered in CLAUDE.md)

**A1** `ProviderContainer(...)` without `addTearDown(container.dispose)` — test teardown leak (644+ fixed 2026-04-17)

**A2** `*Repository` naming without offline-first implementation → rename to `*RemoteService`/`*OnlineSource`

**A3** `client.insert()` → `client.upsert()` (idempotent replay)

**A4** FK-parent syncable repo missing `ValidatedSyncMixin` (orphan push risk)

**A5** `IconButton` without `constraints: BoxConstraints(minWidth: 48, minHeight: 48)` (accessibility)

## Static vs Manual Review

- **Statically checked** (verify_code_quality.py): #1–6, #10–12, #15–17, #19–22, A1, A5, others
- **Manual review only**: #7, #8, #9, #13, #23 (partial), #24

## See Also

- [[infrastructure/scripts]] — verify_code_quality.py
- [[patterns/providers]] — ref.watch/read rules
- [[patterns/ui-patterns]] — navigation rules
