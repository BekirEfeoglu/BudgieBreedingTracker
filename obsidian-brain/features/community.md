# Feature: community

**Purpose**: Cross-user community feed — posts, comments, likes, reports.

## Key Screens

- Community feed (public posts)
- Post detail + comments
- Create post
- Moderation report flow

## Key Providers

- `communityFeedProvider` — paginated post stream (online-first)
- `communityProfileProvider(userId)`

## Online-First Exception

`CommunityPostRepository` is **not** offline-first — it's a cross-user public feed where server is the source of truth. It must declare its exemption in its doc block:

```dart
/// Online-first: cross-user public feed. No local Drift mirror by design.
```

See [[architecture/online-first-exemption]]

## Content Moderation

- Reports trigger `moderate-content` Edge Function
- Threshold-based auto-flag + human review queue
- Photos scanned by `scan-image-safety` Edge Function before upload

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
content can no longer be edited via a direct client `.update()`; edits go through
`create-community-post` edge fn `mode: 'update'` (moderation re-runs, fail-closed).
(`reviewed_by` was in the planned grant but that column does NOT exist on
`community_posts` — dropped; `clearReviewFlag`'s write to it is a pre-existing latent
bug.) UI shows an `edited` badge; the edit action appears only
on the author's own post inside the window. Applied to prod + merged to main
2026-07-03 (advisors 0 new). Follow-up polish (`fix/community-followups`): edit
sheet uses shared `showAppBottomSheet` (safe-area), the specific `edit_window_expired`
message surfaces, and the comment empty-state fires on `visibleComments.isEmpty`
(fully-muted thread no longer blank). Design decisions are retained in this
community brain page and [[log]].

**Client** (commits `68d6a57` data, `d31eef5` UI): `CommunityPost.editedAt` +
`CommunityPostX.isEdited`; `CommunityPostRepository.update({postId, content})` →
`updateContent` → `EdgeFunctionClient.updateCommunityPost` (`mode:'update'`).
`community_post_edit_sheet.dart` + `postEditProvider` (success → `applyPostEdit` +
invalidate `communityPostByIdProvider`; failure logs+Sentry, feed intact),
author-only "Edit" gated by `canEditPost` (UTC 5-min), `edited` badge. 6 l10n keys.

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

## Feed UI (visual redesign)

Feed restyle (2026-07-05, behavior unchanged) around `AppColors` brand accents:
shared `CommunityAvatar` (gradient ring + initials fallback), icon+label pill
tabs with active-tab gradient (`community_pill_tabs.dart`), liked heart →
`colorScheme.error` / bookmark → `AppColors.accent` (`community_post_actions.dart`),
and brand-accent restyle of the FAB, feed overlays, guide cards, and post-card
body/parts. l10n `community.guide_badge` ("Rehber", tr/en/de).

### Layout alignment to `design/Topluluk.dc.html` (2026-07-05, behavior changed)

Structural pass matching the design mockup — this one changes behavior:

- **Explore is post-first**: the quick composer, the sort/section bar and the
  scroll-to-top mini FAB were removed from the feed (`community_feed_items.dart` /
  `community_feed_list.dart`). The story strip no longer shows on Explore. The
  three now-orphaned widgets (`community_quick_composer.dart`,
  `community_section_bar.dart`, `community_following_list.dart`) + their tests
  were **deleted** in the 2026-07-05 review sweep (~745 lines dead code).
- **Following = feed, not people list**: `CommunityFeedList` no longer
  short-circuits the `following` tab to a people list. It now renders the story
  strip (`CommunityStoryStrip.fromPosts`) over the follow-authored post feed via
  `communityVisiblePostsProvider(following)` (posts where `isFollowingAuthor`).
- **Media collage**: `community_media_gallery.dart` rewritten from a `PageView`
  carousel to a `StatelessWidget` collage grid — 1 full cell / 2 side-by-side /
  3+ big-left (2fr) + stacked-right with a `1 / N` counter chip and a `+{N-3}`
  overlay. Double-tap-to-like and tap-to-open preserved.
- **Bird chip**: cyan (`tertiary`) variant on question posts, amber elsewhere
  (`community_post_card_parts.dart`). Text/guide cards get a hairline separator
  above the action bar.
- **Create FAB**: `_CreatePostFab` in `community_screen.dart` — amber-gradient
  pill with a plus glyph (guide glyph on the guides tab); the founder-only rule
  on the guides tab is preserved.
- **Author badges (real data)**: verified-breeder + `Lv.X · Title` badge on
  author rows, wired from `profiles` via `CommunityProfileCache` (`level,
  xp_title, is_verified_breeder` → `author_*`). `CommunityPost.authorLevel/
  authorTitle/authorIsVerified` (enrichment-only, `includeToJson: false`),
  rendered by `CommunityUserHeader` + guide cards. Shown only when the profile
  actually carries them (no fabrication).

- **Explore empty state**: an empty Explore feed now shows the welcoming
  `EmptyState` ("Henüz gönderi yok" + create CTA) instead of the search-oriented
  `FilteredFeedEmptyState` ("Eşleşen gönderi yok / try different search"), since
  Explore has no visible search/filter UI. The welcome-empty condition lives in
  `communityShowWelcomeEmptyProvider` (`community_feed_providers_filters.dart`) —
  single source of truth: `!isLoading && (posts.isEmpty || (explore &&
  visiblePosts.isEmpty))`. `_buildFeedBody` watches it; Takip/Rehberler/Pazar
  keep the filtered state. `CommunityScreen` also suppresses `_CreatePostFab`
  while it's true (explore/following only) so the empty state's own centered CTA
  isn't duplicated by the FAB — no more two "Gönderi Oluştur" buttons on an empty
  feed; FAB returns once the feed has content.

- **App-bar profile chip**: `CommunityAppBar` shows the current user's avatar in
  a blue→amber gradient ring (`_ProfileAvatar`) and an amber `★ Lv.X · Title`
  badge (`_LevelBadge`) under "Topluluk". The level falls back to **Lv.1** with
  `LevelCalculator.titleForLevel(1)` when `userLevelProvider` returns null (user
  with no `user_levels` row) so the badge always renders, matching the design;
  the hardcoded `'Lv.'` was replaced with `community.level_prefix`.

See [[features/marketplace]] for the embedded Pazar tab's 2-column grid change.

## Current Decisions

- Community remains online-first: server/feed cache is authoritative, no Drift mirror.
- Explore is post-first: no quick composer, sort bar, story strip, or scroll-to-top FAB.
- Comments use `commentListProvider` as the single source; add/delete/like update it.
- Profile enrichment uses public-safe `display_name`, level/title, and verified breeder flags.
- Multi-image posts open the full swipeable image set from the tapped index.

## Known Deferred Work

- Hardcoded Supabase column strings in community remain a manual-review follow-up.
- Multi-device block/mute union staleness is known but not blocking current UX.
- `edited_at` optimistic clock behavior is noted for later polish.
- Pinned posts (`is_pinned`) column + select exist but no client set/display/premium gate yet.

## Do Not Reintroduce

- Do not show both empty-state create CTA and floating create FAB together.
- Do not expose `full_name` as a public community username.
- Do not re-add the removed quick composer / section bar / people-list following tab.
- Do not drop `bird_id`/`bird_name`/`mutation_tags` from `_feedColumns` — the columns are now live and the direct-select paths (`fetchById`/`fetchByUser`) 400 without them.
- Do not add 2+ levels of comment nesting — one-level replies are the ceiling.

## Cache

`community_profile_cache`, `community_post_cache` in `lib/data/remote/api/`

## Rules

- `.claude/rules/community.md` — online-first feed exemption, post lifecycle, comment, like, report, block/mute, RLS policy, premium gating
- `.claude/rules/edge-functions.md` — moderate-content, scan-image-safety
- `.claude/rules/security.md` — RLS on community tables

## See Also

- [[features/_features-index]]
- [[infrastructure/edge-functions]]
