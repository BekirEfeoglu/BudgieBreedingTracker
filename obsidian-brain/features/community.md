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

## Post-guard trigger fix — service_role vs auth.uid() (2026-07-05)

Post creation was **fully broken** — `create-community-post` returned 400
`insert_failed` ("Beklenmeyen bir hata oluştu."), feed stayed empty. The
`community_posts` BEFORE INSERT trigger `internal.enforce_community_post_guards()`
guarded via `public.check_community_post_allowed()` (reads `auth.uid()`), but the
edge fn inserts as **service_role** where `auth.uid()` is NULL → `unauthorized` →
RAISE on every insert. Fix (migration
`20260705193000_fix_community_post_guard_trigger_row_author.sql`, prod-applied):
guard `NEW.user_id` via `private.check_community_post_allowed_for_user(...)`;
dropped the dead `is_admin()` bypass. DB guards (24h age, 5/hr+20/day, 1h dedup)
preserved; edge fn still pre-checks with user JWT. See [[log]].

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
(fully-muted thread no longer blank). See
`docs/superpowers/specs/2026-07-03-community-tab-design.md`.

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

- `community_avatar.dart` — shared `CommunityAvatar`: circular avatar with an
  optional brand gradient ring and initials fallback when `avatarUrl` is null;
  reused across post header, guide cards, and story strip.
- `community_pill_tabs.dart` — tabs show icon + label inline; active tab filled
  with the `AppColors.primary → primaryLight` gradient, full-radius pills,
  inactive tabs transparent.
- `community_post_actions.dart` — liked heart turns `colorScheme.error` (red),
  bookmark turns `AppColors.accent` (amber).
- FAB, `community_feed_overlays.dart`, `community_feed_guide_cards.dart`,
  `community_post_card_body/parts.dart` restyled to brand accents. l10n
  `community.guide_badge` ("Rehber", tr/en/de).

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
  author rows, wired from `profiles` via `CommunityProfileCache` (select pulls
  `level, xp_title, is_verified_breeder`; `mergeIntoRows` → `author_*`).
  `CommunityPost.authorLevel/authorTitle/authorIsVerified` (enrichment-only,
  `includeToJson: false`); `CommunityUserHeader` + guide cards render them
  (`LucideIcons.badgeCheck`). l10n `community.level_prefix`. Badges only show when
  the profile actually carries them (no fabrication).

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

### Review sweep (2026-07-05, bug + hygiene fixes)

Post-redesign audit fixes:

- **Multi-image reachability (regression fix)**: the collage viewer only opened
  the tapped cell's single image, so images 4+ in a post were unreachable.
  `CommunityImageViewer` is now a swipeable `PageView` (`imageUrls` + `initialIndex`,
  `i / N` counter, disposes its `PageController`); gallery `onOpenImage` is index-based.
  Marketplace detail viewer opens the full listing set too.
- **PII**: `CommunityProfileCache` public `username` now prefers `display_name`
  over `full_name` (real name no longer leaks as the public handle) — matches
  `getFollowedUserSummaries`.
- **Feed cache staleness**: like/bookmark/follow now call
  `CommunityPostRepository.invalidateFeedCache()` so a refetch reflects the toggle
  instead of the pre-toggle TTL snapshot.
- **Comment single-source**: dead `commentsForPostProvider` removed; add/delete/like
  update `commentListProvider` (the source `visibleCommentsProvider` reads) —
  delete/like are now in-place (`removeComment` / optimistic `applyLikeToggle`+rollback),
  add re-fetches.
- **Report "Other" text**: sheet now returns `CommunityReportResult(reason, description)`;
  the free-text description reaches `community_reports.description` (was dropped).
- **Premium photo cap**: `CommunityCreatePostScreen` enforces free 3 / premium 10
  (`_maxImages`, `effectivePremiumProvider`, `community.photo_limit_reached`).
- **a11y**: verified-breeder `badgeCheck` wrapped in `Semantics(community.verified_breeder)`
  (header + guide cards); `_AuthorMetaLine` trailing date is now `Flexible`.
- **Dead code**: `community_quick_composer` / `community_section_bar` /
  `community_following_list` + tests deleted.
- **Latent**: bird-link chip + mutation tags never populate — `community_posts` has
  no `bird_id`/`bird_name`/`mutation_tags` columns (live-verified); do NOT add them
  to `_feedColumns` (breaks the query).

## Cache

`community_profile_cache`, `community_post_cache` in `lib/data/remote/api/`

## Rules

- `.claude/rules/community.md` — online-first feed exemption, post lifecycle, comment, like, report, block/mute, RLS policy, premium gating
- `.claude/rules/edge-functions.md` — moderate-content, scan-image-safety
- `.claude/rules/security.md` — RLS on community tables

## See Also

- [[features/_features-index]]
- [[infrastructure/edge-functions]]
