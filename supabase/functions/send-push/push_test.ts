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
  MAX_TOKENS,
  MAX_USER_IDS,
  normalizeData,
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
  assertEquals(clampText("a".repeat(TITLE_MAX + 50), TITLE_MAX).length, TITLE_MAX);
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
    authorizePushTargets({ userId: CALLER, title: "t", body: "b" }, CALLER, false),
    null,
  );
  assertEquals(
    authorizePushTargets({ userIds: [CALLER], title: "t", body: "b" }, CALLER, false),
    null,
  );
});

Deno.test("authorizePushTargets: non-admin pushing to another user is forbidden", () => {
  const r = authorizePushTargets(
    { userId: OTHER, title: "t", body: "b" },
    CALLER,
    false,
  );
  assertEquals(typeof r, "string");
  assertEquals((r ?? "").startsWith("forbidden"), true);
});

Deno.test("authorizePushTargets: non-admin with mixed userIds is forbidden", () => {
  const r = authorizePushTargets(
    { userIds: [CALLER, OTHER], title: "t", body: "b" },
    CALLER,
    false,
  );
  assertEquals((r ?? "").startsWith("forbidden"), true);
});

Deno.test("authorizePushTargets: raw tokens require admin", () => {
  const r = authorizePushTargets(
    { tokens: ["fcm-token-xyz"], title: "t", body: "b" },
    CALLER,
    false,
  );
  assertEquals((r ?? "").includes("raw tokens"), true);
});

Deno.test("authorizePushTargets: admin may push to any user", () => {
  assertEquals(
    authorizePushTargets(
      { userIds: [OTHER, "u3"], title: "t", body: "b" },
      CALLER,
      true,
    ),
    null,
  );
});

Deno.test("authorizePushTargets: admin may use raw tokens", () => {
  assertEquals(
    authorizePushTargets(
      { tokens: ["a", "b"], title: "t", body: "b" },
      CALLER,
      true,
    ),
    null,
  );
});

Deno.test("authorizePushTargets: empty target set is allowed (no-op)", () => {
  assertEquals(
    authorizePushTargets({ title: "t", body: "b" }, CALLER, false),
    null,
  );
});
