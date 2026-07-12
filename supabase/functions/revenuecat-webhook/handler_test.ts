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
  profileUpdateError?: { message: string } | null;
  subscriptionError?: { message: string } | null;
  updated?: Record<string, unknown>[];
} = {}) {
  const updated = overrides.updated ?? [];
  const profile = overrides.profile === undefined
    ? { id: APP_USER_ID, role: null }
    : overrides.profile;

  return {
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

Deno.test("revenuecat-webhook returns 200 success:false on internal error (no retry storm)", async () => {
  const response = await createRevenueCatWebhookHandler(
    baseDeps({
      createAdminClient: () =>
        makeAdmin({
          profileUpdateError: { message: "db exploded" },
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
    success: false,
    error: "internal_error",
  });
});

Deno.test("revenuecat-webhook syncs premium status on happy path", async () => {
  const updated: Record<string, unknown>[] = [];
  const response = await createRevenueCatWebhookHandler(
    baseDeps({ createAdminClient: () => makeAdmin({ updated }) }),
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
  assertEquals(updated.length, 1);
  assertEquals(updated[0].is_premium, true);
});
