import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { createValidateFreeTierLimitHandler } from "./handler.ts";

function jsonRequest(body: unknown): Request {
  return new Request("https://example.com/validate-free-tier-limit", {
    method: "POST",
    body: JSON.stringify(body),
  });
}

function makeCountQuery(count: number) {
  const builder: {
    eq: () => typeof builder;
    in: () => typeof builder;
    then: (resolve: (value: { count: number }) => void) => void;
  } = {
    eq: () => builder,
    in: () => builder,
    then: (resolve) => resolve({ count }),
  };
  return builder;
}

function makeAdmin(
  overrides: {
    profile?: Record<string, unknown> | null;
    count?: number;
  } = {},
) {
  const profile = overrides.profile ?? { is_premium: false, role: "member" };
  const count = overrides.count ?? 0;

  return {
    from: (table: string) => {
      if (table === "profiles") {
        return {
          select: () => ({
            eq: () => ({
              single: () => Promise.resolve({ data: profile, error: null }),
            }),
          }),
        };
      }
      return {
        select: () => makeCountQuery(count),
      };
    },
  };
}

function baseDeps(overrides: Record<string, unknown> = {}) {
  return {
    getAuthenticatedUserId: () => Promise.resolve("u1"),
    checkRateLimit: () => Promise.resolve(true),
    createAdminClient: () => makeAdmin(),
    ...overrides,
  };
}

Deno.test("validate-free-tier-limit rejects missing authentication", async () => {
  const response = await createValidateFreeTierLimitHandler(
    baseDeps({ getAuthenticatedUserId: () => Promise.resolve(null) }),
  )(jsonRequest({ table: "birds" }));

  assertEquals(response.status, 401);
  assertEquals(await response.json(), { error: "Unauthorized" });
});

Deno.test("validate-free-tier-limit rejects malformed body", async () => {
  const response = await createValidateFreeTierLimitHandler(baseDeps())(
    jsonRequest({}),
  );

  assertEquals(response.status, 400);
});

Deno.test("validate-free-tier-limit allows under-limit usage", async () => {
  const response = await createValidateFreeTierLimitHandler(
    baseDeps({ createAdminClient: () => makeAdmin({ count: 3 }) }),
  )(jsonRequest({ table: "birds" }));

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { allowed: true, count: 3, limit: 15 });
});

Deno.test("validate-free-tier-limit rejects unknown table (fail-closed)", async () => {
  const response = await createValidateFreeTierLimitHandler(baseDeps())(
    jsonRequest({ table: "not_a_real_table" }),
  );

  assertEquals(response.status, 400);
  assertEquals(await response.json(), {
    allowed: false,
    error: "invalid_table",
  });
});
