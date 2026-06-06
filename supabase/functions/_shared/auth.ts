/**
 * Shared authentication utilities for Edge Functions.
 *
 * - getAuthenticatedUserId: validates JWT via supabase.auth.getUser()
 * - requireAdminRole: checks profiles table for admin/founder role
 * - createSupabaseAdmin: service-role client for privileged operations
 */
// Deno-native `npm:` specifier. The previous `https://esm.sh/...`
// import was the single biggest source of intermittent edge-function
// deploy failures: esm.sh returned HTTP 522 multiple times during
// `bundling Function: revoke-oauth-token`, requiring a manual rerun
// for every other push. `npm:` is resolved by the Edge Runtime
// directly (>= v1.45, currently v1.73 in production) and bypasses
// third-party CDNs entirely.
import { createClient } from "npm:@supabase/supabase-js@2";

/**
 * Validate the caller's JWT and return their user ID.
 * Returns null if the token is missing, malformed, or invalid.
 *
 * Always validates server-side via supabase.auth.getUser() —
 * never trusts decoded JWT payload without signature verification.
 */
export async function getAuthenticatedUserId(
  req: Request,
): Promise<string | null> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return null;

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    );

    const {
      data: { user },
      error,
    } = await supabase.auth.getUser();
    if (error || !user) return null;
    return user.id;
  } catch {
    return null;
  }
}

function decodeBase64Url(value: string): string {
  const normalized = value.replaceAll("-", "+").replaceAll("_", "/");
  const padded = normalized.padEnd(
    Math.ceil(normalized.length / 4) * 4,
    "=",
  );
  return atob(padded);
}

/**
 * Extract claims from the bearer access token.
 *
 * This does not verify the JWT signature by itself. Use only after
 * getAuthenticatedUserId(req) has validated the same token via Supabase Auth.
 */
export function getAccessTokenClaims(
  req: Request,
): Record<string, unknown> | null {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return null;
  const token = authHeader.slice("Bearer ".length);
  const parts = token.split(".");
  if (parts.length !== 3) return null;

  try {
    const payload = JSON.parse(decodeBase64Url(parts[1]));
    return payload && typeof payload === "object" ? payload : null;
  } catch {
    return null;
  }
}

export function getAuthenticatorAssuranceLevel(req: Request): string | null {
  const claims = getAccessTokenClaims(req);
  const aal = claims?.aal;
  return typeof aal === "string" ? aal : null;
}

type AdminProfile = {
  role?: unknown;
  is_active?: unknown;
};

export function isActiveAdminProfile(profile: AdminProfile | null): boolean {
  if (!profile || profile.is_active !== true) return false;
  return profile.role === "admin" || profile.role === "founder";
}

/**
 * Check if a user has admin or founder role in the profiles table.
 * Uses a service-role client to bypass RLS.
 */
export async function requireAdminRole(userId: string): Promise<boolean> {
  const supabase = createSupabaseAdmin();
  const { data: profile } = await supabase
    .from("profiles")
    .select("role, is_active")
    .eq("id", userId)
    .single();

  return isActiveAdminProfile(profile);
}

/**
 * Create a Supabase client with service-role key for privileged operations.
 * Use sparingly — only for server-side admin tasks.
 */
export function createSupabaseAdmin() {
  return createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );
}

/**
 * Create a Supabase client authenticated as the requesting user.
 * Passes the user's JWT in the Authorization header.
 */
export function createSupabaseAuth(req: Request) {
  return createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    {
      global: {
        headers: {
          Authorization: req.headers.get("Authorization") ?? "",
        },
      },
    },
  );
}
