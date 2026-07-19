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
  subscription?: Record<string, unknown> | null;
  subscriptionLookupError?: { message: string } | null;
  applyError?: { message: string } | null;
  applyResult?: Record<string, unknown> | null;
  applied?: Record<string, unknown>[];
} = {}) {
  const applied = overrides.applied ?? [];
  const profile = overrides.profile === undefined
    ? { role: null }
    : overrides.profile;

  return {
    rpc: (fn: string, params: Record<string, unknown>) => {
      if (fn !== "apply_verified_premium_status") {
        throw new Error(`unexpected rpc ${fn}`);
      }
      applied.push(params);
      return Promise.resolve({
        data: overrides.applyResult ?? {
          manual_override: false,
          is_premium: params.p_is_premium,
          subscription_status: params.p_subscription_status,
          premium_expires_at: params.p_premium_expires_at,
          grace_period_until: params.p_grace_period_until,
        },
        error: overrides.applyError ?? null,
      });
    },
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
        };
      }
      if (table === "user_subscriptions") {
        return {
          select: () => ({
            eq: () => ({
              maybeSingle: () =>
                Promise.resolve({
                  data: overrides.subscription ?? null,
                  error: overrides.subscriptionLookupError ?? null,
                }),
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
  const applied: Record<string, unknown>[] = [];
  const response = await createSyncPremiumStatusHandler(
    baseDeps({ createAdminClient: () => makeAdmin({ applied }) }),
  )(authedRequest());

  assertEquals(response.status, 200);
  assertEquals(await response.json(), {
    success: true,
    is_premium: true,
    subscription_status: "premium",
    premium_expires_at: "2026-02-01T00:00:00Z",
    grace_period_until: null,
  });
  assertEquals(applied.length, 1);
  assertEquals(applied[0].p_is_premium, true);
  assertEquals(applied[0].p_subscription_status, "premium");
});

Deno.test("sync-premium-status preserves an active manual premium override", async () => {
  let revenueCatCalls = 0;
  const response = await createSyncPremiumStatusHandler(
    baseDeps({
      createAdminClient: () =>
        makeAdmin({
          subscription: {
            plan: "premium",
            status: "active",
            provider: "manual",
          },
        }),
      fetchSubscriber: () => {
        revenueCatCalls++;
        return Promise.resolve({});
      },
    }),
  )(authedRequest());

  assertEquals(response.status, 200);
  assertEquals(await response.json(), {
    success: true,
    is_premium: true,
    subscription_status: "premium",
    premium_expires_at: null,
    grace_period_until: null,
    manual_override: true,
  });
  assertEquals(revenueCatCalls, 0);
});

Deno.test("sync-premium-status preserves a revoked manual premium override", async () => {
  let revenueCatCalls = 0;
  const response = await createSyncPremiumStatusHandler(
    baseDeps({
      createAdminClient: () =>
        makeAdmin({
          subscription: {
            plan: "premium",
            status: "canceled",
            provider: "manual",
          },
        }),
      fetchSubscriber: () => {
        revenueCatCalls++;
        return Promise.resolve({});
      },
    }),
  )(authedRequest());

  assertEquals(response.status, 200);
  assertEquals(await response.json(), {
    success: true,
    is_premium: false,
    subscription_status: "free",
    premium_expires_at: null,
    grace_period_until: null,
    manual_override: true,
  });
  assertEquals(revenueCatCalls, 0);
});

Deno.test("sync-premium-status fails closed when manual override lookup fails", async () => {
  const response = await createSyncPremiumStatusHandler(
    baseDeps({
      createAdminClient: () =>
        makeAdmin({
          subscriptionLookupError: { message: "lookup failed" },
        }),
    }),
  )(authedRequest());

  assertEquals(response.status, 500);
  assertEquals((await response.json()).error, "Internal server error");
});

Deno.test("sync-premium-status preserves an override created during RevenueCat fetch", async () => {
  const response = await createSyncPremiumStatusHandler(
    baseDeps({
      createAdminClient: () =>
        makeAdmin({
          applyResult: {
            manual_override: true,
            is_premium: false,
            subscription_status: "free",
            premium_expires_at: null,
            grace_period_until: null,
          },
        }),
    }),
  )(authedRequest());

  assertEquals(response.status, 200);
  assertEquals(await response.json(), {
    success: true,
    is_premium: false,
    subscription_status: "free",
    premium_expires_at: null,
    grace_period_until: null,
    manual_override: true,
  });
});

Deno.test("sync-premium-status returns 500 when atomic apply fails", async () => {
  const response = await createSyncPremiumStatusHandler(
    baseDeps({
      createAdminClient: () =>
        makeAdmin({ applyError: { message: "rpc failed" } }),
    }),
  )(authedRequest());

  assertEquals(response.status, 500);
  assertEquals((await response.json()).error, "Internal server error");
});
