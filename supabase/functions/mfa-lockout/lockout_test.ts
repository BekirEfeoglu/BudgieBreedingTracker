import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  computeFailureUpdate,
  computeResetCount,
  getLockoutDuration,
  isLockedOut,
  LOCKOUT_DECAY_HOURS,
  LOCKOUT_TIERS,
  MAX_ATTEMPTS,
  type LockoutRow,
} from "./lockout_core.ts";

const now = new Date("2026-04-17T12:00:00Z");

function row(partial: Partial<LockoutRow> = {}): LockoutRow {
  return {
    user_id: "u1",
    failed_attempts: 0,
    locked_until: null,
    last_attempt_at: null,
    lockout_count: 0,
    ...partial,
  };
}

// ---------------------------------------------------------------------------
// isLockedOut
// ---------------------------------------------------------------------------

Deno.test("isLockedOut returns false when no lockout row", () => {
  assertEquals(isLockedOut(null, now).locked, false);
  assertEquals(isLockedOut(undefined, now).locked, false);
});

Deno.test("isLockedOut returns false when locked_until is null", () => {
  assertEquals(isLockedOut({ locked_until: null }, now).locked, false);
});

Deno.test("isLockedOut returns true when locked_until is in the future", () => {
  const future = new Date(now.getTime() + 60_000).toISOString();
  const result = isLockedOut({ locked_until: future }, now);
  assertEquals(result.locked, true);
  assertEquals(result.remaining_seconds, 60);
});

Deno.test("isLockedOut returns false when locked_until has passed", () => {
  const past = new Date(now.getTime() - 1_000).toISOString();
  assertEquals(isLockedOut({ locked_until: past }, now).locked, false);
});

Deno.test("isLockedOut rounds remaining seconds up", () => {
  const future = new Date(now.getTime() + 1_500).toISOString();
  assertEquals(isLockedOut({ locked_until: future }, now).remaining_seconds, 2);
});

// ---------------------------------------------------------------------------
// getLockoutDuration tiers
// ---------------------------------------------------------------------------

Deno.test("getLockoutDuration uses first tier for count 0", () => {
  assertEquals(getLockoutDuration(0), 120);
});

Deno.test("getLockoutDuration advances through tiers", () => {
  assertEquals(getLockoutDuration(1), 300);
  assertEquals(getLockoutDuration(2), 900);
  assertEquals(getLockoutDuration(3), 3600);
});

Deno.test("getLockoutDuration caps at last tier for high counts", () => {
  assertEquals(getLockoutDuration(10), 3600);
  assertEquals(getLockoutDuration(999), 3600);
});

Deno.test("getLockoutDuration clamps negative input to first tier", () => {
  assertEquals(getLockoutDuration(-5), 120);
});

Deno.test("LOCKOUT_TIERS are monotonically non-decreasing", () => {
  for (let i = 1; i < LOCKOUT_TIERS.length; i++) {
    assertEquals(LOCKOUT_TIERS[i] >= LOCKOUT_TIERS[i - 1], true);
  }
});

// ---------------------------------------------------------------------------
// computeFailureUpdate
// ---------------------------------------------------------------------------

Deno.test("failure below threshold increments attempts without locking", () => {
  const r = computeFailureUpdate(row({ failed_attempts: 2 }), now);
  assertEquals(r.locked, false);
  assertEquals(r.failed_attempts, 3);
  assertEquals(r.lockout_count, 0);
  assertEquals(r.locked_until, null);
});

Deno.test("failure reaching MAX_ATTEMPTS triggers lockout", () => {
  const r = computeFailureUpdate(
    row({ failed_attempts: MAX_ATTEMPTS - 1, lockout_count: 0 }),
    now,
  );
  assertEquals(r.locked, true);
  assertEquals(r.remaining_seconds, LOCKOUT_TIERS[0]);
  assertEquals(r.lockout_count, 1);
  assertEquals(r.failed_attempts, MAX_ATTEMPTS);
  assertEquals(r.locked_until !== null, true);
});

Deno.test("consecutive lockouts escalate tier", () => {
  const r = computeFailureUpdate(
    row({ failed_attempts: MAX_ATTEMPTS - 1, lockout_count: 2 }),
    now,
  );
  assertEquals(r.locked, true);
  assertEquals(r.remaining_seconds, LOCKOUT_TIERS[2]);
  assertEquals(r.lockout_count, 3);
});

Deno.test("expired prior lockout resets attempts before counting failure", () => {
  const pastLock = new Date(now.getTime() - 1000).toISOString();
  const r = computeFailureUpdate(
    row({
      failed_attempts: MAX_ATTEMPTS, // stale
      locked_until: pastLock,
      lockout_count: 1,
    }),
    now,
  );
  assertEquals(r.locked, false);
  assertEquals(r.failed_attempts, 1);
});

Deno.test("null failed_attempts treated as zero", () => {
  const r = computeFailureUpdate(row({ failed_attempts: null }), now);
  assertEquals(r.failed_attempts, 1);
});

// ---------------------------------------------------------------------------
// computeResetCount (decay)
// ---------------------------------------------------------------------------

Deno.test("reset without prior activity keeps count unchanged", () => {
  assertEquals(computeResetCount(null, now), 0);
});

Deno.test("reset within decay window keeps count unchanged", () => {
  const recent = new Date(
    now.getTime() - (LOCKOUT_DECAY_HOURS - 1) * 3600 * 1000,
  ).toISOString();
  const r = computeResetCount(
    { lockout_count: 3, last_attempt_at: recent },
    now,
  );
  assertEquals(r, 3);
});

Deno.test("reset past decay window decrements count by one", () => {
  const longAgo = new Date(
    now.getTime() - (LOCKOUT_DECAY_HOURS + 1) * 3600 * 1000,
  ).toISOString();
  const r = computeResetCount(
    { lockout_count: 3, last_attempt_at: longAgo },
    now,
  );
  assertEquals(r, 2);
});

Deno.test("reset does not decrement below zero", () => {
  const longAgo = new Date(
    now.getTime() - (LOCKOUT_DECAY_HOURS + 1) * 3600 * 1000,
  ).toISOString();
  const r = computeResetCount(
    { lockout_count: 0, last_attempt_at: longAgo },
    now,
  );
  assertEquals(r, 0);
});

Deno.test("decay window equals 7 days (security invariant)", () => {
  assertEquals(LOCKOUT_DECAY_HOURS, 168);
});
