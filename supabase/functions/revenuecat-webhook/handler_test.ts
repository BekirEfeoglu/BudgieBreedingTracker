import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  createRevenueCatWebhookHandler,
  type RevenueCatWebhookDeps,
} from "./handler.ts";

const TOKEN = "a-strong-shared-secret-token-1234";
const APP_USER_ID = "00000000-0000-7000-8000-000000000111";
const FIXED_NOW = new Date("2026-01-01T00:00:00Z");

function webhookRequest(
  opts: {
    method?: string;
    authorization?: string;
    rawBody?: string;
    body?: unknown;
  } = {},
): Request {
  const headers = new Headers();
  headers.set("Authorization", opts.authorization ?? `Bearer ${TOKEN}`);
  const method = opts.method ?? "POST";
  const init: RequestInit = { method, headers };
  if (method !== "GET" && method !== "HEAD") {
    init.body = opts.rawBody ?? JSON.stringify(opts.body ?? {});
  }
  return new Request("https://example.com/revenuecat-webhook", init);
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
    ? { id: APP_USER_ID, role: null }
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
              maybeSingle: () =>
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
  overrides: Partial<RevenueCatWebhookDeps> = {},
): RevenueCatWebhookDeps {
  return {
    getWebhookAuthToken: () => TOKEN,
    getEntitlementId: () => "premium",
    createAdminClient: () => makeAdmin(),
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

Deno.test("revenuecat-webhook rejects non-POST requests", async () => {
  const response = await createRevenueCatWebhookHandler(baseDeps())(
    webhookRequest({ method: "GET" }),
  );
  assertEquals(response.status, 405);
});

Deno.test("revenuecat-webhook rejects missing/short shared secret", async () => {
  const response = await createRevenueCatWebhookHandler(
    baseDeps({ getWebhookAuthToken: () => "short" }),
  )(webhookRequest({ authorization: "Bearer short" }));

  assertEquals(response.status, 500);
  assertEquals((await response.json()).error, "Server misconfigured");
});

Deno.test("revenuecat-webhook rejects bad auth header", async () => {
  const response = await createRevenueCatWebhookHandler(baseDeps())(
    webhookRequest({ authorization: "Bearer wrong-secret" }),
  );

  assertEquals(response.status, 401);
  assertEquals((await response.json()).error, "Unauthorized");
});

Deno.test("revenuecat-webhook rejects invalid JSON body", async () => {
  const response = await createRevenueCatWebhookHandler(baseDeps())(
    webhookRequest({ rawBody: "{not valid json" }),
  );

  assertEquals(response.status, 400);
  assertEquals((await response.json()).error, "Invalid JSON");
});

Deno.test("revenuecat-webhook rejects malformed event payload", async () => {
  const response = await createRevenueCatWebhookHandler(baseDeps())(
    webhookRequest({ body: { event: { app_user_id: APP_USER_ID } } }),
  );

  assertEquals(response.status, 400);
  assertEquals((await response.json()).error, "Malformed event payload");
});

Deno.test("revenuecat-webhook acks TEST event with 200", async () => {
  const response = await createRevenueCatWebhookHandler(baseDeps())(
    webhookRequest({ body: { event: { type: "TEST" } } }),
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { success: true, test: true });
});

Deno.test("revenuecat-webhook returns retryable 503 on internal error", async () => {
  const response = await createRevenueCatWebhookHandler(
    baseDeps({
      createAdminClient: () =>
        makeAdmin({
          applyError: { message: "db exploded" },
        }),
    }),
  )(
    webhookRequest({
      body: {
        event: { type: "RENEWAL", app_user_id: APP_USER_ID, id: "evt-1" },
      },
    }),
  );

  assertEquals(response.status, 503);
  assertEquals(response.headers.get("Retry-After"), "60");
  assertEquals(await response.json(), {
    success: false,
    error: "internal_error",
  });
});

Deno.test("revenuecat-webhook syncs premium status on happy path", async () => {
  const applied: Record<string, unknown>[] = [];
  const response = await createRevenueCatWebhookHandler(
    baseDeps({ createAdminClient: () => makeAdmin({ applied }) }),
  )(
    webhookRequest({
      body: {
        event: { type: "RENEWAL", app_user_id: APP_USER_ID, id: "evt-1" },
      },
    }),
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), {
    success: true,
    type: "RENEWAL",
    is_premium: true,
  });
  assertEquals(applied.length, 1);
  assertEquals(applied[0].p_is_premium, true);
  assertEquals(applied[0].p_subscription_status, "premium");
});

Deno.test("revenuecat-webhook preserves an active manual premium override", async () => {
  let revenueCatCalls = 0;
  const response = await createRevenueCatWebhookHandler(
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
  )(
    webhookRequest({
      body: {
        event: { type: "RENEWAL", app_user_id: APP_USER_ID, id: "evt-1" },
      },
    }),
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), {
    success: true,
    type: "RENEWAL",
    is_premium: true,
    manual_override: true,
  });
  assertEquals(revenueCatCalls, 0);
});

Deno.test("revenuecat-webhook preserves a revoked manual premium override", async () => {
  let revenueCatCalls = 0;
  const response = await createRevenueCatWebhookHandler(
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
  )(
    webhookRequest({
      body: {
        event: { type: "RENEWAL", app_user_id: APP_USER_ID, id: "evt-1" },
      },
    }),
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), {
    success: true,
    type: "RENEWAL",
    is_premium: false,
    manual_override: true,
  });
  assertEquals(revenueCatCalls, 0);
});

Deno.test("revenuecat-webhook fails closed when manual override lookup fails", async () => {
  const response = await createRevenueCatWebhookHandler(
    baseDeps({
      createAdminClient: () =>
        makeAdmin({
          subscriptionLookupError: { message: "lookup failed" },
        }),
    }),
  )(
    webhookRequest({
      body: {
        event: { type: "RENEWAL", app_user_id: APP_USER_ID, id: "evt-1" },
      },
    }),
  );

  assertEquals(response.status, 503);
  assertEquals(await response.json(), {
    success: false,
    error: "internal_error",
  });
});

Deno.test("revenuecat-webhook retries when profile creation races the event", async () => {
  const response = await createRevenueCatWebhookHandler(
    baseDeps({
      createAdminClient: () => makeAdmin({ profile: null }),
    }),
  )(
    webhookRequest({
      body: {
        event: {
          type: "INITIAL_PURCHASE",
          app_user_id: APP_USER_ID,
          id: "evt-race",
        },
      },
    }),
  );

  assertEquals(response.status, 503);
  assertEquals(response.headers.get("Retry-After"), "60");
  assertEquals(await response.json(), { success: false, unknown_user: true });
});

Deno.test("revenuecat-webhook preserves an override created during RevenueCat fetch", async () => {
  const response = await createRevenueCatWebhookHandler(
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
  )(
    webhookRequest({
      body: {
        event: { type: "RENEWAL", app_user_id: APP_USER_ID, id: "evt-1" },
      },
    }),
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), {
    success: true,
    type: "RENEWAL",
    is_premium: false,
    manual_override: true,
  });
});
