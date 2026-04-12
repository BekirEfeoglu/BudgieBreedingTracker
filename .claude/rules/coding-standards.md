# Coding Standards

## Naming
- `snake_case`: constants, file names
- `camelCase`: variables, functions, parameters
- `PascalCase`: classes, enums, typedefs
- Private fields: leading underscore `_fieldName`

## Freezed Models
- ALWAYS add `const Model._()` private constructor
- Use `@JsonKey(unknownEnumValue: X.unknown)` on every enum field
- All `switch` on server-side enums must handle `unknown` case

## File Organization
- Features: `lib/features/<name>/screens/`, `widgets/`, `providers/`
- Models: `lib/data/models/`
- Enums: `lib/core/enums/` (15 files)
- Tests mirror lib/ structure in `test/`

## Icons
- Domain icons: `AppIcon(AppIcons.x)` with SVG (84 constants in `app_icons.dart`)
- Generic UI icons: `LucideIcons.x` (settings, navigation, generic actions only)
- Never use `Icon(Icons.x)` for domain concepts
- Shared widgets accept `Widget icon` param, not `IconData`

## 24 Critical Anti-Patterns
See CLAUDE.md § "Critical Anti-Patterns" — enforced by `verify_code_quality.py` (21 checkers).

Key rules:
1. `withOpacity()` → `withValues(alpha:)`
2. `setState` after async → check `mounted` first
3. `ref.watch()` in callbacks → `ref.read()`
4. Hardcoded text → `.tr()` (3 languages)
5. `print()` → `AppLogger`
6. `context.go()` forward nav → `context.push()`
7. Hardcoded colors/spacing → `Theme.of(context)` / `AppSpacing`
8. Always `dispose()` controllers in `ConsumerStatefulWidget`
9. Bare `catch(e)` → `AppLogger.error`
10. Critical errors → `Sentry.captureException`
