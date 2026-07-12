import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { createSendPushHandler, type SendPushDeps } from "./handler.ts";

function jsonRequest(body: unknown): Request {
  return new Request("https://example.com/send-push", {
    method: "POST",
    body: JSON.stringify(body),
  });
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
