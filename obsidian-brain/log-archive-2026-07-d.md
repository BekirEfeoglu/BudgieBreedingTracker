# Change Log Archive - 2026-07 (part 4, 07-03 plan execution)

Back to [[log]].

## [2026-07-03] feat (branch) | community post edit UI (sheet, menu, badge)

Branch `feature/community-tab-faz1` (commit `d31eef5`). User-facing edit: content-only
bottom sheet (`community_post_edit_sheet.dart`), `postEditProvider` (`editPost → bool`;
success → `applyPostEdit` + `communityPostByIdProvider` invalidate, failure →
`AppLogger.error` + Sentry, feed left intact), author-only "Edit" menu item gated by
`canEditPost` (UTC now−createdAt < 5 min), `edited` badge on the header, 6 l10n keys
(tr/en/de). 436/436 community tests, analyze/l10n/quality clean. Completes the
post-edit vertical (migration → edge fn → data path → UI) on the branch.

## [2026-07-03] feat (branch) | community post edit client data path

Branch `feature/community-tab-faz1` (commit `68d6a57`). Client wiring for the
5-minute edit: `CommunityPost.editedAt` (`DateTime?`) + `CommunityPostX.isEdited`;
`CommunityPostRepository.update({postId, content})` →
`CommunityPostRemoteSource.updateContent` → `EdgeFunctionClient.updateCommunityPost`
(`mode: 'update'`). `_parsePost` reads `edited_at`; `update` invalidates post cache.
Online-first exemption doc-blocks untouched; generated Freezed files gitignored
(regenerated in CI). UI (sheet/menu/badge) lands in a later branch task.

## [2026-07-03] feat (branch) | community post edit hardening migration

Branch `feature/community-tab-faz1` (NOT yet merged/applied to prod). Migration
`20260703120000_community_post_edit_hardening.sql` (committed `3cdf483`): adds
`community_posts.edited_at timestamptz`, narrows the `authenticated` UPDATE grant
to `(is_deleted, needs_review)` so post **content** can no longer be
edited directly by clients (edits must go through the moderated
`create-community-post` edge fn `mode: 'update'`, being wired in the same branch),
and recreates `fetch_community_feed` (DROP+CREATE — RETURNS TABLE shape changed) to
return `edited_at`. Applied to prod 2026-07-03 (MCP; advisors 0 new). At apply time
the original grant listed `reviewed_by` too, but that column does NOT exist on
`community_posts` (never added by any migration) — dropped from the grant; the
`clearReviewFlag` write to it is a pre-existing latent bug (IMPROVEMENT_PLAN §6.14).
The other 3 authenticated UPDATE call-sites (`softDelete`, admin
`approvePost`/`deletePost`) write only within the grant. Client edit UI +
`edited` badge land in later tasks of the same branch. Design:
`docs/superpowers/specs/2026-07-03-community-tab-design.md`.

## [2026-07-03] feat | send-push server-side quiet hours — opt-in, fail-open (§5.2)

`send-push` can now honor a recipient's quiet-hours window (previously
device-only; push bypassed it). Pure helpers in `push_core.ts`
(`isWithinQuietHours` mirrors the client `NotificationRateLimiter` wraparound,
`localHourInZone` via IANA tz, `isSuppressedByQuietHours` fail-open) + `index.ts`
reads `profiles.quiet_hours` (JSONB, migration `20260703044437`, applied to
prod via MCP) and drops suppressed recipients before token resolution.
Safe-by-construction: suppression is **opt-in** (`respectQuietHours: true`), so
with no caller opting in yet it is a strict no-op — critical/incubation
notifications are never held back — and any missing/invalid config delivers.
Caught a real bug via live schema check: `profiles` has no `user_id` column
(PK is `id` = auth.uid()), so the recipient lookup selects on `id`. 7 Deno
tests (30 total green); `deno check` clean. Remaining activation (client DND
sync + caller opt-in taxonomy) noted in `.claude/rules/notifications.md`. See
[[domain/notification-service]].

## [2026-07-03] fix | Messaging surfaces send failures with a retry action (§4.3)

Continuing plan execution. A failed message send set `messagingFormStateProvider.error`
but nothing displayed it — the user saw the text stay in the input with no
reason. `MessageInputBar` now `ref.listen`s the form state and shows the error
(cooldown / moderation / length / network) in a SnackBar with a `common.retry`
action that re-sends the preserved text, then `clearError()`s. Chose this over
the full in-thread sending/failed status bubble (a `Message` delivery-status
field + build_runner + turning `messagingRealtimeProvider` into an id-keyed
upsert) because that touches heavily-tested realtime list management and is a
larger supervised refactor — noted in [[features/messaging]] /
`.claude/rules/messaging.md` § Delivery Status. Provider + widget tests added;
103 messaging tests green.

## [2026-07-03] fix | IMPROVEMENT_PLAN.md execution — XP cap, admin queue, reminders

Autonomous plan execution. (1) §4.1 (audit K12): the client-only daily XP cap
(`XpConstants.dailyLimits`) is now server-enforced by a `BEFORE INSERT` trigger
`private.enforce_xp_daily_limit` (SECURITY DEFINER, `search_path=''`) counting
same-day same-action rows and rejecting over-limit inserts; `recordAction`'s
try/catch swallows the rejection (XP is optional). Deployed via MCP
(`20260702234529_xp_daily_limit_enforcement.sql`), verified with a rolled-back
live tx. (2) §5.4 admin moderation queue tracks in-flight ids (`Set<String>`)
so one action locks only its own card, not the whole queue. (3) §5.5 calendar
events get a user-selectable reminder offset (default 30 min, `null` = none).
Local Flutter had drifted 3.41.4→3.44.4 overnight; restored to CI's pinned
3.41.4 first. See [[domain/gamification-service]], [[features/admin]],
[[features/calendar]].
