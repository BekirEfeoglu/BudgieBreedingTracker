import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { createMfaLockoutHandler } from "./handler.ts";

function jsonRequest(body: unknown): Request {
  return new Request("https://example.com/mfa-lockout", {
    method: "POST",
    body: JSON.stringify(body),
  });
}

function makeAdmin(
  overrides: { lockout?: Record<string, unknown> | null } = {},
) {
  const lockout = overrides.lockout ?? {
    user_id: "u1",
    failed_attempts: 0,
    locked_until: null,
    last_attempt_at: null,
    lockout_count: 0,
  };

  return {
    from: () => ({
      select: () => ({
        eq: () => ({
          single: () => Promise.resolve({ data: lockout, error: null }),
        }),
      }),
      upsert: () => ({
        select: () => ({
          single: () => Promise.resolve({ data: lockout, error: null }),
        }),
      }),
      update: () => ({
        eq: () => Promise.resolve({ data: null, error: null }),
      }),
    }),
  };
}

function baseDeps(overrides: Record<string, unknown> = {}) {
  return {
    getAuthenticatedUserId: () => Promise.resolve("u1"),
    getAuthenticatorAssuranceLevel: () => "aal2",
    checkRateLimit: () => Promise.resolve(true),
    createAdminClient: () => makeAdmin(),
    now: () => new Date("2026-04-17T12:00:00Z"),
    ...overrides,
  };
}

Deno.test("mfa-lockout rejects missing authentication", async () => {
  const response = await createMfaLockoutHandler(
    baseDeps({ getAuthenticatedUserId: () => Promise.resolve(null) }),
  )(jsonRequest({ action: "check" }));

  assertEquals(response.status, 401);
  assertEquals(await response.json(), { error: "Unauthorized" });
});

Deno.test("mfa-lockout rejects malformed body", async () => {
  const response = await createMfaLockoutHandler(baseDeps())(
    jsonRequest({ action: "not-a-real-action" }),
  );

  assertEquals(response.status, 400);
});

Deno.test("mfa-lockout check happy path returns not locked", async () => {
  const response = await createMfaLockoutHandler(baseDeps())(
    jsonRequest({ action: "check" }),
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { locked: false, remaining_seconds: 0 });
});

Deno.test("mfa-lockout record-failure returns 429 when already locked", async () => {
  const lockedUntil = new Date("2026-04-17T12:05:00Z").toISOString();
  const response = await createMfaLockoutHandler(
    baseDeps({
      createAdminClient: () =>
        makeAdmin({
          lockout: {
            user_id: "u1",
            failed_attempts: 5,
            locked_until: lockedUntil,
            last_attempt_at: "2026-04-17T11:59:00Z",
            lockout_count: 1,
          },
        }),
    }),
  )(jsonRequest({ action: "record-failure" }));

  assertEquals(response.status, 429);
  const body = await response.json();
  assertEquals(body.locked, true);
  assertEquals(body.remaining_seconds, 300);
});

Deno.test("mfa-lockout reset requires aal2", async () => {
  const response = await createMfaLockoutHandler(
    baseDeps({ getAuthenticatorAssuranceLevel: () => "aal1" }),
  )(jsonRequest({ action: "reset" }));

  assertEquals(response.status, 403);
  assertEquals(await response.json(), { error: "mfa_verification_required" });
});
