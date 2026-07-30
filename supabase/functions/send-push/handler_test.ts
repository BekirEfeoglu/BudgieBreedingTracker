import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  createSendPushHandler,
  resolvePersistedMessagePush,
  type SendPushDeps,
} from "./handler.ts";
import type { PushRequest } from "./push_core.ts";

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
    createAdminClient: () => quietHoursAdmin([]),
    resolveMessagePush: () =>
      Promise.resolve({
        request: {
          userIds: ["user-2"],
          title: "Sender",
          body: "Hello",
          payload: "message:0194e2d0-cf4d-7000-8000-000000000001",
          respectQuietHours: true,
        },
      }),
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

Deno.test("send-push derives message recipients server-side", async () => {
  let resolvedMessageId: string | null = null;
  const deliveredRequests: PushRequest[] = [];
  const messageId = "0194e2d0-cf4d-7000-8000-000000000002";
  const response = await createSendPushHandler(
    baseDeps({
      resolveMessagePush: (id) => {
        resolvedMessageId = id;
        return Promise.resolve({
          request: {
            userIds: ["user-2"],
            title: "Sender",
            body: "Hello",
            payload: "message:0194e2d0-cf4d-7000-8000-000000000001",
            respectQuietHours: true,
          },
        });
      },
      sendToFcm: (_accessToken, _projectId, token, request) => {
        deliveredRequests.push(request);
        return Promise.resolve({
          ok: true,
          token,
          permanentTokenFailure: false,
        });
      },
    }),
  )(jsonRequest({ messageId }));

  assertEquals(response.status, 200);
  assertEquals(resolvedMessageId, messageId);
  assertEquals(deliveredRequests[0].userIds, ["user-2"]);
  assertEquals(
    deliveredRequests[0].payload,
    "message:0194e2d0-cf4d-7000-8000-000000000001",
  );
  assertEquals(deliveredRequests[0].respectQuietHours, true);
});

Deno.test("send-push rejects a message not owned by the caller", async () => {
  let sendCalls = 0;
  const response = await createSendPushHandler(
    baseDeps({
      resolveMessagePush: () =>
        Promise.resolve({ error: "Forbidden", status: 403 }),
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
      messageId: "0194e2d0-cf4d-7000-8000-000000000002",
    }),
  );

  assertEquals(response.status, 403);
  assertEquals(await response.json(), { error: "Forbidden" });
  assertEquals(sendCalls, 0);
});

Deno.test("send-push rejects mixed message and caller-supplied targets", async () => {
  const response = await createSendPushHandler(baseDeps())(
    jsonRequest({
      messageId: "0194e2d0-cf4d-7000-8000-000000000002",
      userIds: ["victim"],
      title: "Forged",
      body: "Forged",
    }),
  );

  assertEquals(response.status, 400);
});

Deno.test("message push resolution filters inactive and muted participants", async () => {
  const filters: Array<[string, string, unknown]> = [];
  const admin = {
    from: (table: string) => {
      if (table === "messages") {
        return {
          select: (_columns: string) => ({
            eq: (_column: string, _value: unknown) => ({
              maybeSingle: () =>
                Promise.resolve({
                  data: {
                    id: "message-1",
                    conversation_id: "0194e2d0-cf4d-7000-8000-000000000001",
                    sender_id: "user-1",
                    sender_name: "Sender",
                    content: "Hello",
                    message_type: "text",
                  },
                  error: null,
                }),
            }),
          }),
        };
      }
      return {
        select: (_columns: string) => ({
          eq(column1: string, value1: unknown) {
            filters.push(["eq", column1, value1]);
            return {
              eq(column2: string, value2: unknown) {
                filters.push(["eq", column2, value2]);
                return {
                  eq(column3: string, value3: unknown) {
                    filters.push(["eq", column3, value3]);
                    return {
                      neq(column4: string, value4: unknown) {
                        filters.push(["neq", column4, value4]);
                        return Promise.resolve({
                          data: [{ user_id: "user-2" }, { user_id: "user-3" }],
                          error: null,
                        });
                      },
                    };
                  },
                };
              },
            };
          },
        }),
      };
    },
  };

  const resolved = await resolvePersistedMessagePush(
    "0194e2d0-cf4d-7000-8000-000000000002",
    "user-1",
    admin,
  );

  assertEquals(resolved.request?.userIds, ["user-2", "user-3"]);
  assertEquals(resolved.request?.title, "BudgieBreedingTracker");
  assertEquals(resolved.request?.body, "💬");
  assertEquals(resolved.request?.respectQuietHours, true);
  assertEquals(filters, [
    [
      "eq",
      "conversation_id",
      "0194e2d0-cf4d-7000-8000-000000000001",
    ],
    ["eq", "is_left", false],
    ["eq", "is_muted", false],
    ["neq", "user_id", "user-1"],
  ]);
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
