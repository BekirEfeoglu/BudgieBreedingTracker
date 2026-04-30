import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { resolvePremiumStatus } from "./premium_core.ts";

const now = new Date("2026-05-01T12:00:00.000Z");

Deno.test("resolvePremiumStatus: active premium entitlement", () => {
  const result = resolvePremiumStatus({
    subscriber: {
      entitlements: {
        premium: {
          expires_date: "2026-06-01T12:00:00Z",
          product_identifier: "premium_yearly",
        },
      },
    },
  }, now);

  assertEquals(result.isPremium, true);
  assertEquals(result.subscriptionStatus, "premium");
  assertEquals(result.subscriptionRecordStatus, "active");
  assertEquals(result.expiresAt, "2026-06-01T12:00:00Z");
  assertEquals(result.gracePeriodUntil, null);
  assertEquals(result.productIdentifier, "premium_yearly");
});

Deno.test("resolvePremiumStatus: lifetime entitlement", () => {
  const result = resolvePremiumStatus({
    subscriber: {
      entitlements: {
        premium: {
          expires_date: null,
          product_identifier: "lifetime",
        },
      },
    },
  }, now);

  assertEquals(result.isPremium, true);
  assertEquals(result.expiresAt, null);
  assertEquals(result.productIdentifier, "lifetime");
});

Deno.test("resolvePremiumStatus: expired entitlement keeps app grace window", () => {
  const result = resolvePremiumStatus({
    subscriber: {
      entitlements: {
        premium: {
          expires_date: "2026-04-20T12:00:00Z",
          product_identifier: "premium_monthly",
        },
      },
    },
  }, now);

  assertEquals(result.isPremium, false);
  assertEquals(result.subscriptionStatus, "free");
  assertEquals(result.subscriptionRecordStatus, "expired");
  assertEquals(result.gracePeriodUntil, "2026-05-20T12:00:00.000Z");
});

Deno.test("resolvePremiumStatus: RevenueCat grace date wins", () => {
  const result = resolvePremiumStatus({
    subscriber: {
      entitlements: {
        premium: {
          expires_date: "2026-04-20T12:00:00Z",
          grace_period_expires_date: "2026-05-05T12:00:00Z",
          product_identifier: "premium_monthly",
        },
      },
    },
  }, now);

  assertEquals(result.isPremium, false);
  assertEquals(result.gracePeriodUntil, "2026-05-05T12:00:00.000Z");
});

Deno.test("resolvePremiumStatus: missing entitlement is free", () => {
  const result = resolvePremiumStatus({
    subscriber: {
      entitlements: {},
    },
  }, now);

  assertEquals(result.isPremium, false);
  assertEquals(result.subscriptionStatus, "free");
  assertEquals(result.expiresAt, null);
  assertEquals(result.gracePeriodUntil, null);
});
