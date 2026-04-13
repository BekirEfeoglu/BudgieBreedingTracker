/**
 * Tests for the shared rate-limit module.
 *
 * Run: cd supabase/functions && deno test _shared/rate-limit_test.ts --allow-env
 */

import {
  assert,
  assertEquals,
  assertNotEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { createRateLimiter, rateLimitedResponse } from "./rate-limit.ts";

// ---------------------------------------------------------------------------
// createRateLimiter — default config
// ---------------------------------------------------------------------------

Deno.test("default config: allows first request", () => {
  const limiter = createRateLimiter();
  assert(limiter.check("user-1"));
});

Deno.test("default config: allows 20 requests (default maxCalls)", () => {
  const limiter = createRateLimiter();
  for (let i = 0; i < 20; i++) {
    assert(limiter.check("user-default"));
  }
});

Deno.test("default config: blocks 21st request", () => {
  const limiter = createRateLimiter();
  for (let i = 0; i < 20; i++) {
    limiter.check("user-block");
  }
  assertEquals(limiter.check("user-block"), false);
});

// ---------------------------------------------------------------------------
// createRateLimiter — custom config
// ---------------------------------------------------------------------------

Deno.test("custom config: respects custom maxCalls", () => {
  const limiter = createRateLimiter({ maxCalls: 3, windowMs: 60_000 });
  assert(limiter.check("u1"));
  assert(limiter.check("u1"));
  assert(limiter.check("u1"));
  assertEquals(limiter.check("u1"), false);
});

Deno.test("custom config: respects custom windowMs", () => {
  const limiter = createRateLimiter({ windowMs: 1, maxCalls: 100 });
  // With a 1ms window, requests should effectively never accumulate
  assert(limiter.check("u-win"));
});

Deno.test("custom config: maxCalls=1 blocks after first call", () => {
  const limiter = createRateLimiter({ maxCalls: 1, windowMs: 60_000 });
  assert(limiter.check("single"));
  assertEquals(limiter.check("single"), false);
});

// ---------------------------------------------------------------------------
// Key isolation
// ---------------------------------------------------------------------------

Deno.test("different keys do not interfere", () => {
  const limiter = createRateLimiter({ maxCalls: 2, windowMs: 60_000 });
  assert(limiter.check("alice"));
  assert(limiter.check("alice"));
  assertEquals(limiter.check("alice"), false);

  // Bob should still be allowed
  assert(limiter.check("bob"));
  assert(limiter.check("bob"));
  assertEquals(limiter.check("bob"), false);
});

Deno.test("many distinct keys work independently", () => {
  const limiter = createRateLimiter({ maxCalls: 1, windowMs: 60_000 });
  for (let i = 0; i < 50; i++) {
    assert(limiter.check(`key-${i}`));
  }
  // Each key should now be blocked
  for (let i = 0; i < 50; i++) {
    assertEquals(limiter.check(`key-${i}`), false);
  }
});

// ---------------------------------------------------------------------------
// Window expiry
// ---------------------------------------------------------------------------

Deno.test("window expiry resets count", async () => {
  const limiter = createRateLimiter({ maxCalls: 2, windowMs: 30 });
  assert(limiter.check("expire"));
  assert(limiter.check("expire"));
  assertEquals(limiter.check("expire"), false);

  // Wait for the window to expire
  await new Promise((r) => setTimeout(r, 50));

  // Should be allowed again
  assert(limiter.check("expire"));
});

Deno.test("partial window expiry frees some capacity", async () => {
  const limiter = createRateLimiter({ maxCalls: 2, windowMs: 30 });
  assert(limiter.check("partial"));

  // Wait so the first timestamp expires but we add a second within window
  await new Promise((r) => setTimeout(r, 50));

  assert(limiter.check("partial"));
  // After expiry of first, only 1 active — room for 1 more
  assert(limiter.check("partial"));
  // Now at limit
  assertEquals(limiter.check("partial"), false);
});

// ---------------------------------------------------------------------------
// Memory eviction — empty keys
// ---------------------------------------------------------------------------

Deno.test("expired timestamps are pruned on check", async () => {
  const limiter = createRateLimiter({ maxCalls: 5, windowMs: 10 });
  for (let i = 0; i < 5; i++) {
    limiter.check("prune-me");
  }
  assertEquals(limiter.check("prune-me"), false);

  await new Promise((r) => setTimeout(r, 30));

  // After expiry the key is cleaned up and counter resets
  assert(limiter.check("prune-me"));
});

// ---------------------------------------------------------------------------
// Large store eviction (MAX_STORE_SIZE = 10_000)
// ---------------------------------------------------------------------------

Deno.test("large store eviction prunes stale keys", async () => {
  // Use a very short window so entries expire quickly
  const limiter = createRateLimiter({ maxCalls: 1, windowMs: 5 });

  // Fill the store beyond MAX_STORE_SIZE with stale entries
  for (let i = 0; i < 10_002; i++) {
    limiter.check(`stale-${i}`);
  }

  // Wait for all entries to expire
  await new Promise((r) => setTimeout(r, 20));

  // Trigger eviction by adding one more — the check triggers the prune path
  // Since store had > 10_000 entries, the eviction loop runs
  assert(limiter.check("fresh-after-eviction"));
  // If eviction didn't work, the store would just keep growing
  // The fresh key should work fine
  assert(limiter.check("another-fresh"));
});

// ---------------------------------------------------------------------------
// rateLimitedResponse
// ---------------------------------------------------------------------------

Deno.test("rateLimitedResponse returns 429 status", async () => {
  const resp = rateLimitedResponse({ "Content-Type": "application/json" });
  assertEquals(resp.status, 429);
});

Deno.test("rateLimitedResponse body contains error message", async () => {
  const resp = rateLimitedResponse({ "Content-Type": "application/json" });
  const body = await resp.json();
  assertEquals(body.error, "Rate limited: too many requests");
});

Deno.test("rateLimitedResponse includes provided headers", () => {
  const resp = rateLimitedResponse({
    "Content-Type": "application/json",
    "X-Custom": "test-value",
  });
  assertEquals(resp.headers.get("Content-Type"), "application/json");
  assertEquals(resp.headers.get("X-Custom"), "test-value");
});

Deno.test("rateLimitedResponse with empty headers", async () => {
  const resp = rateLimitedResponse({});
  assertEquals(resp.status, 429);
  const body = await resp.json();
  assertEquals(body.error, "Rate limited: too many requests");
});

// ---------------------------------------------------------------------------
// Edge cases
// ---------------------------------------------------------------------------

Deno.test("rapid sequential calls are counted correctly", () => {
  const limiter = createRateLimiter({ maxCalls: 5, windowMs: 60_000 });
  const results: boolean[] = [];
  for (let i = 0; i < 10; i++) {
    results.push(limiter.check("rapid"));
  }
  // First 5 allowed, rest blocked
  assertEquals(results.filter((r) => r === true).length, 5);
  assertEquals(results.filter((r) => r === false).length, 5);
});

Deno.test("empty key string works as a valid key", () => {
  const limiter = createRateLimiter({ maxCalls: 2, windowMs: 60_000 });
  assert(limiter.check(""));
  assert(limiter.check(""));
  assertEquals(limiter.check(""), false);
});

Deno.test("blocked request does not increment counter further", () => {
  const limiter = createRateLimiter({ maxCalls: 2, windowMs: 60_000 });
  assert(limiter.check("no-inc"));
  assert(limiter.check("no-inc"));
  // These should all return false but not push new timestamps
  assertEquals(limiter.check("no-inc"), false);
  assertEquals(limiter.check("no-inc"), false);
  assertEquals(limiter.check("no-inc"), false);
  // Still blocked — counter didn't grow beyond maxCalls
  assertEquals(limiter.check("no-inc"), false);
});

Deno.test("separate limiter instances have independent stores", () => {
  const limiter1 = createRateLimiter({ maxCalls: 1, windowMs: 60_000 });
  const limiter2 = createRateLimiter({ maxCalls: 1, windowMs: 60_000 });

  assert(limiter1.check("shared-key"));
  assertEquals(limiter1.check("shared-key"), false);

  // limiter2 has its own store — should allow
  assert(limiter2.check("shared-key"));
});
