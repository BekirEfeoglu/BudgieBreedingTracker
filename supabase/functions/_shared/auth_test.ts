/**
 * Tests for the shared auth module.
 *
 * These tests set dummy env vars so the Supabase client can be instantiated
 * without real credentials. They verify the logic paths in each auth utility.
 *
 * Note: Supabase JS client creates internal timers/intervals for token refresh,
 * so tests that instantiate clients use sanitizeOps/sanitizeResources: false.
 *
 * Run: cd supabase/functions && deno test _shared/auth_test.ts --allow-env --allow-net
 */

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

// Set dummy env vars so createClient doesn't throw "supabaseUrl is required"
function ensureEnv() {
  if (!Deno.env.get("SUPABASE_URL")) {
    Deno.env.set("SUPABASE_URL", "https://test-project.supabase.co");
  }
  if (!Deno.env.get("SUPABASE_ANON_KEY")) {
    Deno.env.set(
      "SUPABASE_ANON_KEY",
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlc3QiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYwMDAwMDAwMCwiZXhwIjo5OTk5OTk5OTk5fQ.abc123",
    );
  }
  if (!Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")) {
    Deno.env.set(
      "SUPABASE_SERVICE_ROLE_KEY",
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlc3QiLCJyb2xlIjoic2VydmljZV9yb2xlIiwiaWF0IjoxNjAwMDAwMDAwLCJleHAiOjk5OTk5OTk5OTl9.xyz789",
    );
  }
}

// Shared test options for tests that create Supabase client instances.
// The client starts internal timers for auth refresh that can't be cleaned up.
const clientTestOpts = {
  sanitizeOps: false,
  sanitizeResources: false,
};

function base64UrlJson(value: unknown): string {
  return btoa(JSON.stringify(value))
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

function requestWithClaims(claims: Record<string, unknown>): Request {
  const token = [
    base64UrlJson({ alg: "HS256", typ: "JWT" }),
    base64UrlJson(claims),
    "signature",
  ].join(".");
  return new Request("https://example.com", {
    method: "POST",
    headers: { Authorization: `Bearer ${token}` },
  });
}

// ---------------------------------------------------------------------------
// getAuthenticatedUserId — header validation (no client created)
// ---------------------------------------------------------------------------

Deno.test("getAuthenticatedUserId: returns null when no Authorization header", async () => {
  ensureEnv();
  const { getAuthenticatedUserId } = await import("./auth.ts");
  const req = new Request("https://example.com", { method: "POST" });
  const result = await getAuthenticatedUserId(req);
  assertEquals(result, null);
});

Deno.test("getAuthenticatedUserId: returns null for non-Bearer auth header", async () => {
  ensureEnv();
  const { getAuthenticatedUserId } = await import("./auth.ts");
  const req = new Request("https://example.com", {
    method: "POST",
    headers: { Authorization: "Basic dXNlcjpwYXNz" },
  });
  const result = await getAuthenticatedUserId(req);
  assertEquals(result, null);
});

Deno.test({
  name: "getAuthenticatedUserId: returns null for invalid Bearer token",
  ...clientTestOpts,
  async fn() {
    ensureEnv();
    const { getAuthenticatedUserId } = await import("./auth.ts");
    const req = new Request("https://example.com", {
      method: "POST",
      headers: { Authorization: "Bearer invalid-token-that-wont-verify" },
    });
    // With a fake SUPABASE_URL, getUser() will fail -> catch returns null
    const result = await getAuthenticatedUserId(req);
    assertEquals(result, null);
  },
});

// ---------------------------------------------------------------------------
// Access-token claim helpers
// ---------------------------------------------------------------------------

Deno.test("getAccessTokenClaims: decodes bearer JWT payload", async () => {
  const { getAccessTokenClaims } = await import("./auth.ts");
  const req = requestWithClaims({ sub: "user-1", aal: "aal2" });

  const claims = getAccessTokenClaims(req);

  assertEquals(claims?.sub, "user-1");
  assertEquals(claims?.aal, "aal2");
});

Deno.test("getAccessTokenClaims: returns null for malformed JWT", async () => {
  const { getAccessTokenClaims } = await import("./auth.ts");
  const req = new Request("https://example.com", {
    headers: { Authorization: "Bearer not-a-jwt" },
  });

  assertEquals(getAccessTokenClaims(req), null);
});

Deno.test("getAuthenticatorAssuranceLevel: returns aal claim", async () => {
  const { getAuthenticatorAssuranceLevel } = await import("./auth.ts");
  const req = requestWithClaims({ aal: "aal2" });

  assertEquals(getAuthenticatorAssuranceLevel(req), "aal2");
});

Deno.test("getAuthenticatorAssuranceLevel: returns null when missing", async () => {
  const { getAuthenticatorAssuranceLevel } = await import("./auth.ts");
  const req = requestWithClaims({ sub: "user-1" });

  assertEquals(getAuthenticatorAssuranceLevel(req), null);
});

// ---------------------------------------------------------------------------
// createSupabaseAdmin
// ---------------------------------------------------------------------------

Deno.test({
  name: "createSupabaseAdmin: returns a valid Supabase client object",
  ...clientTestOpts,
  async fn() {
    ensureEnv();
    const { createSupabaseAdmin } = await import("./auth.ts");
    const client = createSupabaseAdmin();
    assert(client !== null && client !== undefined);
    assert(typeof client.from === "function");
    assert(typeof client.auth === "object");
  },
});

// ---------------------------------------------------------------------------
// createSupabaseAuth
// ---------------------------------------------------------------------------

Deno.test({
  name: "createSupabaseAuth: returns a client with expected interface",
  ...clientTestOpts,
  async fn() {
    ensureEnv();
    const { createSupabaseAuth } = await import("./auth.ts");
    const req = new Request("https://example.com", {
      method: "POST",
      headers: { Authorization: "Bearer test-jwt-token" },
    });
    const client = createSupabaseAuth(req);
    assert(client !== null && client !== undefined);
    assert(typeof client.from === "function");
    assert(typeof client.auth === "object");
  },
});

Deno.test({
  name: "createSupabaseAuth: works without Authorization header",
  ...clientTestOpts,
  async fn() {
    ensureEnv();
    const { createSupabaseAuth } = await import("./auth.ts");
    const req = new Request("https://example.com", { method: "POST" });
    const client = createSupabaseAuth(req);
    assert(client !== null && client !== undefined);
    assert(typeof client.from === "function");
  },
});

// ---------------------------------------------------------------------------
// requireAdminRole
// ---------------------------------------------------------------------------

Deno.test({
  name: "requireAdminRole: returns false for non-existent user",
  ...clientTestOpts,
  async fn() {
    ensureEnv();
    const { requireAdminRole } = await import("./auth.ts");
    // With a fake Supabase URL, the query will fail -> returns false
    const result = await requireAdminRole("non-existent-user-id");
    assertEquals(result, false);
  },
});

Deno.test({
  name: "requireAdminRole: returns false for empty user id",
  ...clientTestOpts,
  async fn() {
    ensureEnv();
    const { requireAdminRole } = await import("./auth.ts");
    const result = await requireAdminRole("");
    assertEquals(result, false);
  },
});
