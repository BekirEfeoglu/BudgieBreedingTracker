# New Feature Checklist

Use this checklist before implementation, not only before commit. Check only the
rows that apply, but record why a security-, data-, sync-, or lifecycle-related
row is not applicable when that decision is not obvious from the diff.

## 1. Classify The Change First

- [ ] Name the user-visible behavior and the single source of truth.
- [ ] Classify the change: entity/data, domain behavior, UI-only, route/guard,
  remote/Edge Function, migration, notification/calendar, premium/limit,
  release/CI, or documentation/rule.
- [ ] Read the owning `.claude/rules/*.md` and matching `obsidian-brain` page
  before editing. Code proves current behavior; the rule owns policy.
- [ ] Trace the production path end to end: UI -> provider -> service/repository
  -> DAO/remote -> sync/side effects.
- [ ] Identify invariants that must remain true, failure modes, rollback boundary,
  optional side effects, and concurrency/duplicate-submit behavior.
- [ ] Decide whether the feature is offline-first. An online-first exception must
  be explicit and documented on the owning service/repository.
- [ ] Identify authorization enforcement. Client guards are UX only; RLS, JWT
  claims, or server validation must protect remote data/actions.
- [ ] Define the smallest test that proves each changed behavior before coding.

## 2. Change Surface Map

| Surface touched | Required companion work |
|---|---|
| Model / enum / Drift table | Mapper, DAO, migration, repository, generated files, migration tests |
| Repository / sync | Local-first write, `SyncMetadata`, remote validation, conflict/idempotency tests |
| Route / protected screen | `AppRoutes`, route registration/order, auth/admin/premium guard tests |
| User-facing text | TR master + EN + DE keys, interpolation/plural checks, l10n sync |
| Notification / calendar | Stable IDs, timezone/deeplink, cancellation and partial-failure tests |
| Remote write / Edge Function | Input validation, JWT/RLS authority, idempotency, safe errors, Deno tests |
| Premium / free-tier limit | `effectivePremiumProvider`, server authority, grace-period and boundary tests |
| Image / attachment | Size/type validation, moderation where needed, bucket constants, cleanup |
| Behavior or architecture contract | Owning rule + wiki page + `obsidian-brain/log.md` in the same change |
| Counted inventory | Run `python3 scripts/verify_rules.py --fix`; never hand-edit managed counts |

## 3. Full-Stack Entity Addition

```text
1.  Model (Freezed)      -> lib/data/models/
2.  Enum (if needed)     -> lib/core/enums/
3.  Table (Drift)        -> lib/data/local/database/tables/
4.  Converter            -> lib/data/local/database/converters/
5.  Mapper               -> lib/data/local/database/mappers/
6.  DAO                  -> lib/data/local/database/daos/
7.  DB Registration      -> app_database.dart (table + DAO + schema migration)
8.  Remote Migration     -> supabase/migrations/ (table/index/RLS when applicable)
9.  Remote Source        -> lib/data/remote/api/
10. Repository           -> lib/data/repositories/
11. Repository Provider  -> lib/data/repositories/repository_providers.dart
12. Sync Registration    -> SyncMetadata + coordinator/registry when syncable
13. Feature Providers    -> lib/features/<name>/providers/
14. Domain Service       -> lib/domain/services/ when orchestration crosses writes/side effects
15. Screens              -> lib/features/<name>/screens/
16. Widgets              -> lib/features/<name>/widgets/
17. Routes + Guards      -> lib/router/routes/ + lib/router/guards/
18. L10n Keys            -> assets/translations/{tr,en,de}.json
19. Tests                -> test/ (mirror production path)
20. Docs                 -> owning rule + obsidian-brain feature/domain page
```

### Critical Reminders Per Step

- **Model/enum**: add `const Model._()` and
  `@JsonKey(unknownEnumValue: SomeEnum.unknown)` for remote enum fields.
- **Table/DAO**: import the table directly; use `.equalsValue()` for enum
  columns; add indexes for real filter/order/FK access paths.
- **Migration**: bump Drift `schemaVersion`, cover fresh install and upgrade,
  and never rewrite an already-applied Supabase migration.
- **Remote boundary**: use `SupabaseConstants`, typed parsing, `.toSupabase()`,
  and server-side ownership/authorization. Do not trust body `user_id`.
- **Repository**: local persistence commits before sync for offline-first data;
  use stable client-generated IDs and idempotent remote upserts.
- **Provider/service**: guard duplicate submits, disposed/racing async work, and
  distinguish primary failure from optional side-effect warning.
- **UI**: implement loading, empty, error, offline, validation, accessibility,
  and narrow provider watching; reuse shared widgets.
- **Route**: specific paths precede `:id`; forward navigation uses
  `context.push()`; edit uses the existing query-parameter pattern.
- **L10n**: add the Turkish master and EN/DE translations together; verify
  placeholders and text overflow, not only key parity.
- **Tests/docs**: assert behavior and failure boundaries, audit skips, update the
  owning wiki/rule, and regenerate managed metrics.

## 4. Non-Entity Feature

```text
1. Contract + owner     -> owning rule/wiki and source of truth
2. Provider/service     -> state, orchestration, race and error boundaries
3. Screens/widgets      -> all AsyncValue and accessibility states
4. Routes/guards        -> if navigable or protected
5. L10n                 -> TR/EN/DE
6. Observability        -> actionable logs/Sentry without PII
7. Tests                -> behavior + error/empty/offline paths
8. Docs                 -> behavior and known limitations
```

Do not create a feature module for a reusable concern. Shared UI belongs in
`core/widgets`, shared business logic in `domain/services`, and shared state in
the established shared provider/data boundary.

## 5. Shared Widget Addition

- [ ] Confirm no existing widget already expresses the state/action.
- [ ] Place it under `lib/core/widgets/` in the correct subdirectory.
- [ ] Accept `Widget icon`, not `IconData`, when the caller supplies an icon.
- [ ] Use theme/text theme/`AppSpacing`; avoid feature imports.
- [ ] Support text scaling, semantics, keyboard focus, 48dp targets, loading,
  disabled, and error states that apply.
- [ ] Add focused widget tests; add a golden only when visual regression value
  exceeds maintenance cost.

## 6. Breeding / Egg / Chick Trigger

Any change touching breeding pairs, incubations, clutches, eggs, chicks,
species incubation math, hatch flows, or their notification/calendar cleanup
must use `.claude/rules/breeding-eggs.md` as an additional checklist. The local
quality gate automatically runs `scripts/run_breeding_egg_regression.sh` when
those paths, their scheduler/calendar integration, or that rule change. The
focused manifest covers the Drift transaction, notifiers, notification IDs,
scheduler/rescheduler/toggles, and calendar generator/provider, and rejects
skipped/excluded tests; this does not replace the rule's manual lifecycle review.

## 7. Verification By Changed Surface

Run the smallest proof while iterating, then the canonical gate before handoff.

| Change | Minimum proof |
|---|---|
| Any implementation | Focused unit/provider/widget test for changed behavior |
| Freezed/Drift/JSON/Riverpod generator input | `dart run build_runner build --delete-conflicting-outputs` |
| L10n | `python3 scripts/check_l10n_sync.py --strict-keys` |
| Rule/docs/scripts/CI | `scripts/run_local_quality_gate.sh` |
| Breeding/egg lifecycle | `scripts/run_breeding_egg_regression.sh` (transaction + notifier + notification/calendar boundaries; also path-triggered by local gate) |
| Migration | Migration tests + `python3 scripts/verify_migration_drift.py` |
| Edge Function | Focused `deno test` + auth/error-path review |
| Broad Dart change | `flutter analyze --no-fatal-infos` + relevant `flutter test` scope |

## 8. Definition Of Done

- [ ] The production path, not a mock-only shortcut, is covered.
- [ ] Primary failure, partial side-effect failure, retry, and duplicate action
  behavior are explicit where applicable.
- [ ] Authorization, privacy, offline/sync, accessibility, localization, and
  observability decisions are implemented or clearly marked not applicable.
- [ ] No skipped test was introduced or inherited silently.
- [ ] Generated and documentation surfaces are synchronized.
- [ ] `scripts/run_local_quality_gate.sh` passes and the final dirty-state
  ledger contains only intended task files.
- [ ] Handoff reports commands run, skipped/manual checks, branch/commit, and
  remaining dirty state.

> **Related**: data-layer.md (offline-first and sync), security.md (authority),
> accessibility.md (interaction contract), testing.md (coverage),
> breeding-eggs.md (domain lifecycle), ai-workflow.md (quality gates and handoff)
