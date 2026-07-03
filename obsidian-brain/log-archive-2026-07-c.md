# Change Log Archive - 2026-07 (part 3, 07-02 all-tabs audit)

Back to [[log]].

## [2026-07-02] fix | All-tabs comprehensive audit + remediation

User asked to comprehensively examine all 5 main tabs (Home, Birds, Breeding,
Calendar, More) plus More's ~15 sub-features — in practice, nearly the whole
app. 7 parallel agents (one per tab/cluster) surfaced ~50 findings; each was
independently verified against real code before fixing. Full quality gates
green throughout: `flutter analyze` 0, 27-checker scan 0/0, `verify_rules.py`
24/24, l10n 3015/3015/3015 synced, `flutter test` 11,912/11,912 (two real
regressions found by the full-suite run and fixed before this entry — see
below).

**Critical**: MFA-enrolled users could not change their password or delete
their account — `_requireAal2IfEnrolled()` always re-throws after the
password-reauth step resets AAL2 back to AAL1, with no path back to AAL2.
Account deletion had a second, worse form: storage-file cleanup ran *before*
the AAL2 check, so an MFA user's photos could be permanently deleted without
the deletion completing. Fixed with a new MFA-challenge-and-retry flow (see
[[domain/auth-service]]). Marketplace's free-tier listing limit was never
actually server-enforced despite a comment claiming otherwise (see
[[features/marketplace]]). `EggActionsNotifier.updateEggStatus` rebased
writes on a caller-held snapshot that could be stale across an async UI gap,
silently reverting concurrent edits to other fields (see
[[domain/eggs-service]]).

**High**: health record edit/delete never cancelled or rescheduled
follow-up reminders (zombie notifications) — fixed, and while fixing it the
full-suite test run caught a second issue: the new best-effort `getById`
pre-fetch wasn't failure-isolated, so a fetch error could abort the primary
save/delete too (see [[features/health_records]]). Genealogy's family-tree
and ancestor-list widgets had no cycle guard, unlike the sibling stats
calculator (see [[features/genealogy]]). Birds' context-menu "Edit" action
pushed a nonexistent `/birds/:id/edit` route (404) instead of
`/birds/form?editId=`. Blocked users could still send messages into a
conversation they already belonged to — RLS never checked
`community_blocks` on insert; fixed and deployed to production same day
(`20260702174304_block_messages_from_blocked_users.sql`, applied via
Supabase MCP after the CLI's direct-DB connection failed on IPv6/SSL
negotiation — see [[features/messaging]]).

**Medium/low**: image-safety scan fail-*open* on a malformed edge-function
response (contradicted its own fail-closed doc comment); guests could browse
the user-guide list but got redirected to login opening a topic
(`/user-guide/:id` missing from the anonymous-allowed prefix match);
`Event`'s `unknownEnumValue` fallback used real interactive values
(`EventType.custom`/`EventStatus.active`) instead of the dedicated `unknown`
sentinel that already existed; admin force-logout was the only destructive
action missing the typed-confirm step (see [[features/admin]]); home-widget
sync dedup was defeated by including display-only timestamp fields in
`HomeWidgetDashboardSnapshot` equality (see [[domain/home-widget-service]]);
leaderboard showed a raw exception string and a `LucideIcons` icon instead
of the existing `AppIcons.leaderboard`; a second logout call site
(`danger_zone_section.dart`) had no error handling, unlike the hardened one
in `profile_menu_dialog.dart`; `feedback.error_network` mapped to a
translation key that existed in no language file (the l10n-sync checker
can't catch store-then-`.tr()`-elsewhere indirection).

**Found, deliberately not fixed**: `profiles.is_verified_breeder`/`level`/
`xp_title` have no RLS write guard — any authenticated user can self-grant
the verified-breeder trust badge. A straightforward RLS lock-down was
drafted and reverted because it would also break the app's own legitimate
XP/level write path (`GamificationService` writes both via a normal
authenticated client call, not a service-role RPC) — see
[[features/marketplace]] § Verification Badge for the full explanation.
Correct fix needs a `SECURITY DEFINER` RPC redesign, scoped separately.
`.claude/rules/messaging.md` and [[features/messaging]] corrected for
several long-standing doc/code mismatches surfaced by this audit: group
chat is real (schema is `conversations`/`conversation_participants`, not
the documented deterministic-ID 1-1 scheme), delivery-status
(sending/sent/delivered/failed) doesn't exist, the read-receipt privacy
opt-out doesn't exist, and the attachment pipeline isn't wired to any UI.
