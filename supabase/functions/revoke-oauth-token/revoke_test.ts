import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  APPLE_REVOKE_URL,
  appleRevokeParams,
  GOOGLE_REVOKE_URL,
  googleRevokeBody,
  isRefreshToken,
  pickToken,
} from "./revoke_core.ts";

Deno.test("pickToken prefers provider_token over refresh token", () => {
  const token = pickToken({
    provider: "google",
    provider_token: "access",
    provider_refresh_token: "refresh",
  });
  assertEquals(token, "access");
});

Deno.test("pickToken falls back to refresh token when access token is absent", () => {
  const token = pickToken({
    provider: "apple",
    provider_refresh_token: "refresh",
  });
  assertEquals(token, "refresh");
});

Deno.test("pickToken returns null when no token present", () => {
  assertEquals(pickToken({ provider: "google" }), null);
});

Deno.test("isRefreshToken only when refresh-only input", () => {
  assertEquals(
    isRefreshToken({ provider: "apple", provider_refresh_token: "r" }),
    true,
  );
  assertEquals(
    isRefreshToken({ provider: "apple", provider_token: "a" }),
    false,
  );
  assertEquals(
    isRefreshToken({
      provider: "apple",
      provider_token: "a",
      provider_refresh_token: "r",
    }),
    false,
  );
});

Deno.test("googleRevokeBody URL-encodes the token", () => {
  assertEquals(googleRevokeBody("abc 123"), "token=abc%20123");
  assertEquals(googleRevokeBody("a/b=c"), "token=a%2Fb%3Dc");
});

Deno.test("appleRevokeParams includes all required fields", () => {
  const params = appleRevokeParams("tok", "client-id", "secret", false);
  assertEquals(params.get("client_id"), "client-id");
  assertEquals(params.get("client_secret"), "secret");
  assertEquals(params.get("token"), "tok");
  assertEquals(params.get("token_type_hint"), "access_token");
});

Deno.test("appleRevokeParams sets refresh_token hint when refresh=true", () => {
  const params = appleRevokeParams("tok", "c", "s", true);
  assertEquals(params.get("token_type_hint"), "refresh_token");
});

Deno.test("provider URLs are hardcoded to HTTPS", () => {
  assertEquals(GOOGLE_REVOKE_URL.startsWith("https://"), true);
  assertEquals(APPLE_REVOKE_URL.startsWith("https://"), true);
});
