# Feature: community

**Purpose**: Cross-user community feed — posts, comments, likes, reports.

## Key Screens

- Community feed (public posts)
- Post detail + comments
- Create post
- Moderation report flow

## Key Providers

- `communityFeedProvider` — paginated post stream (online-first)
- Author enrichment via `CommunityProfileCache` (no per-user provider); own
  profile reads use `userProfileProvider`

## Online-First Exception

`CommunityPostRepository` is **not** offline-first — it's a cross-user public feed where server is the source of truth. It must declare its exemption in its doc block:

```dart
/// Online-first: cross-user public feed. No local Drift mirror by design.
```

See [[architecture/online-first-exemption]]

## Content Moderation

- Reports trigger `moderate-content` Edge Function
- Threshold-based auto-flag + human review queue
- Photos use `upload-community-photo` for server-side validation, moderation, and storage; the client never uploads directly to the bucket
- Picker sonrası client guard, Edge decoded-size doğrulaması ve `community-photos` bucket limiti raw 2 MiB sözleşmesinde hizalıdır

## Comment Replies (one-level, shipped 2026-07-07)

`CommunityComment.parentId` + `community_comments.parent_id` (migration
`20260707093514`, prod). UI: `replyToCommentProvider`, "→ @user" banner in
`community_comment_input.dart`, one-level indent in `community_comment_tile.dart`
when `parentId != null`. Reply-trigger grant hardened by `20260707194236`.
**One level only** — no 2+ nesting.

## Bird-Link + Mutation Tags (shipped 2026-07-08)

`community_posts.bird_id` (FK → `birds.id` ON DELETE SET NULL) + `bird_name` +
`mutation_tags TEXT[]` live via migration `20260708153615_add_bird_tags_to_posts`
(+ `idx_community_posts_bird_id` partial index). Full round-trip:
`create-community-post` validates+writes, `_feedColumns` selects, repository
parses, `BirdLinkChip`/`PostTagWrap` render. Latent until 2026-07-08 — client
had already added them to `_feedColumns`, 400'ing `fetchById`/`fetchByUser`
until the migration deployed. See [[data-layer/migrations]].

## Post-guard trigger fix — service_role vs auth.uid() (2026-07-05)

Post creation was fully broken — the `community_posts` BEFORE INSERT trigger
guarded via `public.check_community_post_allowed()` (reads `auth.uid()`), but the
edge fn inserts as **service_role** (`auth.uid()` NULL) → RAISE on every insert.
Fix (migration `20260705190654_fix_community_post_guard_trigger_row_author`,
prod): guard `NEW.user_id` via `private.check_community_post_allowed_for_user(...)`,
dropped the dead `is_admin()` bypass. DB guards (24h age, 5/hr+20/day, 1h dedup)
preserved. See [[log]].

## Post Edit (5-minute window)

Content-only edit within a **5-minute window**, enforced server-side. Migration
`20260703120000_community_post_edit_hardening.sql` adds `community_posts.edited_at`
and narrows the `authenticated` UPDATE grant to `(is_deleted, needs_review)` — post
content can't be edited via a direct client `.update()`; edits go through
`create-community-post` edge fn `mode: 'update'` (moderation re-runs, fail-closed).
Client: `CommunityPostRepository.update({postId, content})` → `updateContent` →
`updateCommunityPost`; `postEditProvider` (success → `applyPostEdit` + invalidate
`communityPostByIdProvider`), author-only "Edit" gated by `canEditPost` (UTC
5-min), `edited` badge. (`reviewed_by` was in the planned grant but that column
does NOT exist on `community_posts`; `clearReviewFlag`'s write to it is a
pre-existing latent bug.)

## Mute (soft block)

One-directional, visibility-only "soft block". Migration `20260703121000_community_mutes.sql`
adds a **separate** `public.community_mutes` table (NOT a column on `community_blocks` —
messaging block-RLS reads `community_blocks` for DM rejection, so mute must not affect DMs).
RLS SELECT is **owner-only** (`auth.uid() = user_id`) so the muted user can't learn who
muted them (unlike `community_blocks`' two-sided SELECT).

**Client** (commit `40013c0`): `CommunityEngagementRemoteSource.{fetchMutedUserIds,muteUser,
unmuteUser}` → `CommunitySocialRepository` → `mutedUsersProvider` (`MutedUsersNotifier`,
SharedPreferences `keyMutedUserIds` + server sync, optimistic+rollback — mirrors
`blockedUsersProvider`). Feed filter applies muted after blocked across all tab arms;
`visibleCommentsProvider` filters muted+blocked comment authors. Mute is a light action
(no confirm dialog, toast only) and **community-only** — NOT wired into messaging (mute
never affects DMs; that's block's job). 4 l10n keys (tr/en/de). Applied to prod +
merged to main 2026-07-03 (advisors 0 new; FORCE RLS + owner-only SELECT verified).

## Feed UI (visual redesign, 2026-07-05)

Restyle + structural pass to the `design/Topluluk.dc.html` mockup around
`AppColors` brand accents. Key behavior: **Explore is post-first** (quick
composer / section bar / scroll-to-top FAB removed; three orphaned widgets +
tests deleted, ~745 lines); **Following = feed not people list** (story strip
over follow-authored posts); **media collage** grid (1 / 2 / 3+ big-left) with
`1/N` + `+{N-3}` overlays; `_CreatePostFab` amber pill (founder-only on guides);
real author badges (verified-breeder + `Lv.X · Title` from `CommunityProfileCache`,
enrichment-only); Explore empty → welcoming `EmptyState` via
`communityShowWelcomeEmptyProvider`; app-bar profile chip (avatar + `★ Lv.X ·
Title`, `community.level_prefix`). See [[features/marketplace]] for the Pazar tab
grid.

## Tag & Mutation Discovery Feed (shipped 2026-07-10)

Tapping a tag or mutation-tag chip (`PostTagWrap` / `_TagChip`) opens a discovery
feed of every post carrying that tag. Write paths already existed — free `tags`
via the create form, `mutation_tags` derived **server-side** from a linked bird
(anti-spoof; client-sent `mutation_tags`/`bird_name` are ignored) — so this wired
the read side end to end:

- **RPC `get_community_posts_by_tag(p_tag, p_limit)`** (migration
  `20260710160000_add_community_tag_gin_indexes`, prod via MCP) does the mixed
  containment the two columns need: `tags` is **jsonb** (`?` element existence),
  `mutation_tags` is **text[]** (`@>` containment) — a single PostgREST `.or()`
  can't express both. `SECURITY INVOKER` + `search_path=''`, so RLS still
  applies. GIN indexes on both columns back the lookups.
- Chain: `CommunityPostRemoteSource.fetchByTag` (calls the RPC, not `.or()`) →
  `CommunityPostRepository.getByTag` → `communityTagFeedProvider.family` →
  `CommunityTagFeedScreen` at `/community/tag/:tag` (`AppRoutes.communityTagFeed`).
- `_TagChip` is now tappable (Material+InkWell, button semantics); it pushes the
  raw stored tag (not the `#`-prefixed label), URL-encoded.

## Audit Fixes (2026-07-10)

Cross-validated 4-lane audit (bugs / a11y / UI-UX / perf):
- **Comment visibility**: `addComment` appends the server-created comment locally
  (edge fn returns it) instead of reloading page 1 — the newest comment stayed
  off-page on long threads. Comment add/delete also invalidate
  `communityPostByIdProvider` so the detail count refreshes.
- **Block/mute staleness** + **newest re-sort**: see Current Decisions below.
- **Perf**: dropped `AutomaticKeepAliveClientMixin` from `SwipeablePostCard`,
  moved the new-post-count watch into the banner only, hoisted the URL RegExp,
  narrowed post-card rebuilds via `.select`.
- **a11y/UI**: single like haptic (was dead on tap / double on double-tap),
  unified like color to error, removed duplicate feed engagement counts, comment
  overflow menu + 48dp targets + reply connector, story labels ≥12sp, rich
  empty-comment state, guide chip opaque contrast. Swipe-to-like is additive.

## Current Decisions

- Tag/mutation discovery reads via the `get_community_posts_by_tag` RPC (not a
  PostgREST `.or()`) because `tags` (jsonb) and `mutation_tags` (text[]) need
  different containment operators. Mutation tags are authored only by linking a
  bird; the client never sends `mutation_tags` (server derives them).
- Block/mute `load()` is server-authoritative (replace local, not union).
- `communityVisiblePostsProvider` does not re-sort the newest feed — the
  notifier owns newest + pinned-first ordering.
- Community remains online-first: server/feed cache is authoritative, no Drift mirror.
- Explore is post-first: no quick composer, sort bar, story strip, or scroll-to-top FAB.
- Comments use `commentListProvider` as the single source; add/delete/like update it.
- Profile enrichment uses public-safe `display_name`, level/title, and verified breeder flags.
- Multi-image posts open the full swipeable image set from the tapped index.

## Known Deferred Work

- Hardcoded Supabase column strings in community remain a manual-review follow-up.
- Multi-device block/mute union staleness is known but not blocking current UX.
- `edited_at` optimistic clock behavior is noted for later polish.
- Global pinned-first pagination is a backend follow-up; shipped behavior pins only within the loaded feed window to preserve the `(created_at, id)` cursor.

## Pinned Posts

Client-wired: `is_pinned` parses from feed/detail rows, `CommunityPostCardBody`
shows the badge (even titleless general posts), `CommunityFeedNotifier` keeps
loaded pinned posts first, and `PostPinToggleNotifier` does optimistic pin/unpin
with rollback. Admin/founder (`isAdminProvider`) pin/unpin from the feed card menu
and detail app bar; cache invalidation is feed-wide since pin state affects order.

## Do Not Reintroduce

- Do not show both empty-state create CTA and floating create FAB together.
- Do not expose `full_name` as a public community username.
- Do not re-add the removed quick composer / section bar / people-list following tab.
- Do not drop `bird_id`/`bird_name`/`mutation_tags` from `_feedColumns` — the columns are now live and the direct-select paths (`fetchById`/`fetchByUser`) 400 without them.
- Do not add 2+ levels of comment nesting — one-level replies are the ceiling.
- Do not union local+server block/mute IDs in `load()` — server-authoritative
  replace is required for cross-device unblock/unmute to propagate.
- Do not re-add a newest re-sort in `communityVisiblePostsProvider` (wasted
  per-tap work; drops pinned-first — the notifier owns ordering).
- Do not restore `AutomaticKeepAliveClientMixin` on `SwipeablePostCard`.

## Cache

`community_profile_cache`, `community_post_cache` in `lib/data/remote/api/`

## Rules

- `.claude/rules/community.md` — online-first feed exemption, post lifecycle, comment, like, report, block/mute, RLS policy, premium gating
- `.claude/rules/edge-functions.md` — moderate-content, scan-image-safety
- `.claude/rules/security.md` — RLS on community tables

## See Also

- [[features/_features-index]]
- [[infrastructure/edge-functions]]
