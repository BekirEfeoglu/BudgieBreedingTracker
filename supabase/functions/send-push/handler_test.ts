import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { createSendPushHandler, type SendPushDeps } from "./handler.ts";

function jsonRequest(body: unknown): Request {
  return new Request("https://example.com/send-push", {
    method: "POST",
    body: JSON.stringify(body),
  });
}

/**
 * Minimal stand-in for the `profiles` quiet-hours lookup:
 * `admin.from("profiles").select("id, quiet_hours").in("id", ids)`.
 */
function quietHoursAdmin(
  rows: Array<{ id: string; quiet_hours: unknown }>,
) {
  return {
    from: (_table: string) => ({
      select: (_columns: string) => ({
        in: (_column: string, _values: string[]) =>
          Promise.resolve({ data: rows, error: null }),
      }),
    }),
  };
}

function baseDeps(overrides: Partial<SendPushDeps> = {}): SendPushDeps {
  return {
    getAuthenticatedUserId: () => Promise.resolve("user-1"),
    requireAdminRole: () => Promise.resolve(false),
    checkRateLimit: () => Promise.resolve(true),
    createAdminClient: () => ({}),
    getProjectId: () => "test-project",
    createAccessToken: () => Promise.resolve("access-token"),
    resolveTokens: () => Promise.resolve(["device-token-1"]),
    sendToFcm: (_accessToken, _projectId, token) =>
      Promise.resolve({ ok: true, token, permanentTokenFailure: false }),
    deactivateFcmTokens: () => Promise.resolve(),
    now: () => new Date("2026-07-12T12:00:00Z"),
    ...overrides,
  };
}

Deno.test("send-push rejects missing authentication", async () => {
  const response = await createSendPushHandler(
    baseDeps({ getAuthenticatedUserId: () => Promise.resolve(null) }),
  )(
    jsonRequest({
      userId: "user-1",
      title: "Hello",
      body: "World",
    }),
  );

  assertEquals(response.status, 401);
  assertEquals(await response.json(), { error: "Unauthorized" });
});

Deno.test("send-push rejects invalid/malformed body", async () => {
  const response = await createSendPushHandler(baseDeps())(
    jsonRequest({ userId: "user-1" }), // missing required title/body
  );

  assertEquals(response.status, 400);
  const json = await response.json();
  assertEquals(json.error, "Validation failed");
});

Deno.test("send-push delivers to self on happy path", async () => {
  const response = await createSendPushHandler(baseDeps())(
    jsonRequest({
      userId: "user-1",
      title: "Hello",
      body: "World",
    }),
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { success: 1, failure: 0 });
});

// --- Authorization wiring -------------------------------------------------
// `authorizePushTargets` is unit-tested in push_test.ts, but these assert the
// handler actually CALLS it: deleting the call would leave every non-admin
// caller able to push to arbitrary users / raw device tokens.

Deno.test("send-push rejects a non-admin caller targeting another user", async () => {
  let sendCalls = 0;
  const response = await createSendPushHandler(
    baseDeps({
      sendToFcm: (_accessToken, _projectId, token) => {
        sendCalls++;
        return Promise.resolve({
          ok: true,
          token,
          permanentTokenFailure: false,
        });
      },
    }),
  )(
    jsonRequest({
      userIds: ["some-other-user"],
      title: "Hello",
      body: "World",
    }),
  );

  assertEquals(response.status, 403);
  assertEquals(await response.json(), {
    error: "forbidden: non-admin caller may only push to self",
  });
  assertEquals(sendCalls, 0);
});

Deno.test("send-push rejects raw tokens from a non-admin caller", async () => {
  let sendCalls = 0;
  const response = await createSendPushHandler(
    baseDeps({
      sendToFcm: (_accessToken, _projectId, token) => {
        sendCalls++;
        return Promise.resolve({
          ok: true,
          token,
          permanentTokenFailure: false,
        });
      },
    }),
  )(
    jsonRequest({
      tokens: ["raw-token"],
      title: "Hello",
      body: "World",
    }),
  );

  assertEquals(response.status, 403);
  assertEquals(await response.json(), {
    error: "forbidden: raw tokens require admin role",
  });
  assertEquals(sendCalls, 0);
});

// --- Quiet hours wiring (§5.2) --------------------------------------------
// Opt-in only: `respectQuietHours` must actually drive the profiles lookup and
// drop suppressed recipients before any FCM call.

Deno.test("send-push suppresses a recipient inside their quiet-hours window", async () => {
  let sendCalls = 0;
  let resolveCalls = 0;
  const response = await createSendPushHandler(
    baseDeps({
      // now() is 12:00 UTC -> inside [10, 14) in the recipient's zone.
      createAdminClient: () =>
        quietHoursAdmin([
          {
            id: "user-1",
            quiet_hours: {
              enabled: true,
              startHour: 10,
              endHour: 14,
              timeZone: "UTC",
            },
          },
        ]),
      resolveTokens: () => {
        resolveCalls++;
        return Promise.resolve(["device-token-1"]);
      },
      sendToFcm: (_accessToken, _projectId, token) => {
        sendCalls++;
        return Promise.resolve({
          ok: true,
          token,
          permanentTokenFailure: false,
        });
      },
    }),
  )(
    jsonRequest({
      userId: "user-1",
      title: "Hello",
      body: "World",
      respectQuietHours: true,
    }),
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), {
    success: 0,
    failure: 0,
    suppressed: 1,
  });
  assertEquals(sendCalls, 0);
  assertEquals(resolveCalls, 0);
});

Deno.test("send-push delivers when the recipient is outside their quiet-hours window", async () => {
  let sendCalls = 0;
  const response = await createSendPushHandler(
    baseDeps({
      // now() is 12:00 UTC -> outside the overnight [22, 24) u [0, 7) window.
      createAdminClient: () =>
        quietHoursAdmin([
          {
            id: "user-1",
            quiet_hours: {
              enabled: true,
              startHour: 22,
              endHour: 7,
              timeZone: "UTC",
            },
          },
        ]),
      sendToFcm: (_accessToken, _projectId, token) => {
        sendCalls++;
        return Promise.resolve({
          ok: true,
          token,
          permanentTokenFailure: false,
        });
      },
    }),
  )(
    jsonRequest({
      userId: "user-1",
      title: "Hello",
      body: "World",
      respectQuietHours: true,
    }),
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { success: 1, failure: 0 });
  assertEquals(sendCalls, 1);
});
