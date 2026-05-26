import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  constantTimeEquals,
  parseWebhookEvent,
  shouldRefetchPremium,
  verifyWebhookAuth,
} from "./webhook_core.ts";

// ---------------------------------------------------------------------------
// constantTimeEquals
// ---------------------------------------------------------------------------

Deno.test("constantTimeEquals: equal strings", () => {
  assertEquals(constantTimeEquals("secret", "secret"), true);
});

Deno.test("constantTimeEquals: different strings same length", () => {
  assertEquals(constantTimeEquals("secret", "sxcret"), false);
});

Deno.test("constantTimeEquals: different lengths", () => {
  assertEquals(constantTimeEquals("secret", "secret1"), false);
});

Deno.test("constantTimeEquals: empty strings", () => {
  assertEquals(constantTimeEquals("", ""), true);
});

// ---------------------------------------------------------------------------
// verifyWebhookAuth
// ---------------------------------------------------------------------------

const TOKEN = "a-strong-shared-secret-token";

Deno.test("verifyWebhookAuth: valid Bearer header", () => {
  assertEquals(verifyWebhookAuth(`Bearer ${TOKEN}`, TOKEN), true);
});

Deno.test("verifyWebhookAuth: rejects missing header", () => {
  assertEquals(verifyWebhookAuth(null, TOKEN), false);
});

Deno.test("verifyWebhookAuth: rejects wrong scheme", () => {
  assertEquals(verifyWebhookAuth(`Basic ${TOKEN}`, TOKEN), false);
});

Deno.test("verifyWebhookAuth: rejects empty token", () => {
  assertEquals(verifyWebhookAuth("Bearer ", TOKEN), false);
  assertEquals(verifyWebhookAuth("Bearer    ", TOKEN), false);
});

Deno.test("verifyWebhookAuth: rejects wrong token", () => {
  assertEquals(verifyWebhookAuth(`Bearer ${TOKEN}xx`, TOKEN), false);
  assertEquals(verifyWebhookAuth(`Bearer wrong-secret`, TOKEN), false);
});

Deno.test("verifyWebhookAuth: rejects too-short configured token", () => {
  // 16-char minimum guards against accidentally enabling with a weak secret.
  assertEquals(verifyWebhookAuth(`Bearer short`, "short"), false);
});

// ---------------------------------------------------------------------------
// parseWebhookEvent
// ---------------------------------------------------------------------------

Deno.test("parseWebhookEvent: well-formed RENEWAL event", () => {
  const result = parseWebhookEvent({
    event: {
      type: "RENEWAL",
      app_user_id: "user-uuid-1234",
      id: "evt-abc",
    },
  });
  assertEquals(result, {
    type: "RENEWAL",
    appUserId: "user-uuid-1234",
    eventId: "evt-abc",
    isTest: false,
  });
});

Deno.test("parseWebhookEvent: TEST event without app_user_id is allowed", () => {
  const result = parseWebhookEvent({
    event: { type: "TEST" },
  });
  assertEquals(result?.isTest, true);
  assertEquals(result?.type, "TEST");
  assertEquals(result?.appUserId, "");
});

Deno.test("parseWebhookEvent: lowercases-to-uppercase type", () => {
  const result = parseWebhookEvent({
    event: { type: "initial_purchase", app_user_id: "u1" },
  });
  assertEquals(result?.type, "INITIAL_PURCHASE");
});

Deno.test("parseWebhookEvent: missing event object", () => {
  assertEquals(parseWebhookEvent({}), null);
  assertEquals(parseWebhookEvent(null), null);
  assertEquals(parseWebhookEvent("not an object"), null);
});

Deno.test("parseWebhookEvent: missing type", () => {
  assertEquals(
    parseWebhookEvent({ event: { app_user_id: "u1" } }),
    null,
  );
});

Deno.test("parseWebhookEvent: non-test event missing app_user_id is rejected", () => {
  assertEquals(
    parseWebhookEvent({ event: { type: "RENEWAL" } }),
    null,
  );
  assertEquals(
    parseWebhookEvent({ event: { type: "RENEWAL", app_user_id: "" } }),
    null,
  );
});

Deno.test("parseWebhookEvent: event.id is optional", () => {
  const result = parseWebhookEvent({
    event: { type: "RENEWAL", app_user_id: "u1" },
  });
  assertEquals(result?.eventId, null);
});

// ---------------------------------------------------------------------------
// shouldRefetchPremium
// ---------------------------------------------------------------------------

Deno.test("shouldRefetchPremium: TEST events skipped", () => {
  assertEquals(shouldRefetchPremium("TEST"), false);
});

Deno.test("shouldRefetchPremium: known premium events refetch", () => {
  for (
    const t of [
      "INITIAL_PURCHASE",
      "RENEWAL",
      "CANCELLATION",
      "UNCANCELLATION",
      "EXPIRATION",
      "BILLING_ISSUE",
      "PRODUCT_CHANGE",
      "TRANSFER",
      "SUBSCRIPTION_PAUSED",
      "SUBSCRIPTION_EXTENDED",
      "TEMPORARY_ENTITLEMENT_GRANT",
    ]
  ) {
    assertEquals(shouldRefetchPremium(t), true, `expected refetch for ${t}`);
  }
});

Deno.test("shouldRefetchPremium: unknown events refetch defensively", () => {
  // RC may add new event types over time; safer to refetch than ignore.
  assertEquals(shouldRefetchPremium("HYPOTHETICAL_FUTURE_EVENT"), true);
});
