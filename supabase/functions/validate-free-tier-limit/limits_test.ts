import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  ALLOWED_TABLES,
  evaluateLimit,
  getLimit,
  getStatusFilter,
  isAllowedTable,
  isExemptProfile,
  LIMITS,
  shouldFilterDeleted,
} from "./limits_core.ts";

Deno.test("ALLOWED_TABLES covers every LIMITS entry", () => {
  for (const key of Object.keys(LIMITS)) {
    assertEquals(ALLOWED_TABLES.has(key), true);
  }
  assertEquals(ALLOWED_TABLES.size, Object.keys(LIMITS).length);
});

Deno.test("isAllowedTable rejects unknown tables", () => {
  assertEquals(isAllowedTable("birds"), true);
  assertEquals(isAllowedTable("secrets"), false);
  assertEquals(isAllowedTable(""), false);
});

Deno.test("getLimit returns null for unknown tables", () => {
  assertEquals(getLimit("birds"), 15);
  assertEquals(getLimit("breeding_pairs"), 5);
  assertEquals(getLimit("incubations"), 3);
  assertEquals(getLimit("marketplace_listings"), 3);
  assertEquals(getLimit("profiles"), null);
});

// ---------------------------------------------------------------------------
// Profile exemption
// ---------------------------------------------------------------------------

Deno.test("isExemptProfile: null / empty profile is not exempt", () => {
  assertEquals(isExemptProfile(null), false);
  assertEquals(isExemptProfile(undefined), false);
  assertEquals(isExemptProfile({}), false);
});

Deno.test("isExemptProfile: premium bypasses limit", () => {
  assertEquals(isExemptProfile({ is_premium: true }), true);
});

Deno.test("isExemptProfile: admin/founder bypasses limit", () => {
  assertEquals(isExemptProfile({ role: "admin" }), true);
  assertEquals(isExemptProfile({ role: "founder" }), true);
});

Deno.test("isExemptProfile: ordinary user is not exempt", () => {
  assertEquals(isExemptProfile({ is_premium: false, role: "user" }), false);
  assertEquals(isExemptProfile({ is_premium: null, role: null }), false);
});

// ---------------------------------------------------------------------------
// Query filter helpers
// ---------------------------------------------------------------------------

Deno.test("shouldFilterDeleted is false only for incubations", () => {
  assertEquals(shouldFilterDeleted("birds"), true);
  assertEquals(shouldFilterDeleted("breeding_pairs"), true);
  assertEquals(shouldFilterDeleted("marketplace_listings"), true);
  assertEquals(shouldFilterDeleted("incubations"), false);
});

Deno.test("getStatusFilter for breeding_pairs", () => {
  assertEquals(getStatusFilter("breeding_pairs"), ["active", "ongoing"]);
});

Deno.test("getStatusFilter for incubations and listings", () => {
  assertEquals(getStatusFilter("incubations"), ["active"]);
  assertEquals(getStatusFilter("marketplace_listings"), ["active"]);
});

Deno.test("getStatusFilter for birds is null", () => {
  assertEquals(getStatusFilter("birds"), null);
});

// ---------------------------------------------------------------------------
// evaluateLimit
// ---------------------------------------------------------------------------

Deno.test("evaluateLimit allows count below limit", () => {
  assertEquals(evaluateLimit(10, 15).allowed, true);
});

Deno.test("evaluateLimit rejects at exactly the limit", () => {
  assertEquals(evaluateLimit(15, 15).allowed, false);
});

Deno.test("evaluateLimit rejects above the limit", () => {
  assertEquals(evaluateLimit(20, 15).allowed, false);
});

Deno.test("evaluateLimit treats null count as zero", () => {
  const r = evaluateLimit(null, 15);
  assertEquals(r.allowed, true);
  assertEquals(r.count, 0);
});

Deno.test("evaluateLimit treats undefined count as zero", () => {
  assertEquals(evaluateLimit(undefined, 3).allowed, true);
});
