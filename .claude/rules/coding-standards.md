# Coding Standards

## Naming
| Convention | Usage |
|-----------|-------|
| `snake_case` | File names, constants, l10n keys |
| `camelCase` | Variables, functions, parameters |
| `PascalCase` | Classes, enums, typedefs, extensions |
| `_prefixed` | Private fields, methods |

## Freezed Models
```dart
@freezed
class Bird with _$Bird {
  const Bird._();  // ALWAYS add private constructor

  const factory Bird({
    required String id,
    required String name,
    @JsonKey(unknownEnumValue: BirdGender.unknown)  // ALWAYS on enum fields
    required BirdGender gender,
  }) = _Bird;

  factory Bird.fromJson(Map<String, dynamic> json) => _$BirdFromJson(json);
}
```
- All `switch` on server-side enums must handle `unknown` case

## File Organization
- Features: `lib/features/<name>/screens/`, `widgets/`, `providers/`
- Models: `lib/data/models/`
- Enums: `lib/core/enums/` (15 files)
- Tests mirror `lib/` structure in `test/`
- One public class per file (private helpers OK in same file)
- Max ~300 lines per file — split if growing beyond

## Icons
- Domain icons: `AppIcon(AppIcons.x)` with SVG (89 constants in `app_icons.dart`)
- Generic UI icons: `LucideIcons.x` (settings, navigation, generic actions only)
- Never use `Icon(Icons.x)` for domain concepts
- Shared widgets accept `Widget icon` param, not `IconData`

## Extensions
- Use extensions for model transformations: `.toSupabase()`, `.toLocal()`
- Keep extensions in the same file as the model or in a dedicated `_extensions.dart`
- Name extensions descriptively: `extension BirdSupabaseX on Bird`

## Async/Await
```dart
// Prefer async/await over .then()
final birds = await repository.getAll();

// Use Future.wait for parallel operations
final [birds, eggs] = await Future.wait([
  birdRepo.getAll(),
  eggRepo.getAll(),
]);
```

## 24 Critical Anti-Patterns
Full list with explanations: CLAUDE.md § "Critical Anti-Patterns (24 rules)"
Enforced by: `verify_code_quality.py` — 27 checker kategorisi; 19/24 CLAUDE.md kuralı + 9 ek dokümante scanner.
Statik tarayıcı dışı (manuel review): #8, #9, #13, #23 (kısmi), #24.

**Top 10 most common:**
1. `withOpacity()` -> `withValues(alpha:)` — Flutter deprecation
2. `setState` after async -> check `mounted` first — disposed widget crash
3. `ref.watch()` in callbacks -> `ref.read()` — unintended rebuilds
4. Hardcoded text -> `.tr()` — 3 languages supported
5. `print()` -> `AppLogger` — structured logging
6. `context.go()` forward nav -> `context.push()` — stack replacement
7. Hardcoded colors/spacing -> `Theme.of(context)` / `AppSpacing` — theming + dark mode
8. Missing `controller.dispose()` -> ALWAYS dispose — memory leaks
9. Bare `catch(e)` -> `AppLogger.error` — silent failures
10. Critical errors without Sentry -> `Sentry.captureException` — observability

**Audit-flagged ek kurallar (CLAUDE.md numarali liste disinda):**
- `ProviderContainer(...)` -> `addTearDown(container.dispose)` (test-stability.md, 2026-04-17 audit, 644+ leak)
- `*Repository` adi -> offline-first OR `*RemoteService`/`*OnlineSource` rename (data-layer.md)
- `client.insert()` -> `client.upsert()` — idempotent retry/sync replay
- FK parent'li syncable repo -> `ValidatedSyncMixin` (orphan push engelle)
- `IconButton` -> `constraints: BoxConstraints(minWidth: 48, minHeight: 48)` (a11y, accessibility.md)
- Feature-to-feature import veya feature katmanından `data/remote/` import -> `shared/`, `data/providers`, repository veya domain servis sınırı kullan

> **Related**: ai-workflow.md (prohibited actions), ui-patterns.md (widget patterns), data-layer.md (Drift conventions), accessibility.md (a11y), observability.md (logging + Sentry)
