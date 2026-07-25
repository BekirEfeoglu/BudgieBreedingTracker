import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  createRevokeOauthTokenHandler,
  type RevokeOauthTokenDeps,
} from "./handler.ts";
import { APPLE_REVOKE_URL } from "./revoke_core.ts";

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

function failingFetch(status: number, body = "provider error"): typeof fetch {
  return (() =>
    Promise.resolve(new Response(body, { status }))) as unknown as typeof fetch;
}

function recordingFetch(
  calls: Array<{ url: string; body: string }>,
): typeof fetch {
  return ((url: string | URL | Request, init?: RequestInit) => {
    calls.push({ url: String(url), body: String(init?.body ?? "") });
    return Promise.resolve(new Response("", { status: 200 }));
  }) as unknown as typeof fetch;
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

Deno.test("revoke-oauth-token revokes apple token when credentials are configured", async () => {
  const calls: Array<{ url: string; body: string }> = [];
  const response = await createRevokeOauthTokenHandler(
    baseDeps({ fetchImpl: recordingFetch(calls) }),
  )(
    jsonRequest({
      provider: "apple",
      provider_refresh_token: "apple-refresh-token",
    }),
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { success: true, provider: "apple" });

  // Routed to Apple (not Google) with the configured credentials and the
  // refresh-token hint Apple requires.
  assertEquals(calls.length, 1);
  assertEquals(calls[0].url, APPLE_REVOKE_URL);
  const params = new URLSearchParams(calls[0].body);
  assertEquals(params.get("client_id"), "apple-client-id");
  assertEquals(params.get("client_secret"), "apple-client-secret");
  assertEquals(params.get("token"), "apple-refresh-token");
  assertEquals(params.get("token_type_hint"), "refresh_token");
});

Deno.test("revoke-oauth-token reports not_configured when apple credentials are unset", async () => {
  const calls: Array<{ url: string; body: string }> = [];
  const response = await createRevokeOauthTokenHandler(
    baseDeps({
      fetchImpl: recordingFetch(calls),
      getAppleClientId: () => undefined,
      getAppleClientSecret: () => undefined,
    }),
  )(
    jsonRequest({ provider: "apple", provider_token: "apple-access-token" }),
  );

  assertEquals(response.status, 500);
  assertEquals(await response.json(), {
    success: false,
    provider: "apple",
    error: "not_configured",
  });
  assertEquals(calls.length, 0);
});

Deno.test("revoke-oauth-token surfaces a failed google revocation as 502", async () => {
  const response = await createRevokeOauthTokenHandler(
    baseDeps({ fetchImpl: failingFetch(400, "invalid_token") }),
  )(
    jsonRequest({ provider: "google", provider_token: "access-token" }),
  );

  assertEquals(response.status, 502);
  assertEquals(await response.json(), {
    success: false,
    provider: "google",
    error: "revocation_failed",
  });
});
