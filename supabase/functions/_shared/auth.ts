/**
 * Shared authentication utilities for Edge Functions.
 *
 * - getAuthenticatedUserId: validates JWT via supabase.auth.getUser()
 * - requireAdminRole: checks profiles table for admin/founder role
 * - createSupabaseAdmin: service-role client for privileged operations
 */
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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

/**
 * Check if a user has admin or founder role in the profiles table.
 * Uses a service-role client to bypass RLS.
 */
export async function requireAdminRole(userId: string): Promise<boolean> {
  const supabase = createSupabaseAdmin();
  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", userId)
    .single();

  return !!profile && ["admin", "founder"].includes(profile.role);
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
