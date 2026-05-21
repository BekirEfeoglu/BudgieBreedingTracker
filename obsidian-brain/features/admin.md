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

## Edge Function Hooks

| Edge fn | Used in |
|---------|---------|
| `system-health` | Monitoring screen |
| `moderate-content` | Feedback / moderation flows |
| `mfa-lockout` | Security screen — view + reset lockouts |

All admin-invoked Edge Functions require `JWT + admin role` server-side
(see [[infrastructure/edge-functions]]).

## Rules

- `.claude/rules/security.md` — AdminGuard + role-based redirects
- `.claude/rules/edge-functions.md` — admin-scoped functions
- `.claude/rules/architecture.md` — feature exception

## See Also

- [[infrastructure/edge-functions]]
- [[patterns/security]] — RLS + guards
- [[features/feedback]] — user-side of feedback triage
- [[features/_features-index]]
