# Feature: admin

**Purpose**: Admin-only dashboard for system management, moderation, and health checks.

## Key Screens

- Admin dashboard overview
- User management
- Content moderation queue
- System health (`system-health` edge function)

## Special Permissions

- Protected by `AdminGuard` — redirects non-admins to home
- **Exception to the architecture rule**: `admin/` feature may call `client.from()` directly (no Repository required)

## Related Services

- `system-health` Edge Function (JWT + admin role required)
- `moderate-content` Edge Function (community moderation)

## Rules

- `.claude/rules/security.md` — AdminGuard, route protection
- `.claude/rules/edge-functions.md` — system-health invocation

## See Also

- [[features/_features-index]]
- [[infrastructure/edge-functions]]
