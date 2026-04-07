import {
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  moderateText,
  PROHIBITED_PATTERNS,
  MAX_TEXT_LENGTH,
} from "./moderation.ts";

// ---------------------------------------------------------------------------
// Clean content
// ---------------------------------------------------------------------------

Deno.test("allows clean text", () => {
  const result = moderateText("My budgie laid 4 eggs today!");
  assertEquals(result.allowed, true);
  assertEquals(result.reason, undefined);
});

Deno.test("allows short text", () => {
  const result = moderateText("Hi");
  assertEquals(result.allowed, true);
});

Deno.test("allows empty string", () => {
  const result = moderateText("");
  assertEquals(result.allowed, true);
});

// ---------------------------------------------------------------------------
// Prohibited patterns
// ---------------------------------------------------------------------------

Deno.test("rejects English violence pattern", () => {
  const result = moderateText("I will kill your bird");
  assertEquals(result.allowed, false);
  assertEquals(result.reason, "content_violation");
});

Deno.test("rejects Turkish violence pattern", () => {
  const result = moderateText("Seni öldürürüm");
  assertEquals(result.allowed, false);
  assertEquals(result.reason, "content_violation");
});

Deno.test("rejects German violence pattern", () => {
  const result = moderateText("Ich werde dich töten");
  assertEquals(result.allowed, false);
  assertEquals(result.reason, "content_violation");
});

Deno.test("rejects spam pattern", () => {
  const result = moderateText("buy followers cheap now!");
  assertEquals(result.allowed, false);
  assertEquals(result.reason, "content_violation");
});

Deno.test("rejects URL shortener spam", () => {
  const result = moderateText("Check this out: bit.ly/free");
  assertEquals(result.allowed, false);
  assertEquals(result.reason, "content_violation");
});

Deno.test("rejects self-harm content", () => {
  const result = moderateText("how to kill yourself");
  assertEquals(result.allowed, false);
  assertEquals(result.reason, "content_violation");
});

Deno.test("pattern matching is case-insensitive", () => {
  const result = moderateText("I WILL KILL");
  assertEquals(result.allowed, false);
  assertEquals(result.reason, "content_violation");
});

// ---------------------------------------------------------------------------
// Excessive caps detection
// ---------------------------------------------------------------------------

Deno.test("rejects excessive caps in long text", () => {
  const result = moderateText("THIS IS ALL CAPS AND IT IS VERY LONG TEXT");
  assertEquals(result.allowed, false);
  assertEquals(result.reason, "excessive_caps");
});

Deno.test("allows caps in short text (<=20 chars)", () => {
  const result = moderateText("SHORT CAPS TEXT");
  assertEquals(result.allowed, true);
});

Deno.test("allows mixed case in long text", () => {
  const result = moderateText("This is a normal sentence with mixed case characters");
  assertEquals(result.allowed, true);
});

// ---------------------------------------------------------------------------
// Repeated character spam
// ---------------------------------------------------------------------------

Deno.test("rejects repeated characters (10+)", () => {
  const result = moderateText("aaaaaaaaaa is spam");
  assertEquals(result.allowed, false);
  assertEquals(result.reason, "spam_detected");
});

Deno.test("allows 9 repeated characters", () => {
  const result = moderateText("aaaaaaaaa is ok");
  assertEquals(result.allowed, true);
});

// ---------------------------------------------------------------------------
// URL spam (>3 URLs)
// ---------------------------------------------------------------------------

Deno.test("rejects more than 3 URLs", () => {
  const result = moderateText(
    "Visit https://a.com https://b.com https://c.com https://d.com",
  );
  assertEquals(result.allowed, false);
  assertEquals(result.reason, "spam_detected");
});

Deno.test("allows up to 3 URLs", () => {
  const result = moderateText(
    "Visit https://a.com https://b.com https://c.com",
  );
  assertEquals(result.allowed, true);
});

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

Deno.test("PROHIBITED_PATTERNS is non-empty", () => {
  assertEquals(PROHIBITED_PATTERNS.length > 0, true);
});

Deno.test("MAX_TEXT_LENGTH is 10000", () => {
  assertEquals(MAX_TEXT_LENGTH, 10000);
});

// ---------------------------------------------------------------------------
// All prohibited patterns are testable
// ---------------------------------------------------------------------------

Deno.test("every prohibited pattern triggers rejection", () => {
  for (const pattern of PROHIBITED_PATTERNS) {
    const result = moderateText(pattern);
    assertEquals(
      result.allowed,
      false,
      `Pattern "${pattern}" should be rejected but was allowed`,
    );
    assertEquals(result.reason, "content_violation");
  }
});
