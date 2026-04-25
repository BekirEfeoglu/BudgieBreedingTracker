# AGENTS.md

## Project Context

BudgieBreedingTracker is a production Flutter app for budgie breeders. It is offline-first: UI reads from Drift/SQLite through Riverpod providers, while Supabase is used for auth, storage, sync, moderation, and Edge Functions.

Stack: Flutter/Dart, Riverpod 3, GoRouter 17, Drift, Supabase, Freezed, easy_localization, Sentry, RevenueCat, and `flutter_svg`.

## Communication

- Reply to the user in Turkish unless they explicitly ask for another language.
- Be direct and implementation-focused.
- If the worktree is dirty, preserve existing changes and avoid unrelated rewrites.

## Architecture Rules

- Respect the layer order: `core/`, `data/`, `domain/`, `features/`, `router/`.
- `core/` must stay shared and must not import from `data/` or `features/`.
- UI and feature code must not import `data/remote/` directly. Use repositories/providers.
- Features must not import other feature modules. Move shared widgets to `lib/core/widgets/`, shared logic to `lib/domain/services/`, and shared state to a shared provider location.
- Repositories are offline-first by default. A `*Repository` that is online-first must document why in its class doc comment.
- Admin-only exceptions must remain scoped to `lib/features/admin/`.

## Data Rules

- Drift is the local source of truth for app UI.
- Writes should go local first, then sync through repository/sync metadata flow.
- Use Drift DAOs, mappers, and model extensions instead of ad hoc map conversion.
- Use `.equalsValue()` for enum columns in Drift queries.
- Import Drift table files directly in DAOs instead of relying on broad database imports.
- Do not send `created_at` or `updated_at` to Supabase. Use the existing `.toSupabase()` style.
- Use `SupabaseConstants` for table, bucket, and column names.

## Riverpod Rules

- Use `ref.watch()` only while building reactive UI or providers.
- Use `ref.read()` inside callbacks, submit handlers, navigation handlers, and side effects.
- Keep provider chains narrow: raw streams/data first, filters/computed state separately.
- Dispose `ProviderContainer` in tests with `addTearDown(container.dispose)`.
- Guard async state changes against races and disposed widgets.

## UI Rules

- Prefer `ConsumerWidget`. Use `ConsumerStatefulWidget` when controllers, focus nodes, timers, scroll controllers, or animations are needed.
- Always dispose controllers and focus nodes.
- Check `mounted` after awaited calls before using `context` or calling `setState`.
- Handle `AsyncValue` with loading, error, and data states.
- Use shared widgets from `lib/core/widgets/` before creating new equivalents.
- Use `Theme.of(context)`, text theme, and `AppSpacing`; avoid hardcoded colors and spacing unless an existing exception applies.
- Use `.withValues(alpha: x)`, never `withOpacity()`.
- Use `AppIcon(AppIcons.x)` for domain icons and SVG assets. Reserve `LucideIcons` for generic UI actions only.
- Shared widgets should accept `Widget icon`, not `IconData`.

## Navigation Rules

- Add route names in `lib/router/route_names.dart`.
- Register routes in the appropriate `lib/router/routes/*_routes.dart` file.
- Place specific routes before parameterized routes, for example `form` before `:id`.
- Use `context.push()` for forward navigation and `context.pop()` for back navigation.
- Do not skip auth, admin, or premium guards.
- Edit flows should use the existing query parameter pattern, such as `?editId=...`.

## Localization Rules

- All user-facing text must use `easy_localization` keys and `.tr()`.
- Turkish (`assets/translations/tr.json`) is the master language.
- Add or update the same key in `tr.json`, `en.json`, and `de.json` together.
- Run `python3 scripts/check_l10n_sync.py` after localization changes.

## Model And Enum Rules

- Freezed models must include `const Model._();`.
- Enum fields deserialized from remote/server data must use `@JsonKey(unknownEnumValue: SomeEnum.unknown)`.
- Switches over server-side enums must handle `unknown`.
- Prefer typed parsing and explicit validation at remote boundaries.

## Error Handling And Logging

- Do not use `print()`. Use `AppLogger`.
- Do not swallow `catch (e)` blocks. Log meaningful failures.
- Critical failures should be reported to Sentry.
- User-facing errors must be localized and actionable.
- Never log passwords, tokens, secrets, or sensitive personal data.

## Security Rules

- Never hardcode Supabase credentials, RevenueCat keys, OAuth IDs, tokens, or service-role keys.
- Never commit `.env`, credential files, or generated secret material.
- RLS belongs server-side in Supabase migrations/policies, not client code.
- Client-side checks are not authorization. Protected flows still require server/RLS enforcement.
- Use secure storage for sensitive session data.

## Testing Rules

- Tests should mirror the production path under `test/`.
- Add or update tests for changed behavior, especially providers, repositories, services, route guards, and forms.
- Use existing helpers from `test/helpers/` before adding new test infrastructure.
- Prefer behavior assertions over brittle implementation details.
- Golden tests belong under `test/golden/` and should be tagged `golden`.

## Quality Gates

Run the smallest relevant checks while iterating. Before handing off substantial changes, prefer:

```bash
flutter analyze --no-fatal-infos
python3 scripts/verify_code_quality.py
python3 scripts/check_l10n_sync.py
flutter test
```

Run code generation after touching Freezed models, Drift tables, JSON models, or Riverpod generators:

```bash
dart run build_runner build --delete-conflicting-outputs
```

If codebase metrics in `CLAUDE.md` changed, run:

```bash
python3 scripts/verify_rules.py --fix
```

## Common Anti-Patterns To Avoid

- `withOpacity()` instead of `withValues(alpha:)`
- `ref.watch()` inside callbacks
- `context.go()` for normal forward navigation
- hardcoded UI text
- hardcoded Supabase table or column names
- direct Supabase access from feature/UI code
- feature-to-feature imports
- missing controller disposal
- missing `mounted` check after async UI work
- `Icon(Icons.x)` for domain icons
- bare `catch` without logging
- unguarded route access for protected screens

