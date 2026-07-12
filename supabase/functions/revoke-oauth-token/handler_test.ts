import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  createRevokeOauthTokenHandler,
  type RevokeOauthTokenDeps,
} from "./handler.ts";

function jsonRequest(body: unknown): Request {
  return new Request("https://example.com/revoke-oauth-token", {
    method: "POST",
    body: JSON.stringify(body),
  });
}

function okFetch(): typeof fetch {
  return (() =>
    Promise.resolve(new Response("", { status: 200 }))) as unknown as
      typeof fetch;
}

function baseDeps(
  overrides: Partial<RevokeOauthTokenDeps> = {},
): RevokeOauthTokenDeps {
  return {
    getAuthenticatedUserId: () => Promise.resolve("user-1"),
    checkRateLimit: () => Promise.resolve(true),
    fetchImpl: okFetch(),
    getAppleClientId: () => "apple-client-id",
    getAppleClientSecret: () => "apple-client-secret",
    ...overrides,
  };
}

Deno.test("revoke-oauth-token rejects missing authentication", async () => {
  const response = await createRevokeOauthTokenHandler(
    baseDeps({ getAuthenticatedUserId: () => Promise.resolve(null) }),
  )(
    jsonRequest({ provider: "google", provider_token: "tok" }),
  );

  assertEquals(response.status, 401);
  assertEquals(await response.json(), { error: "Unauthorized" });
});

Deno.test("revoke-oauth-token rejects malformed body", async () => {
  const response = await createRevokeOauthTokenHandler(baseDeps())(
    jsonRequest({ provider: "google" }), // missing both token fields
  );

  assertEquals(response.status, 400);
  const json = await response.json();
  assertEquals(json.error, "Validation failed");
});

Deno.test("revoke-oauth-token revokes google token on happy path", async () => {
  const response = await createRevokeOauthTokenHandler(baseDeps())(
    jsonRequest({ provider: "google", provider_token: "access-token" }),
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { success: true, provider: "google" });
});
