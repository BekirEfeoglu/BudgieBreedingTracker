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

## Post Edit (in progress — branch `feature/community-tab-faz1`)

Content-only edit within a **5-minute window**, enforced server-side. Migration
`20260703120000_community_post_edit_hardening.sql` adds `community_posts.edited_at`
and narrows the `authenticated` UPDATE grant to `(is_deleted, needs_review,
reviewed_by)` — post content can no longer be edited via a direct client `.update()`;
edits go through `create-community-post` edge fn `mode: 'update'` (moderation re-runs,
fail-closed). UI shows an `edited` badge; the edit action appears only on the author's
own post inside the window. Not yet merged/applied to prod. See
`docs/superpowers/specs/2026-07-03-community-tab-design.md`.

**Client data contract** (commit `68d6a57`): `CommunityPost.editedAt` (`DateTime?`) +
`CommunityPostX.isEdited`; edit flows `CommunityPostRepository.update({postId, content})`
→ `CommunityPostRemoteSource.updateContent` → `EdgeFunctionClient.updateCommunityPost`
(`mode: 'update'`). `_parsePost` reads `edited_at`; `update` invalidates the post cache.

**UI** (commit `d31eef5`): `community_post_edit_sheet.dart` (content-only edit sheet),
`postEditProvider` (`editPost → bool`; success calls `CommunityFeedNotifier.applyPostEdit`
+ invalidates `communityPostByIdProvider`, failure logs+Sentry and leaves feed intact),
an author-only "Edit" menu item gated by `canEditPost` (UTC 5-min window), and an
`edited` badge on the post header. 6 l10n keys (tr/en/de).

## Mute (in progress — branch `feature/community-tab-faz1`)

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
never affects DMs; that's block's job). 4 l10n keys (tr/en/de). Not yet applied to prod.

## Cache

`community_profile_cache`, `community_post_cache` in `lib/data/remote/api/`

## Rules

- `.claude/rules/community.md` — online-first feed exemption, post lifecycle, comment, like, report, block/mute, RLS policy, premium gating
- `.claude/rules/edge-functions.md` — moderate-content, scan-image-safety
- `.claude/rules/security.md` — RLS on community tables

## See Also

- [[features/_features-index]]
- [[infrastructure/edge-functions]]
