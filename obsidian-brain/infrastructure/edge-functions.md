# Supabase Edge Functions

Source: `.claude/rules/edge-functions.md`

**Location**: `supabase/functions/`

12 Edge Functions. All client-called functions require JWT verification; webhook receivers use shared-secret auth (see Webhook Receiver Exception).

## Inventory

| Function | Trigger | Auth |
|----------|---------|------|
| `create-community-comment` | Community comment create path | JWT |
| `create-community-post` | Community post create path | JWT |
| `mfa-lockout` | MFA login attempts | JWT |
| `moderate-content` | Community reports / threshold auto-flag | JWT |
| `revenuecat-webhook` | RevenueCat subscription events (server-to-server push) | Shared secret (`REVENUECAT_WEBHOOK_AUTH_TOKEN`) |
| `revoke-oauth-token` | Logout (Google/Apple) | JWT |
| `send-push` | Notification scheduler, admin, persisted DM send | JWT |
| `system-health` | Admin dashboard | JWT + admin role |
| `validate-free-tier-limit` | Entity insert path | JWT |
| `scan-image-safety` | Photo upload pipeline | JWT |
| `sync-premium-status` | RevenueCat premium sync (client pull) | JWT |
| `upload-community-photo` | Community photo upload path | JWT |

**Rule**: All client-called functions MUST enforce JWT verification. Never deploy with `--no-verify-jwt` for those (release-blocker). Webhook receivers are exempt — see below.

## Webhook Receiver Exception

Third-party webhook senders (RevenueCat, Stripe, Apple ASN, etc.) cannot send a Supabase JWT — they post server-to-server with their own auth model. For those receivers ONLY:

- Set `verify_jwt = false` in `supabase/config.toml` (explicit, not omitted)
- Deploy with `--no-verify-jwt` flag in CI deploy step
- Add the function name to `WEBHOOK_FUNCTIONS_EXEMPT_FROM_JWT` in `scripts/verify_security.py`
- Function source MUST perform its own auth (shared secret, signature verification) — never trust raw request
- Use constant-time comparison for shared-secret checks (no timing leak)
- Shared secret MUST be 16+ characters; reject shorter configurations
- On auth failure return 401; on internal errors return 200 with non-success body so the sender doesn't enter a retry storm — the next client pull will repair state

Current webhook receivers: `revenuecat-webhook` (shared secret via `REVENUECAT_WEBHOOK_AUTH_TOKEN`).

## Policies

| Function | Policy |
|----------|--------|
| `mfa-lockout` | 5 fails → lockout, 7-day decay |
| `validate-free-tier-limit` | Server-side enforcement; client cannot bypass |
| `sync-premium-status` | Preserves audited `provider=manual` admin overrides; otherwise RevenueCat is checked with the secret key and client assertions are not trusted |
| `revenuecat-webhook` | Preserves audited `provider=manual` admin overrides; otherwise refetches the full subscriber and converges with `sync-premium-status`. TEST events ack 200 without DB writes. Unknown event types still refetch defensively. Founder/admin short-circuit mirrors `sync-premium-status`. |
| `moderate-content` | Threshold auto-flag + human review queue |
| `create-community-post` | Server-side moderation + post guard before insert; also `mode:'update'` edit-window path. `image_urls` Zod cap is **10** (the premium max) — through 2026-07-09 it was `6`, which deterministically 400'd premium 7–10-photo posts after upload. |
| `create-community-comment` | Server-side moderation + reciprocal block check before insert |
| `upload-community-photo` | Server-side image moderation before Storage write |
| `send-push` | Ordinary cross-user/raw-token sends remain admin-only. Strict DM mode accepts only `messageId`, verifies ownership, derives active/unmuted recipients and lock-screen-safe copy service-side, and honors quiet hours. |

Both premium sync paths persist verified RevenueCat state through the
service-role-only `apply_verified_premium_status` RPC rather than direct table
writes. The RPC shares a per-user advisory lock with admin grant/revoke and
rechecks the manual provider under that lock, preventing a stale RevenueCat
response from winning a concurrent admin override.

Image Edge paths share a raw 2 MiB cap. The request envelope budgets base64 as
`ceil(raw/3)*4 + 1024` bytes, including JSON metadata; decoded-size calculation
subtracts `=` padding, so the exact boundary is accepted. The cap stays below
the general 10 MiB processing budget to bound parser copy + community decode +
provider reserialization memory and payload-amplification abuse.
This also preserves headroom under hosted Supabase Edge's current per-function
256 MB memory and 2-second CPU limits ([official limits, checked 2026-07-17](https://supabase.com/docs/guides/functions/limits)).

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

### Additional steps for webhook receivers

7. Set `verify_jwt = false` in `supabase/config.toml` (with comment explaining why)
8. Add `--no-verify-jwt` to the deploy line in CI
9. Add function name to `WEBHOOK_FUNCTIONS_EXEMPT_FROM_JWT` in `scripts/verify_security.py`
10. Implement own auth in function source (shared secret with constant-time check, or HMAC signature) — reject if secret is <16 chars
11. Set the shared secret in Supabase Dashboard → Edge Functions → Secrets AND in the third-party sender's webhook config
12. Document the exception in this page's "Webhook Receiver Exception" section

## Testing Requirements

Each function needs integration tests for:
1. Happy path (valid JWT + valid payload)
2. Auth failure (missing/invalid JWT)
3. Schema validation (malformed body)
4. Business logic edge cases

**All 12 functions now use the dependency-injected handler pattern** (2026-07-12): `index.ts` is just `Deno.serve(createXHandler())`; `handler.ts` exports `createXHandler(deps = defaultDeps)` with injectable external calls (`getAuthenticatedUserId`, `createSupabaseAdmin`, env getters, `now`, external fetches); `handler_test.ts` injects mock deps and asserts real `Response.status` for the auth→ratelimit→parse→DB wiring (401/400/403/503/200), catching a future reorder that pure `*_core.ts` logic tests would miss. `*_core.ts` still holds pure logic + its own tests. Model: `create-community-comment/handler.ts`.

## CI Deploy

`deploy-edge-functions` job (main only, needs analyze+test+edge-functions-test)
is gated by `edge-function-changes`. It deploys only when
`supabase/functions/**`, `supabase/config.toml`, or `.github/workflows/ci.yml`
changes; documentation-only pushes skip production deployment. Function names
are passed as raw string literals at call sites in
`lib/data/remote/supabase/edge_function_client.dart` — there is no
`EdgeFunctionName` constants class; names must still match exactly across
workflow, function folder, and call sites. `verify_rules.py` § Edge Functions
enforces this in the `rules-sync` job: directories ↔ `config.toml`
`[functions.*]` ↔ the `ci.yml` deploy list are compared two-way, and every
client literal (including the `_rateLimitExempt` set, where a stale name fails
silently by simply not exempting) must resolve to a real function. The client
direction is one-way — a webhook/trigger/cron function needs no client caller.

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
