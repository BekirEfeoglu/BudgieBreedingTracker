import {
  assertEquals,
  assertThrows,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  authorizePushTargets,
  batch,
  BATCH_SIZE,
  BODY_MAX,
  clampText,
  clampTokens,
  isPermanentFcmTokenError,
  isSuppressedByQuietHours,
  isWithinQuietHours,
  localHourInZone,
  MAX_TOKENS,
  MAX_USER_IDS,
  normalizeData,
  parseFcmErrorStatus,
  type QuietHours,
  resultStatus,
  TITLE_MAX,
  validateUserIdsCount,
} from "./push_core.ts";

// ---------------------------------------------------------------------------
// normalizeData
// ---------------------------------------------------------------------------

Deno.test("normalizeData converts values to strings", () => {
  const r = normalizeData({ data: { a: 1, b: true, c: "hi" } });
  assertEquals(r, { a: "1", b: "true", c: "hi" });
});

Deno.test("normalizeData includes payload when present", () => {
  const r = normalizeData({ payload: "p1", data: { a: 1 } });
  assertEquals(r.payload, "p1");
  assertEquals(r.a, "1");
});

Deno.test("normalizeData with no data/payload returns empty object", () => {
  assertEquals(normalizeData({}), {});
});

// ---------------------------------------------------------------------------
// clampTokens
// ---------------------------------------------------------------------------

Deno.test("clampTokens de-duplicates", () => {
  assertEquals(clampTokens(["a", "a", "b", "b", "c"]), ["a", "b", "c"]);
});

Deno.test("clampTokens preserves order of first occurrence", () => {
  assertEquals(clampTokens(["c", "a", "b", "a"]), ["c", "a", "b"]);
});

Deno.test("clampTokens caps at MAX_TOKENS", () => {
  const huge = Array.from({ length: MAX_TOKENS + 10 }, (_, i) => `t${i}`);
  assertEquals(clampTokens(huge).length, MAX_TOKENS);
});

// ---------------------------------------------------------------------------
// validateUserIdsCount
// ---------------------------------------------------------------------------

Deno.test("validateUserIdsCount accepts at limit", () => {
  validateUserIdsCount(Array.from({ length: MAX_USER_IDS }, (_, i) => `${i}`));
});

Deno.test("validateUserIdsCount rejects over limit", () => {
  assertThrows(() =>
    validateUserIdsCount(
      Array.from({ length: MAX_USER_IDS + 1 }, (_, i) => `${i}`),
    )
  );
});

// ---------------------------------------------------------------------------
// clampText
// ---------------------------------------------------------------------------

Deno.test("clampText trims and enforces max length", () => {
  assertEquals(clampText("  hello  ", 100), "hello");
  assertEquals(
    clampText("a".repeat(TITLE_MAX + 50), TITLE_MAX).length,
    TITLE_MAX,
  );
  assertEquals(clampText("a".repeat(BODY_MAX + 50), BODY_MAX).length, BODY_MAX);
});

// ---------------------------------------------------------------------------
// resultStatus
// ---------------------------------------------------------------------------

Deno.test("resultStatus returns 200 when no failures", () => {
  assertEquals(resultStatus(10, 0), 200);
  assertEquals(resultStatus(0, 0), 200);
});

Deno.test("resultStatus returns 502 when all failed", () => {
  assertEquals(resultStatus(0, 5), 502);
});

Deno.test("resultStatus returns 207 on partial success", () => {
  assertEquals(resultStatus(3, 2), 207);
});

// ---------------------------------------------------------------------------
// batch
// ---------------------------------------------------------------------------

Deno.test("batch splits to exact sizes", () => {
  const items = [1, 2, 3, 4, 5, 6, 7];
  assertEquals(batch(items, 3), [[1, 2, 3], [4, 5, 6], [7]]);
});

Deno.test("batch default size equals BATCH_SIZE", () => {
  const items = Array.from({ length: BATCH_SIZE + 5 }, (_, i) => i);
  const out = batch(items);
  assertEquals(out.length, 2);
  assertEquals(out[0].length, BATCH_SIZE);
  assertEquals(out[1].length, 5);
});

Deno.test("batch rejects non-positive size", () => {
  assertThrows(() => batch([1], 0));
  assertThrows(() => batch([1], -3));
});

Deno.test("batch returns empty array for empty input", () => {
  assertEquals(batch([], 10), []);
});

// ---------------------------------------------------------------------------
// authorizePushTargets (IDOR guard)
// ---------------------------------------------------------------------------

const CALLER = "user-caller";
const OTHER = "user-other";

Deno.test("authorizePushTargets: non-admin pushing to self is allowed", () => {
  assertEquals(
    authorizePushTargets({ userId: CALLER }, CALLER, false),
    null,
  );
  assertEquals(
    authorizePushTargets({ userIds: [CALLER] }, CALLER, false),
    null,
  );
});

Deno.test("authorizePushTargets: non-admin pushing to another user is forbidden", () => {
  const r = authorizePushTargets(
    { userId: OTHER },
    CALLER,
    false,
  );
  assertEquals(typeof r, "string");
  assertEquals((r ?? "").startsWith("forbidden"), true);
});

Deno.test("authorizePushTargets: non-admin with mixed userIds is forbidden", () => {
  const r = authorizePushTargets(
    { userIds: [CALLER, OTHER] },
    CALLER,
    false,
  );
  assertEquals((r ?? "").startsWith("forbidden"), true);
});

Deno.test("authorizePushTargets: raw tokens require admin", () => {
  const r = authorizePushTargets(
    { tokens: ["fcm-token-xyz"] },
    CALLER,
    false,
  );
  assertEquals((r ?? "").includes("raw tokens"), true);
});

Deno.test("authorizePushTargets: admin may push to any user", () => {
  assertEquals(
    authorizePushTargets(
      { userIds: [OTHER, "u3"] },
      CALLER,
      true,
    ),
    null,
  );
});

Deno.test("authorizePushTargets: admin may use raw tokens", () => {
  assertEquals(
    authorizePushTargets(
      { tokens: ["a", "b"] },
      CALLER,
      true,
    ),
    null,
  );
});

Deno.test("authorizePushTargets: empty target set is allowed (no-op)", () => {
  assertEquals(
    authorizePushTargets({}, CALLER, false),
    null,
  );
});

// ---------------------------------------------------------------------------
// Quiet hours (§5.2)
// ---------------------------------------------------------------------------

Deno.test("isWithinQuietHours: same-day window is [start, end)", () => {
  // 01:00-06:00
  assertEquals(isWithinQuietHours(0, 1, 6), false);
  assertEquals(isWithinQuietHours(1, 1, 6), true); // start inclusive
  assertEquals(isWithinQuietHours(5, 1, 6), true);
  assertEquals(isWithinQuietHours(6, 1, 6), false); // end exclusive
  assertEquals(isWithinQuietHours(7, 1, 6), false);
});

Deno.test("isWithinQuietHours: overnight window wraps midnight", () => {
  // 22:00-07:00
  assertEquals(isWithinQuietHours(22, 22, 7), true);
  assertEquals(isWithinQuietHours(23, 22, 7), true);
  assertEquals(isWithinQuietHours(0, 22, 7), true);
  assertEquals(isWithinQuietHours(6, 22, 7), true);
  assertEquals(isWithinQuietHours(7, 22, 7), false); // end exclusive
  assertEquals(isWithinQuietHours(12, 22, 7), false);
});

Deno.test("isWithinQuietHours: start == end is an empty window (off)", () => {
  for (let h = 0; h < 24; h++) {
    assertEquals(isWithinQuietHours(h, 3, 3), false);
  }
});

Deno.test("localHourInZone: converts UTC to the recipient's local hour", () => {
  // Turkey is a fixed UTC+3 (no DST since 2016), so this is deterministic.
  const utc = new Date("2026-07-03T22:30:00Z");
  assertEquals(localHourInZone(utc, "Europe/Istanbul"), 1); // 01:30 local
  assertEquals(localHourInZone(utc, "UTC"), 22);
});

Deno.test("localHourInZone: invalid timezone returns null (fail open)", () => {
  assertEquals(
    localHourInZone(new Date("2026-07-03T22:30:00Z"), "Not/AZone"),
    null,
  );
});

Deno.test("isSuppressedByQuietHours: fails open on missing/disabled/invalid", () => {
  const now = new Date("2026-07-03T22:30:00Z"); // 01:30 in Istanbul
  assertEquals(isSuppressedByQuietHours(null, now), false);
  assertEquals(isSuppressedByQuietHours(undefined, now), false);
  assertEquals(
    isSuppressedByQuietHours(
      { enabled: false, startHour: 0, endHour: 6, timeZone: "Europe/Istanbul" },
      now,
    ),
    false,
  );
  // Invalid hours -> deliver.
  assertEquals(
    isSuppressedByQuietHours(
      { enabled: true, startHour: -1, endHour: 6, timeZone: "Europe/Istanbul" },
      now,
    ),
    false,
  );
  // Invalid timezone -> deliver.
  assertEquals(
    isSuppressedByQuietHours(
      { enabled: true, startHour: 0, endHour: 6, timeZone: "Not/AZone" },
      now,
    ),
    false,
  );
});

Deno.test("isSuppressedByQuietHours: suppresses only inside an enabled window", () => {
  const now = new Date("2026-07-03T22:30:00Z"); // 01:30 in Istanbul
  const inside: QuietHours = {
    enabled: true,
    startHour: 0,
    endHour: 6,
    timeZone: "Europe/Istanbul",
  };
  assertEquals(isSuppressedByQuietHours(inside, now), true);

  const outside: QuietHours = {
    enabled: true,
    startHour: 2,
    endHour: 6,
    timeZone: "Europe/Istanbul",
  };
  // 01:30 local is before the 02:00 start -> deliver.
  assertEquals(isSuppressedByQuietHours(outside, now), false);
});

// ---------------------------------------------------------------------------
// FCM permanent token failures
// ---------------------------------------------------------------------------

Deno.test("parseFcmErrorStatus extracts canonical FCM error status", () => {
  const body = JSON.stringify({
    error: {
      status: "NOT_FOUND",
      details: [
        {
          "@type": "type.googleapis.com/google.firebase.fcm.v1.FcmError",
          errorCode: "UNREGISTERED",
        },
      ],
    },
  });

  assertEquals(parseFcmErrorStatus(body), "UNREGISTERED");
});

Deno.test("isPermanentFcmTokenError marks stale/invalid device tokens", () => {
  assertEquals(isPermanentFcmTokenError("UNREGISTERED"), true);
  assertEquals(isPermanentFcmTokenError("INVALID_ARGUMENT"), true);
  assertEquals(isPermanentFcmTokenError("QUOTA_EXCEEDED"), false);
  assertEquals(isPermanentFcmTokenError(null), false);
});
