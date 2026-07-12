import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { createModerateContentHandler } from "./handler.ts";

function jsonRequest(body: unknown): Request {
  return new Request("https://example.com/moderate-content", {
    method: "POST",
    body: JSON.stringify(body),
  });
}

function malformedRequest(): Request {
  return new Request("https://example.com/moderate-content", {
    method: "POST",
    body: "{not valid json",
  });
}

function baseDeps(overrides: Record<string, unknown> = {}) {
  return {
    getAuthenticatedUserId: () => Promise.resolve("test-user"),
    checkRateLimit: () => Promise.resolve(true),
    moderateText: () => ({ allowed: true }),
    ...overrides,
  };
}

Deno.test("moderate-content rejects missing/invalid authentication", async () => {
  const response = await createModerateContentHandler(
    baseDeps({ getAuthenticatedUserId: () => Promise.resolve(null) }),
  )(jsonRequest({ text: "Hello budgie" }));

  assertEquals(response.status, 401);
  assertEquals(await response.json(), {
    allowed: false,
    reason: "unauthorized",
  });
});

Deno.test("moderate-content rejects malformed body", async () => {
  const response = await createModerateContentHandler(baseDeps())(
    malformedRequest(),
  );

  assertEquals(response.status, 400);
});

Deno.test("moderate-content fails closed on internal moderation error", async () => {
  const response = await createModerateContentHandler(
    baseDeps({
      moderateText: () => {
        throw new Error("moderation engine exploded");
      },
    }),
  )(jsonRequest({ text: "My budgie laid 4 eggs today!" }));

  assertEquals(response.status, 503);
  assertEquals(await response.json(), {
    allowed: false,
    reason: "moderation_unavailable",
  });
});

Deno.test("moderate-content allows clean content", async () => {
  const response = await createModerateContentHandler(baseDeps())(
    jsonRequest({ text: "My budgie laid 4 eggs today!" }),
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { allowed: true });
});
