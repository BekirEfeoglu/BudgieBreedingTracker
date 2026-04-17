# Community Foundation — Design Spec

**Date:** 2026-04-17
**Sub-project:** 1 of 4 (Community overhaul decomposition)
**Scope:** Structural foundation — naming contract, file split, dead-code cleanup, anti-pattern sweep. Behavior-neutral.

## Context

The `lib/features/community/` module totals ~8,600 lines across 8 screens, 23 widgets, and 9 providers. A broader overhaul (UX, performance, security, new features) is planned as Sub-projects 2–4. This spec establishes the structural foundation those sub-projects will build on.

Audit 2026-04-17 flagged `community_post_repository.dart` as an offline-first naming violation. Re-inspection shows the class is intentionally online-first (cross-user chronological feed); a mirror in local Drift would not improve UX. This spec codifies the exemption rather than forcing a rename or a pointless local mirror.

The audit also flagged `moderate-content` as an orphan edge function. Re-inspection shows it is invoked from four call sites (`community_create_providers`, `community_comment_providers`, `marketplace_form_providers`, `messaging_form_providers`). This item is **not** in scope — the audit note is stale.

## Goals

1. Codify a naming exemption for online-first `*Repository` classes that serve cross-user feeds.
2. Split two oversized files by responsibility, without behavior change.
3. Delete one dead file (3-line placeholder).
4. Run a targeted anti-pattern sweep on `lib/features/community/` and fix findings.

## Non-Goals

- Performance optimization (Sub-project 2).
- UX/UI polish (Sub-project 3).
- New features — mentions, hashtags, push integration (Sub-project 4).
- Test coverage expansion — only smoke tests for split files.
- Touching `moderate-content` wiring — already correctly invoked.
- Renaming `messaging_repository.dart` or `marketplace_listing_remote_source.dart` — covered by the new exemption, no behavior change needed.

## Design

### 1. Naming exemption taxonomy

Add a new subsection to `.claude/rules/architecture.md` under the existing "Import Rules" area:

> #### Online-first exemption
>
> A class named `*Repository` MUST be offline-first (Drift table + DAO + `SyncMetadata`) UNLESS it serves a **cross-user public feed** (chronological, non-per-user, server is the source of truth by design). Exempt classes MUST declare the exemption in the first doc block:
>
> ```dart
> /// Online-first: cross-user public feed; no local Drift mirror by design.
> ```
>
> Currently exempt:
> - `CommunityPostRepository` — public community feed
> - `MessagingRepository` — direct messages (live server state)
>
> Online-only classes that are NOT cross-user feeds (single-user remote data) MUST use `*RemoteService` or `*OnlineSource` naming.

Update `.claude/rules/data-layer.md` "Offline-First Classification" block to cross-reference the exemption and remove `messaging_repository.dart` and `community_post_repository.dart` from the "needs rename" list.

Docstring normalization:
- `lib/data/repositories/community_post_repository.dart` — first line becomes the exemption declaration above.
- `lib/data/repositories/messaging_repository.dart` — same.

No call-site changes. No class-name changes.

### 2. File split (by responsibility)

#### `community_post_card.dart` (394 → ~150)

Current responsibilities: header orchestration, body layout, media rendering, markdown wiring, tap/long-press handling, action bar composition.

Split:
- `community_post_card.dart` — composition root. Pulls together header, body, actions. Accepts the post model + callbacks. Target ~150 lines.
- `community_post_card_parts.dart` (existing, 228 lines) — unchanged. Already holds header and meta pieces.
- `community_post_card_body.dart` (new) — body + media gallery + markdown + tap/long-press. Target ~180 lines.

Action bar (`community_post_actions.dart`, 228 lines) is already a separate file and stays.

#### `community_report_sheet.dart` (302 → ~200)

Current responsibilities: reason enum list, enum→l10n key mapping, sheet UI, form state, submit wiring.

Split:
- `community_report_sheet.dart` — UI + form + submit. Target ~200 lines.
- `community_report_reasons.dart` (new, same directory) — reason enum values + `reasonLabelKey(reason)` mapping helper. Target ~60 lines.

#### Not split

- `community_feed_items.dart` (298) — single coherent responsibility (state dispatcher). Leave as-is.
- `community_post_markdown.dart` (293), `community_section_bar.dart` (270), `community_post_detail_screen.dart`, `community_user_header.dart` — all below threshold or single-responsibility.

### 3. Dead-file cleanup

Delete `lib/features/community/providers/community_moderation_providers.dart` (3-line placeholder).

Procedure:
1. `grep -rn "community_moderation_providers" lib/ test/` → confirm no imports.
2. If any reference exists, either delete the importer if it is also dead, or re-point to the correct provider.
3. `git rm` the file.

### 4. Anti-pattern sweep (community-scoped)

Run the quality scanner, filter to `lib/features/community/`, fix findings one class at a time.

```bash
python3 scripts/verify_code_quality.py 2>&1 | grep "lib/features/community/"
```

(If the script supports a path argument, use it; otherwise filter output.)

Expected categories from the 24 anti-patterns list:
- `withOpacity()` → `withValues(alpha:)`
- `ref.watch()` in callbacks → `ref.read()`
- Hardcoded user-visible text → `.tr()` (no new keys expected — only `.tr()` wrappers on existing strings if any are hardcoded)
- `context.go()` forward navigation → `context.push()`
- Bare `catch (e)` without logging → `AppLogger.error(...)`
- `setState` after async without `mounted` check
- Hardcoded colors/spacing → `Theme.of(context)` / `AppSpacing`
- Missing `controller.dispose()`

Each anti-pattern category = one focused commit. If a fix requires a new l10n key, out-of-scope — flag for Sub-project 3 (UX polish).

### 5. Verification

Quality gates (run before each commit and before PR):

```bash
flutter analyze --no-fatal-infos
python3 scripts/verify_code_quality.py
python3 scripts/check_l10n_sync.py
flutter test test/features/community/
```

Acceptance criteria:
- 0 analyzer errors.
- 0 anti-pattern violations in `lib/features/community/`.
- All existing community tests pass.
- `community_post_card.dart` < 200 lines.
- `community_report_sheet.dart` < 220 lines.
- No file in `lib/features/community/` > 300 lines after split (exception: `community_feed_items.dart` at 298, single-responsibility, documented).
- `CommunityPostRepository` and `MessagingRepository` docstrings contain the exemption declaration.
- `community_moderation_providers.dart` deleted with no import breakage.

### 6. Commit sequence (suggested)

1. `docs(rules): add online-first exemption taxonomy` — architecture.md + data-layer.md edits.
2. `docs(data): normalize community/messaging repo docstrings` — doc blocks only.
3. `refactor(community): split community_post_card into composition + body` — new `community_post_card_body.dart`.
4. `refactor(community): extract reason list from report sheet` — new `community_report_reasons.dart`.
5. `chore(community): remove dead moderation providers placeholder`.
6. `chore(community): anti-pattern sweep — <category>` — one commit per category with findings.

## Risks & Rollback

- **Risk:** Split accidentally changes behavior (callback wiring, key preservation for AnimatedSwitcher/list keys).
  **Mitigation:** Move widgets verbatim; keep `Key` propagation; run existing tests after each split commit.
- **Risk:** Anti-pattern fix in a `ref.watch` → `ref.read` change introduces a stale-data bug.
  **Mitigation:** Fix one callback at a time; manually smoke-test affected screen in simulator after each.
- **Rollback:** Every commit isolated. Revert individual commits; no data migrations, no RLS changes, no schema touches.

## Effort Estimate

- Architecture docs + docstrings: ~30 min
- `community_post_card` split: ~1 hour
- `community_report_sheet` split: ~45 min
- Dead file removal: ~10 min
- Anti-pattern sweep: ~1.5–3 hours depending on finding count
- Verification + manual smoke: ~30 min

**Total: 4–6 hours, ~8–12 commits.**

## Open Questions

None.

## Out-of-Spec Follow-ups

Tracked for Sub-projects 2–4, not this spec:
- Feed rebuild scope narrowing via `.select()` (Sub-project 2).
- Block/mute surfacing UX (Sub-project 2).
- Moderation admin review queue (Sub-project 2).
- `@mention` + `#hashtag` + trending (Sub-project 4).
- Push integration for comment/like/mention (Sub-project 4).
- Test coverage matrix for community/ (own sub-project or Sub-project 2 extension).
