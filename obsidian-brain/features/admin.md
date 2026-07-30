# Feature: admin

**Purpose**: Operations dashboard for founders / staff — user management,
content moderation queue, system health, audit trail, feedback triage,
security overview, server-side config.

## Routes

| Screen | Route | File |
|--------|-------|------|
| Dashboard | `AppRoutes.adminDashboard` | `admin_dashboard_screen.dart` |
| Users (search, ban, role) | `AppRoutes.adminUsers` | `admin_users_screen.dart` + toolbar/card/list/bulk |
| User detail | `AppRoutes.adminUserDetail` | `admin_user_detail_screen.dart` |
| Monitoring (latency, error rate) | `AppRoutes.adminMonitoring` | `admin_monitoring_screen.dart` |
| Database (storage stats, indexes) | `AppRoutes.adminDatabase` | `admin_database_screen.dart` |
| Audit log | `AppRoutes.adminAudit` | `admin_audit_screen.dart` |
| Security overview | `AppRoutes.adminSecurity` | `admin_security_screen.dart` |
| Server settings / flags | `AppRoutes.adminSettings` | `admin_settings_screen.dart` |
| Feedback triage | `AppRoutes.adminFeedback` | `admin_feedback_screen.dart` |
| Moderation queue | `AppRoutes.adminModeration` | `admin_moderation_screen.dart` |

## Moderation Queue

`admin_moderation_screen.dart` + `admin_moderation_providers.dart` surface
community content awaiting review:

- `adminPendingPostsProvider` / `adminPendingCommentsProvider`
  (`FutureProvider.autoDispose`) fetch rows where `is_deleted = false` and
  `needs_review = true`, newest first. Both call `requireAdmin(ref)` first.
- `AdminModerationNotifier` (`adminModerationProvider`,
  `NotifierProvider<…, Set<String>>`) exposes `approvePost` / `deletePost` /
  `approveComment` / `deleteComment`. Approve clears `needs_review`; delete
  soft-deletes (`is_deleted = true`) and clears `needs_review`. `deletePost` /
  `deleteComment` are **confirm-gated** (2026-07-11): the screen shows a
  `showConfirmDialog(isDestructive: true)` (`admin.moderation_delete_title` /
  `admin.moderation_delete_confirm`) before removing content — previously a
  single tap deleted, the only remaining single-confirm destructive admin path.
  Each guards with `requireAdmin`, writes an `admin_logs` audit entry via
  `logAdminAction` (`community_post_approved` / `community_post_deleted` /
  `…comment…` — added 2026-07-02; these decisions previously left no audit
  trail), and invalidates the relevant list provider. On failure the action
  catch reports via `Sentry.captureException(e, stackTrace: st)` (2026-07-11,
  parity with `admin_bulk_manager` / user ops — was an `AppLogger.error`
  breadcrumb only). Queue thumbnails use
  `CachedNetworkImage` (was raw `Image.network`). State is the set of
  in-flight entity ids (2026-07-03, was a single global `AsyncNotifier<void>`
  loading flag): each card watches only its own id via
  `.select((s) => s.contains(id))`, so one action locks just its card instead
  of freezing the whole queue, and a double-tap on an in-flight item is
  ignored.
- Column names use `SupabaseConstants` (`colIsDeleted`, `colNeedsReview`,
  `colId`, `colCreatedAt`) — the admin `client.from()` exception does NOT
  waive the hardcoded-string rule.

## Force Logout

`AdminUserManager.forceLogout` (user detail → security section,
`admin_user_detail_content_security.dart`) calls the `admin_force_logout`
RPC, which (server-side, `is_admin()`-gated) `DELETE`s all `auth.sessions`
rows for the target and stamps `profiles.session_revoked_at`. Refresh tokens
are revoked immediately; the live access token remains valid until expiry
(≤1h) — there is no custom access-token hook enforcing `session_revoked_at`.
Protected roles (founder) are blocked client-side before the RPC.

UI confirmation is two-step (confirm dialog → typed user-ID confirm via
`showTypedConfirmDialog`), matching every other destructive admin action
per `.claude/rules/admin.md`. Before 2026-07-02 this action only had the
first step (single confirm dialog, no typed confirm) — the only destructive
admin action missing the second step.

All `AdminUserManager` destructive ops (`toggleUserActive`, `grantPremium`,
`revokePremium`, `forceLogout`) report failures via
`Sentry.captureException(e, stackTrace: st)` (2026-07-11) — parity with
`admin_bulk_manager`; a failed ban/grant was previously only an
`AppLogger.error` breadcrumb (anti-pattern #23).

Premium access is controlled from the user-detail subscription card with an
adaptive switch. The switch is replaced by a progress indicator while the RPC
is in flight, and the notifier rejects a second premium mutation. Grant and
revoke remain confirm-gated (revoke also uses typed user-ID confirmation).
Both RPCs record `user_subscriptions.provider = manual`; RevenueCat pull and
webhook syncs preserve that decision. Revoking access does not cancel App
Store/Google Play billing, which the confirmation copy states explicitly.

`admin_get_user_aggregate_detail(p_user_id)` RPC fetches the full user-detail
payload (profile, subscription, entity counts, recent activity logs) in one
round-trip. It is `SECURITY INVOKER` + `is_admin()`-gated and relies on the
admin-inclusive RLS SELECT policies on every table it reads.

## Architectural Exception

`admin/` is the **only** feature module allowed to call `client.from()`
directly — no Repository wrapper required. Rationale: admin screens
expose ad-hoc Postgres surface (cross-user counts, server-side queries),
and forcing a Repository per query would create dead code. The exception
is documented in [[architecture/layers]] and enforced by code review,
not by lint.

This exception MUST NOT spread to other features. Audit checks flag
direct `client.from()` calls outside `admin/`.

## Guarding

`AdminGuard` (in `lib/router/guards/`) reads `isAdminProvider` / `isFounderProvider`
(`lib/data/providers/user_role_providers.dart`) and redirects non-admin/founder
users to `AppRoutes.home`. Every admin route
is guarded — there is no "soft" admin surface.

Roles (from `lib/data/providers/user_role_providers.dart`):

- `member` — default
- `admin` — full dashboard access
- `founder` — superset (currently equivalent to admin + feature flag access)

## Provider

`adminActionsProvider` (`NotifierProvider<AdminActionsNotifier, …>`) holds
the state for bulk actions (ban, unban, role change) and surfaces
loading/error/success. UI uses `ref.listen()` to react with snackbar.

`adminUserCountsProvider` (`FutureProvider<AdminUserCounts>` in
`admin_users_providers.dart`) returns database-wide user counts
(`total`, `active`, `inactive`, `online`) for the users summary bar —
total/active via `profiles` head counts (`.count()`), online via the
presence-sessions source (same threshold as `AdminUser.isOnline`, including
the admin's own local presence). It exists because the list query is capped
at `AdminConstants.usersPageSize` (50): deriving totals from the loaded page
undercounts them. The screen shows these global counts when the list is
unfiltered and falls back to the loaded set while filtered/searched. Counts
are invalidated on refresh, retry, and user mutations (bulk + detail).

`adminBuildDistributionProvider` reads the admin-gated
`admin_get_build_distribution` RPC. Monitoring shows 30-day iOS/Android
coverage and build share from each user-platform's latest session; legacy null
versions stay in the denominator so incomplete telemetry is visible. It
refreshes only on pull-to-refresh/retry, not the capacity timer.

## Current Decisions

- `admin/` is the only feature allowed to call Supabase `client.from()` directly.
- Every route is guarded by `AdminGuard`; admin/founder role is required.
- Moderation is always reachable from the sidebar, quick actions, and content
  review card, including when the pending count is zero.
- Admin interactive cards, quick actions, switches, database actions, and audit
  date filters expose one labeled semantic control per action.
- The monitoring rollup cannot report healthy while index usage or slow-query
  signals are in a warning/critical state.
- Destructive actions use two-step confirmation and write audit entries.
- Moderation post/comment removal is confirm-gated; no destructive admin path is single-tap.
- Destructive admin op failures (user ops, bulk, moderation) report to Sentry, not just a breadcrumb.
- User list summary counts come from database-wide providers, not the loaded page.
- Build rollout decisions use both adoption share and version telemetry coverage.
- Manual premium grants/revocations are authoritative until another admin
  changes them; RevenueCat sync does not replace `provider=manual` records.

## Known Deferred Work

- Access-token revocation remains bounded by token expiry after `admin_force_logout`.
- Admin aggregate RPCs should stay narrow; add fields only when a screen needs them.
- Monitoring and capacity values depend on server-side RPC coverage and may lag UI needs.

## Do Not Reintroduce

- Do not spread direct `client.from()` calls outside `lib/features/admin/`.
- Do not add single-confirm destructive admin actions.
- Do not derive global user counts from the paginated visible list.

## Edge Function Hooks

| Edge fn | Used in |
|---------|---------|
| `system-health` | Monitoring screen |
| `moderate-content` | Feedback / moderation flows |
| `mfa-lockout` | Security screen — view + reset lockouts |

All admin-invoked Edge Functions require `JWT + admin role` server-side
(see [[infrastructure/edge-functions]]).

## Rules

- `.claude/rules/admin.md` — AdminGuard, audit logs, destructive guards (two-step + type-to-confirm), moderation queue, monitoring polling rules, race mitigation
- `.claude/rules/security.md` — AdminGuard + role-based redirects
- `.claude/rules/edge-functions.md` — admin-scoped functions
- `.claude/rules/architecture.md` — feature exception

## See Also

- [[infrastructure/edge-functions]]
- [[patterns/security]] — RLS + guards
- [[features/feedback]] — user-side of feedback triage
- [[features/_features-index]]
