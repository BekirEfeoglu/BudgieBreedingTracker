# AGENTS.md

## Project Context

BudgieBreedingTracker is a production Flutter app for budgie breeders. It is offline-first: UI reads from Drift/SQLite through Riverpod providers, while Supabase is used for auth, storage, sync, moderation, and Edge Functions.

Stack: Flutter/Dart, Riverpod 3, GoRouter 17, Drift, Supabase, Freezed, easy_localization, Sentry, RevenueCat, and `flutter_svg`.

## Communication

- Reply to the user in Turkish unless they explicitly ask for another language.
- Be direct and implementation-focused.
- If the worktree is dirty, preserve existing changes and avoid unrelated rewrites.
- Treat `AGENTS.md` as the compact agent contract. Use `CLAUDE.md` and `.claude/rules/*.md` as the detailed development rulebook when a task touches architecture, data, UI, security, CI, release flow, or domain-specific breeding/egg lifecycle behavior.
- All information is available in the `obsidian-brain` directory. Consult the wiki files inside `obsidian-brain` for comprehensive context, architecture rules, features, data layer documentation, and overall synthesis.

## Development Hygiene

- Start work by checking `git status --short --branch`; identify user changes before editing.
- If the worktree is dirty, classify changes before editing: task-owned, pre-existing/user, generated/dependency, and rule/doc. Keep buckets separate and do not stage, stash, revert, format, regenerate, or rewrite unrelated buckets without explicit request.
- Re-check `git status --short --branch` after any command that can mutate files, including code generation, Flutter/Xcode/CocoaPods builds, formatting, quality gates, and git hooks. Treat new files from those commands as a separate bucket before continuing.
- Before every commit or push, inspect `git diff --name-status` and `git diff --cached --name-status`; stage only explicit task-owned paths. A requested push must not leave task-owned changes in the working tree.
- If the user asks for a clean working tree and unrelated pre-existing/user changes remain, preserve them with a descriptive stash or separate branch and report the exact ref. Never drop or reset those changes silently.
- Keep each change focused on the requested behavior. Do not mix cleanup, rule updates, generated files, and feature logic unless the rulebook explicitly requires them together.
- Before claiming a fix, run the smallest command that proves the changed behavior and read the output.
- Do not treat skipped tests as success evidence unless the skip is intentional, documented with reason/issue, and reported in the handoff.
- After pushing to `main`, verify the exact pushed commit with `python3 scripts/check_remote_status.py`; stale runs from previous commits do not count.
- Treat Xcode Cloud separately from GitHub Actions: verify the App Store Connect status context and the matching check-run URL for the current commit.
- If a CI failure requires UI-side workflow changes, document the intended workflow state in `CLAUDE.md` and `.claude/rules/*.md` in the same change.
- End handoff with current branch/commit, dirty-state summary, commands run, and any remaining skipped or intentionally pending checks.
- Use `scripts/run_local_quality_gate.sh` before push when scripts, rules, CI, l10n, or shared quality gates changed.

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
- Do not edit generated Drift, Freezed, JSON, or Riverpod files by hand. Change the source file and regenerate.

## Breeding And Egg Rules

- Follow `.claude/rules/breeding-eggs.md` when touching breeding pairs, incubations, clutches, eggs, chicks, reminders, or hatch flows.
- Preserve the canonical lifecycle: `Bird -> BreedingPair -> Incubation -> Clutch -> Egg -> Chick`.
- Validate breeding pair birds before writes: both birds must exist, be alive, have the expected genders, and share the same species.
- Incubation species and hatch expectations must come from validated bird species and incubation helpers, never hardcoded default day counts.
- Breeding creation is a logical atomic operation: if incubation save fails after pair save, rollback the pair.
- Destructive parent flows must clean up or close related incubations/eggs and cancel related notification/calendar work before reporting success.
- Notification and calendar generation are side effects after local persistence; optional side-effect failures should surface a localized warning without undoing the primary mutation.
- Hatched eggs should auto-create at most one chick, preserving egg context (`userId`, `eggId`, `clutchId`, `hatchDate`).
- Guard create/update/delete actions against duplicate submits while notifier state is loading.

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
- Audit and explain any `skip:`, `@Skip`, or tag-based test exclusion introduced or left behind by the task.
- For breeding/egg changes, cover lifecycle transitions, rollback/error paths, duplicate submit guards, side-effect warnings, and notification cleanup.
- Use `scripts/run_breeding_egg_regression.sh` for targeted breeding/egg regression before broad `flutter test` runs.
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
dart run build_runner build
```

If codebase metrics in `CLAUDE.md` changed, run:

```bash
python3 scripts/verify_rules.py --fix
```

## Rule Maintenance

- When a feature changes counts, generated files, routes, shared widgets, migrations, Edge Functions, or quality checker coverage, update `CLAUDE.md` and `.claude/rules/*.md` together through `python3 scripts/verify_rules.py --fix`.
- When adding or changing anti-pattern scanners, update `scripts/verify_code_quality.py`, `CLAUDE.md`, `.claude/rules/ai-workflow.md`, `.claude/rules/coding-standards.md`, and `scripts/test_verify_rules.py` together.
- When changing CI, releases, Supabase deploys, or required secrets, update the matching rule file and `.github/pull_request_template.md` in the same change.
- Before pushing any GitHub Actions workflow change, validate workflow YAML locally and make sure every triggering event has at least one non-skipped job. Quote or block-scalar `run:` commands that contain `:` and add no-op guard jobs when actor/event filters would otherwise skip all jobs.
- Keep Xcode Cloud Flutter build setup in `ios/ci_scripts/ci_post_clone.sh`; it must remain executable, keep network-dependent setup retry-aware, and generate Dart build_runner outputs, `ios/Flutter/Generated.xcconfig`, and CocoaPods file lists in a clean clone instead of committing generated dependencies.
- Keep the default Xcode Cloud workflow build-only unless Apple signing prerequisites for archive/export are intentionally prepared.
- Prefer extending the existing verification scripts over adding manual-only rules that will drift.

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
