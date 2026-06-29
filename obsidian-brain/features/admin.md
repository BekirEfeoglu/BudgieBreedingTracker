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
  `AsyncNotifierProvider<…, void>`) exposes `approvePost` / `deletePost` /
  `approveComment` / `deleteComment`. Approve clears `needs_review`; delete
  soft-deletes (`is_deleted = true`) and clears `needs_review`. Each guards
  with `requireAdmin` and invalidates the relevant list provider.
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

`AdminGuard` (in `lib/router/guards/`) reads `userRoleProvider` and
redirects non-admin/founder users to `AppRoutes.home`. Every admin route
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
