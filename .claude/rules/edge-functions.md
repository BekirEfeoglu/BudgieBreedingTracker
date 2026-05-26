# Supabase Edge Functions

## Inventory (9)
| Function | Trigger | Auth |
|----------|---------|------|
| `mfa-lockout` | MFA login attempts | JWT |
| `moderate-content` | Community reports / threshold auto-flag | JWT |
| `revenuecat-webhook` | RevenueCat subscription events (push) | Shared secret (`REVENUECAT_WEBHOOK_AUTH_TOKEN`) |
| `revoke-oauth-token` | Logout (Google/Apple) | JWT |
| `send-push` | Notification scheduler | JWT |
| `system-health` | Admin dashboard | JWT + admin role |
| `validate-free-tier-limit` | Entity insert path | JWT |
| `scan-image-safety` | Photo upload pipeline | JWT |
| `sync-premium-status` | RevenueCat premium sync (client pull) | JWT |

All client-called functions MUST enforce JWT verification. Never deploy with `--no-verify-jwt` for those — audit flagged this as release-blocker.

### Webhook Receiver Exception
Third-party webhook senders (RevenueCat, Stripe, Apple ASN, etc.) cannot send a Supabase JWT — they post server-to-server with their own auth model (static header, HMAC signature, mTLS). For those receivers ONLY:
- Set `verify_jwt = false` in `supabase/config.toml` (explicit, not omitted)
- Deploy with `--no-verify-jwt` flag in the CI deploy step
- Add the function name to `WEBHOOK_FUNCTIONS_EXEMPT_FROM_JWT` in `scripts/verify_security.py`
- The function source MUST perform its own auth (shared secret, signature verification) — never trust the raw request
- Use constant-time comparison for shared-secret checks (no timing leak)
- The shared secret MUST be 16+ characters; reject shorter configurations
- On auth failure return 401; on internal errors return 200 with a non-success body so the sender does NOT enter a retry storm — the next client pull will repair state

Current webhook receivers: `revenuecat-webhook` (shared secret via `REVENUECAT_WEBHOOK_AUTH_TOKEN`).

## Input Validation
- Parse all request bodies with a schema validator (Zod preferred, or hand-rolled type guards)
- Reject on schema mismatch with `400` before touching DB
- Never trust `user_id` from body — read from `req.headers.authorization` JWT claims
- Rate limit sensitive endpoints (`mfa-lockout`, `send-push`) via Supabase config

## Response Contract
- Return typed JSON — document shape in function folder `README.md` or header comment
- Error responses: `{ error: string, code?: string }` — UI maps `code` to l10n key
- HTTP status: `400` bad input, `401` auth, `403` permission, `429` rate limit, `500` server
- Dart side parses responses via Freezed model, not `Map<String, dynamic>`

## Invocation Completeness
- If a function exists, it must be invoked from app code OR a DB trigger OR a scheduled job
- Orphan function = wasted deploy cost + audit false positive
- Example: `moderate-content` must be wired to `community_reports` insert trigger or cron, not just deployed

## Policies
| Function | Policy | Rationale |
|----------|--------|-----------|
| `mfa-lockout` | 5 fails → lockout, 7-day decay | Prevent slow brute force (prior 24h decay allowed 1 try/day forever) |
| `validate-free-tier-limit` | Server-side enforcement, client cannot bypass | Free tier limits must not depend on client trust |
| `sync-premium-status` | RevenueCat checked server-side with secret key | Premium access must not depend on client assertions |
| `moderate-content` | Threshold-based auto-flag + human review queue | Scalable moderation, low false-positive risk |

## Testing Requirements
- Every edge function MUST have integration tests covering:
  1. Happy path (valid JWT + valid payload)
  2. Auth failure (missing/invalid JWT)
  3. Schema validation (malformed body)
  4. Business logic edge cases (limits, retries)
- Tests live in `supabase/functions/<name>/test.ts` using Deno test runner
- CI `deploy-edge-functions` job must run tests before deploy
- Dart-side test of HTTP wrapper ≠ edge function test — both required

## Deployment
- Function names must match exactly across: workflow, function folder, Dart `EdgeFunctionName` constants
- New function checklist:
  1. Create `supabase/functions/<name>/index.ts`
  2. Add tests: `supabase/functions/<name>/test.ts`
  3. Add name to `deploy-edge-functions` workflow matrix
  4. Add Dart constant + service wrapper if client-invoked
  5. Add DB trigger / cron if server-invoked
- Secrets: Supabase Dashboard → Edge Functions → Secrets. Never commit to repo.

## Anti-Patterns
1. Deploying with `--no-verify-jwt` (release-blocker)
2. Reading `user_id` from request body instead of JWT
3. Deploying without integration tests
4. Creating orphan functions (deployed but never invoked)
5. Returning raw Postgres errors to client (leaks schema)
6. Hardcoding secrets in function source
7. Short decay/cooldown windows that enable slow brute force

> **Related**: security.md (JWT, MFA policy), release-ops.md (deploy pipeline), data-layer.md (remote source wrapping)
