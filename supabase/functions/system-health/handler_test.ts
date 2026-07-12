import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  createSystemHealthHandler,
  type SystemHealthDeps,
} from "./handler.ts";

function postRequest(): Request {
  return new Request("https://example.com/system-health", {
    method: "POST",
    body: JSON.stringify({}),
  });
}

function healthyAdmin() {
  return {
    from: () => ({
      select: () => Promise.resolve({ error: null }),
    }),
    auth: {
      admin: {
        listUsers: () => Promise.resolve({ error: null }),
      },
    },
    storage: {
      listBuckets: () => Promise.resolve({ error: null }),
    },
  };
}

function baseDeps(
  overrides: Partial<SystemHealthDeps> = {},
): SystemHealthDeps {
  return {
    getAuthenticatedUserId: () => Promise.resolve("user-1"),
    requireAdminRole: () => Promise.resolve(true),
    checkRateLimit: () => Promise.resolve(true),
    createAdminClient: () => healthyAdmin(),
    now: () => new Date("2026-07-12T12:00:00Z"),
    ...overrides,
  };
}

Deno.test("system-health rejects missing authentication", async () => {
  const response = await createSystemHealthHandler(
    baseDeps({ getAuthenticatedUserId: () => Promise.resolve(null) }),
  )(postRequest());

  assertEquals(response.status, 401);
  assertEquals(await response.json(), { error: "Unauthorized" });
});

Deno.test("system-health rejects non-admin authenticated user", async () => {
  const response = await createSystemHealthHandler(
    baseDeps({ requireAdminRole: () => Promise.resolve(false) }),
  )(postRequest());

  assertEquals(response.status, 403);
  assertEquals(await response.json(), { error: "Forbidden" });
});

Deno.test("system-health returns snapshot for admin on happy path", async () => {
  const response = await createSystemHealthHandler(baseDeps())(
    postRequest(),
  );

  assertEquals(response.status, 200);
  const json = await response.json();
  assertEquals(json.status, "ok");
  assertEquals(json.checks, { database: "ok", auth: "ok", storage: "ok" });
  assertEquals(json.timestamp, "2026-07-12T12:00:00.000Z");
});
