# Change Log

Chronological record of wiki updates. Format: `## [date] action | summary`

---

## [2026-07-17] ops | Production release Sentry monitoring enforced

Created the `budgie-breeding-tracker` Flutter project in the production Sentry
organization, stored its DSN in GitHub/Codemagic, verified ingestion with one
synthetic production event, and added an `org:ci`-only token plus
`sentry_dart_plugin` so obfuscated release symbols upload before publishing.

## [2026-07-17] chore | Supabase local SMTP config deprecation removed

Renamed the local email-capture section from deprecated `[inbucket]` to
`[local_smtp]`, matching Supabase CLI's current template without changing ports
or behavior. A static config regression prevents the warning from returning.

## [2026-07-17] ci-fix | Hook Flutter environment and Edge deploy regression repaired

The pre-commit hook now removes repository-local Git variables only for Flutter
subprocesses, preventing the SDK version from degrading to `0.0.0-unknown` in a
hook. Hook installation is worktree-relative and executable-safe. The Edge
deploy dependency regression now asserts the path guard alongside analyze,
Flutter, and Edge tests; a real hook-environment test covers the failure mode.

## [2026-07-17] ci-fix | Edge deploy is path-gated; marketplace moderation rejection now logs safely
Docs-only main pushes no longer redeploy unchanged Edge Functions; source/config/workflow changes remain test-gated. Expected server moderation rejections emit a non-sensitive warning before the localized validation error, with workflow and remote-source regressions.

## [2026-07-17] fix | Marketing site tablet navigation and accessibility

Live-tested at 375/768/1024/1440 widths. The landing header now uses the
hamburger below 1200px; 48px targets, FAQ/carousel semantics, focus, and heading
order are corrected. TR/EN/DE security copy scopes AES-256 to implemented
fields/backups and retains the 2 MiB scan boundary. Genetics output no longer
leaks Turkish. The user guide uses native buttons, localized ARIA, correct emoji,
layered Escape/focus restoration, and 48px controls. Terms pages remove leaked
annotations and mobile overflow; explicit EN/DE URLs remain authoritative and
privacy links stay in-language. Shared locale scripts are cache-versioned. All
64 public HTML files have asset/ID coverage plus guide/legal regression tests.

## [2026-07-17] sync | Conflict retry now restores encrypted local snapshots

Drift v29 stores encrypted local/server snapshots before server-wins overwrite.
Retry validates and restores through typed DAOs, preserves one pending metadata
row and the oldest unresolved snapshot, and fails closed for legacy/corrupt
payloads. UI success additionally requires restored metadata to leave the queue.

## [2026-07-17] fix | Scanned image upload size contract unified at 2 MiB raw

Bird, community, marketplace, DM, avatar, egg, and chick upload boundaries now
enforce 2 MiB raw from post-picker guards through storage, Edge scans, and seven
bucket limits. The lower cap bounds base64/decode cost; exact-limit padding,
multi-surface, Edge, and migration regressions are covered.

## [2026-07-16] docs | Semantic sync/forms/image reconciliation

Reconciled current wiki claims against production paths: `SyncOrchestrator`
push→pull flow, per-record metadata, nine FK-validating repositories, six
online-first exceptions, conflict surfaces, ring uniqueness, picker-specific
image sizing, marketplace storage, and 11,611 tests. Removed the false ring
gap; added real conflict-payload and 10MB-vs-2MB scan-limit gaps. Hardened the
absence/allowlist review contract and pruned two obsolete drift allowlist items.

## [2026-07-14] perf | Feed RPC emits is_following_author; messages_insert uses definer helpers

Two follow-ups. **`20260714200510`**: `fetch_community_feed` now returns
`is_following_author` (EXISTS over `community_follows`, both sort branches,
SECURITY INVOKER — `community_follows_select` already exposes the follower's own
rows), so the feed is one round-trip again. RETURNS TABLE changed => DROP+CREATE,
grants (`authenticated`, `service_role`, no PUBLIC) restored explicitly; the
parameter list is unchanged so older binaries keep working. `_enrichPosts` now
only does the `fetchFollowedUserIds` lookup when the rows lack the column — the
non-RPC paths (fetchById/ByUser/ByTag/ByIds) still need it.

**`20260714200511`**: `messages_insert` moved off its two inlined subqueries onto
`private.is_conversation_member` + a new `private.sender_blocked_in_conversation`.
Note the new helper deliberately does NOT reuse `conversation_has_block_with`:
that one filters `is_left = false`, while the original messages_insert counted
blocks against LEFT participants too — semantics preserved exactly.

Verified in prod: 0 posts flagged before following, 9 after (both newest and
trending branches); message send OK, rejected 42501 once a block exists.

## [2026-07-14] security | Scope participants_insert self-join to the conversation creator

Follow-up to the DM recursion fix. `participants_insert` still allowed an
unscoped self-join (`user_id = auth.uid()` into ANY conversation): anyone who
learned a conversation UUID could add themselves and — since every read policy
is membership-based — read the entire thread. Migration `20260714192445` adds
`private.is_conversation_creator` (SECURITY DEFINER; a bare subquery over
`public.conversations` would deadlock bootstrap, because
`conversations_participant_read` demands membership that does not exist yet) and
scopes the branch to the creator. Owner/admin invites unchanged.

Verified in prod as real authenticated users: DM create end-to-end OK, group
owner invite OK, non-creator self-join into someone else's DM **and** group both
rejected (42501) with 0 messages visible, block guard still fires (42501).
Security advisor: no new findings. Applied via Supabase MCP.

## [2026-07-14] fix | Community follow + DM were dead: RLS recursion & missing follow state

User report: "topluluk sekmesinde takip ve kişisel mesaj çalışmıyor". Three
root causes, all proven against prod before touching code.

**DM (hard failure, server).** `participants_insert`'s `WITH CHECK` contained an
unconditional raw `NOT EXISTS (SELECT … FROM conversation_participants …)`
(added by the 2026-07-02 block-hardening migration, which silently reverted
`20260402130000_fix_participants_rls_recursion.sql`). Reading the table from
inside its own policy → `42P17 infinite recursion` on EVERY participant insert.
DM never worked in prod (conversations/participants/messages = 0 rows).
Fix + applied to prod: `20260714181422_fix_conversation_participants_rls_recursion.sql`
routes the owner/admin and block checks through `private.is_conversation_manager`
/ `private.conversation_has_block_with` (SECURITY DEFINER). Verified end-to-end
as a real authenticated user (create → 2 participants → message → read cursor →
recipient reads); block rejection still fires (42501). Advisors: 0 new findings.

**Follow (client).** `fetch_community_feed` never returns `is_following_author`,
so `CommunityPost.isFollowingAuthor` was permanently `false` — the button never
showed the followed state and the "following" filter tab was always empty.
`_enrichPosts` now fetches `fetchFollowedUserIds` alongside the social-state RPC
(covers feed/detail/user-posts/tag/bookmark in one place). `FollowToggleNotifier`
now also invalidates `followedUsersProvider`, which the public-profile follow
button reads — without it that button ignored taps until pull-to-refresh.

Also: the community-tagged marketplace test still asserted the pre-2026-07-10
"messaging disabled" contract and had been red in the weekly suite; updated.
Rules updated: community.md (§ Follow + 2 anti-patterns), messaging.md (recursion
regression + anti-pattern #12).

## [2026-07-14] ci | Drift guard: +Dao/Mapper/Guard, bare-prose scan, allowlist audit

Third round of drift-guard hardening (measured before wiring, per the
suggestions). **Suffix expansion:** `--classes` now also checks
`*Dao`/`*Mapper`/`*Guard` (measured 8 tokens, 0 unresolved → zero-noise).
**Bare-prose scan:** class-suffix names are now checked outside backticks too
(fenced code blocks + inline-backtick spans stripped first) — closes the gap
that let the `ConnectivityService` sibling in data-flow.md slip past a
backtick-only scan (20 bare pairs measured, 0 unresolved). **Allowlist audit:**
new `--audit-allowlist` mode (periodic, NOT gated) flags allowlist entries no
longer cited by any doc; ran it and pruned 8 dead placeholders (`exampleProvider`,
`myAsyncProvider`, `someProvider`, `bar.dart`, `example.dart`, `foo.dart`,
`my_form.dart`, `my_screen.dart`). Both the `--target all --classes` gate and
the audit are clean. Test suite 23→31 (100% cov). Docs synced (CLAUDE.md
Quality Scripts, documentation-sync.md, wiki scripts.md).

## [2026-07-14] ci | Drift guard extended to wiki + class names; wiki symbol drift fixed

Executed the three follow-up suggestions. **#3 (obfuscation debunk):** `git grep`
found 135 `*Notifier` / 29 `*Service` / 492 `*Provider` readable names — the
subagent "source is minified" claim was an artifact; disregarded. **#1 + #2
(extend the checker):** `check_rule_symbol_drift.py` gained `--target
{rules,wiki,all}` (wiki scan excludes `log.md`/`log-archive-*` — chronological
history legitimately names removed symbols) and `--classes` (opt-in check of
`*Service`/`*Notifier`/`*Repository` — measured LOW noise: every finding was
genuine drift or documented-non-existence prose). Both surfaces + classes now
gated via `--target all --classes` in the `code-quality` CI job +
`run_local_quality_gate.sh`. **Wiki drift fixed (11):** breeding
`breedingPairListProvider`→`filteredBreedingPairsProvider` +
`activeIncubationsProvider`→`allIncubationsStreamProvider`; chicks
`chickListProvider`→`filteredChicksProvider`; eggs `eggs_mapper.dart`→`egg_mapper.dart`;
profile `currentUserProfileProvider`→`userProfileProvider`; home
`connectivityProvider`→`syncStatusProvider`; admin+more
`userRoleProvider`→`isAdminProvider`/`isFounderProvider`; data-io
`adsServiceProvider`→`adServiceProvider`; premium ×2
`freeTierUsageProvider`→`freeTierLimitServiceProvider`. **Class drift fixed:**
background-sync.md + data-flow.md `ConnectivityService`→`networkStatusProvider`
(the real `connectivity_plus` wrapper; no such class exists). Allowlisted the
documented-non-existence prose (premiumStatusProvider, genealogyTreeProvider,
MarketplaceListingRepository anti-pattern name, CalendarService,
IncubationReminderService). Test suite 18→23 (100% cov). Docs synced across
CLAUDE.md/ci-actions.md/documentation-sync.md/wiki.

Older entries are archived in [[log-archive-2026-07-l]], [[log-archive-2026-07-k]], [[log-archive-2026-07-j]], [[log-archive-2026-07-i]], [[log-archive-2026-07-h]], [[log-archive-2026-07-g]], [[log-archive-2026-07-f]], [[log-archive-2026-07-e]], [[log-archive-2026-07-d]], [[log-archive-2026-07-c]], [[log-archive-2026-07-b]], [[log-archive-2026-07]], [[log-archive-2026-06]] and [[log-archive-2026-05]].
