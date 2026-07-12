import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  createSyncPremiumStatusHandler,
  type SyncPremiumStatusDeps,
} from "./handler.ts";

const USER_ID = "00000000-0000-7000-8000-000000000222";
const FIXED_NOW = new Date("2026-01-01T00:00:00Z");

function authedRequest(
  opts: { authorization?: string | null } = {},
): Request {
  const headers = new Headers();
  if (opts.authorization !== null) {
    headers.set("Authorization", opts.authorization ?? "Bearer valid-token");
  }
  return new Request("https://example.com/sync-premium-status", {
    method: "POST",
    headers,
  });
}

function makeAdmin(overrides: {
  profile?: Record<string, unknown> | null;
  profileLookupError?: { message: string } | null;
  profileUpdateError?: { message: string } | null;
  subscriptionError?: { message: string } | null;
  updated?: Record<string, unknown>[];
} = {}) {
  const updated = overrides.updated ?? [];
  const profile = overrides.profile === undefined
    ? { role: null }
    : overrides.profile;

  return {
    from: (table: string) => {
      if (table === "profiles") {
        return {
          select: () => ({
            eq: () => ({
              single: () =>
                Promise.resolve({
                  data: profile,
                  error: overrides.profileLookupError ?? null,
                }),
            }),
          }),
          update: (row: Record<string, unknown>) => ({
            eq: () => ({
              select: () => ({
                single: () => {
                  updated.push(row);
                  if (overrides.profileUpdateError) {
                    return Promise.resolve({
                      data: null,
                      error: overrides.profileUpdateError,
                    });
                  }
                  return Promise.resolve({ data: row, error: null });
                },
              }),
            }),
          }),
        };
      }
      if (table === "user_subscriptions") {
        return {
          upsert: () =>
            Promise.resolve({ error: overrides.subscriptionError ?? null }),
          update: () => ({
            eq: () =>
              Promise.resolve({
                error: overrides.subscriptionError ?? null,
              }),
          }),
        };
      }
      throw new Error(`unexpected table ${table}`);
    },
  };
}

function baseDeps(
  overrides: Partial<SyncPremiumStatusDeps> = {},
): SyncPremiumStatusDeps {
  return {
    getAuthenticatedUserId: () => Promise.resolve(USER_ID),
    checkRateLimit: () => Promise.resolve(true),
    createAdminClient: () => makeAdmin(),
    getEntitlementId: () => "premium",
    fetchSubscriber: () =>
      Promise.resolve({
        subscriber: {
          entitlements: {
            premium: {
              expires_date: "2026-02-01T00:00:00Z",
              product_identifier: "premium_monthly",
            },
          },
        },
      }),
    now: () => FIXED_NOW,
    ...overrides,
  };
}

Deno.test("sync-premium-status rejects missing/invalid JWT", async () => {
  const response = await createSyncPremiumStatusHandler(
    baseDeps({ getAuthenticatedUserId: () => Promise.resolve(null) }),
  )(authedRequest());

  assertEquals(response.status, 401);
  assertEquals((await response.json()).error, "Unauthorized");
});

Deno.test("sync-premium-status rate limits repeated calls", async () => {
  const response = await createSyncPremiumStatusHandler(
    baseDeps({ checkRateLimit: () => Promise.resolve(false) }),
  )(authedRequest());

  assertEquals(response.status, 429);
});

Deno.test("sync-premium-status short-circuits admin/founder roles", async () => {
  const response = await createSyncPremiumStatusHandler(
    baseDeps({
      createAdminClient: () => makeAdmin({ profile: { role: "admin" } }),
    }),
  )(authedRequest());

  assertEquals(response.status, 200);
  assertEquals(await response.json(), {
    success: true,
    is_premium: true,
    subscription_status: "premium",
    role_based: true,
  });
});

Deno.test("sync-premium-status returns 500 when profile lookup fails", async () => {
  const response = await createSyncPremiumStatusHandler(
    baseDeps({
      createAdminClient: () =>
        makeAdmin({ profileLookupError: { message: "db exploded" } }),
    }),
  )(authedRequest());

  assertEquals(response.status, 500);
  assertEquals((await response.json()).error, "Internal server error");
});

Deno.test("sync-premium-status syncs premium status on happy path", async () => {
  const updated: Record<string, unknown>[] = [];
  const response = await createSyncPremiumStatusHandler(
    baseDeps({ createAdminClient: () => makeAdmin({ updated }) }),
  )(authedRequest());

  assertEquals(response.status, 200);
  assertEquals(await response.json(), {
    success: true,
    is_premium: true,
    subscription_status: "premium",
    premium_expires_at: "2026-02-01T00:00:00Z",
    grace_period_until: null,
  });
  assertEquals(updated.length, 1);
  assertEquals(updated[0].is_premium, true);
});
