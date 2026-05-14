# Supabase Edge Functions

Source: `.claude/rules/edge-functions.md`

**Location**: `supabase/functions/`

8 Edge Functions, all require JWT verification.

## Inventory

| Function | Trigger | Auth |
|----------|---------|------|
| `mfa-lockout` | MFA login attempts | JWT |
| `moderate-content` | Community reports / threshold auto-flag | JWT |
| `revoke-oauth-token` | Logout (Google/Apple) | JWT |
| `send-push` | Notification scheduler | JWT |
| `system-health` | Admin dashboard | JWT + admin role |
| `validate-free-tier-limit` | Entity insert path | JWT |
| `scan-image-safety` | Photo upload pipeline | JWT |
| `sync-premium-status` | RevenueCat premium sync | JWT |

**Rule**: All functions MUST enforce JWT verification. Never deploy with `--no-verify-jwt` (release-blocker).

## Policies

| Function | Policy |
|----------|--------|
| `mfa-lockout` | 5 fails → lockout, 7-day decay |
| `validate-free-tier-limit` | Server-side enforcement; client cannot bypass |
| `sync-premium-status` | RevenueCat checked with secret key; client assertions not trusted |
| `moderate-content` | Threshold auto-flag + human review queue |

## Input Validation Rules

- Parse all request bodies with schema validator (Zod preferred)
- Reject on mismatch with `400` before touching DB
- `user_id`: **always from JWT claims**, never from request body
- Rate-limit sensitive endpoints

## Response Contract

```json
// Error format
{ "error": "string", "code": "optional_l10n_key" }
```

HTTP codes: 400 bad input, 401 auth, 403 permission, 429 rate limit, 500 server.

## New Function Checklist

1. Create `supabase/functions/<name>/index.ts`
2. Add `supabase/functions/<name>/test.ts` (Deno runner)
3. Add to `deploy-edge-functions` workflow matrix
4. Add Dart constant + service wrapper (if client-invoked)
5. Add DB trigger or cron (if server-invoked)
6. Never commit secrets — use Supabase Dashboard → Secrets

## Testing Requirements

Each function needs integration tests for:
1. Happy path (valid JWT + valid payload)
2. Auth failure (missing/invalid JWT)
3. Schema validation (malformed body)
4. Business logic edge cases

## CI Deploy

`deploy-edge-functions` job (main only, needs analyze+test). Function names must match exactly across workflow, function folder, and Dart `EdgeFunctionName` constants.

## Anti-Patterns

1. `--no-verify-jwt` (release-blocker)
2. `user_id` from request body instead of JWT
3. Orphan function (deployed but never invoked)
4. Returning raw Postgres errors (leaks schema)
5. Hardcoding secrets in function source

## See Also

- [[infrastructure/ci-cd]] — deploy job
- [[patterns/security]] — JWT, MFA
- [[domain/notification-service]] — send-push
- [[domain/premium-service]] — sync-premium-status, validate-free-tier-limit
