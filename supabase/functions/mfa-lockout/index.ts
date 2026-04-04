import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const MAX_ATTEMPTS = 5;

// Escalating lockout durations based on total lockout count
const LOCKOUT_TIERS = [
  120,   // 1st lockout: 2 minutes
  300,   // 2nd lockout: 5 minutes
  900,   // 3rd lockout: 15 minutes
  3600,  // 4th+ lockout: 1 hour
];

const corsHeaders = {
  "Access-Control-Allow-Origin": Deno.env.get("ALLOWED_ORIGINS") ?? "",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json",
};

/**
 * Verify the caller's identity via Supabase auth (JWT signature validation).
 * Returns the authenticated user ID or null.
 */
async function getAuthenticatedUserId(req: Request): Promise<string | null> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return null;

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error } = await supabase.auth.getUser();
    if (error || !user) return null;
    return user.id;
  } catch {
    return null;
  }
}

function createSupabaseAdmin() {
  return createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );
}

async function getOrCreateLockout(supabase: any, userId: string) {
  const { data } = await supabase
    .from("mfa_lockouts")
    .select("user_id, failed_attempts, locked_until, last_attempt_at, lockout_count")
    .eq("user_id", userId)
    .single();

  if (data) return data;

  const { data: created } = await supabase
    .from("mfa_lockouts")
    .upsert(
      { user_id: userId, failed_attempts: 0, lockout_count: 0 },
      { onConflict: "user_id" },
    )
    .select()
    .single();

  return created;
}

function isLockedOut(lockout: any): { locked: boolean; remaining_seconds: number } {
  if (!lockout?.locked_until) return { locked: false, remaining_seconds: 0 };
  const now = new Date();
  const lockedUntil = new Date(lockout.locked_until);
  if (now < lockedUntil) {
    const remaining = Math.ceil((lockedUntil.getTime() - now.getTime()) / 1000);
    return { locked: true, remaining_seconds: remaining };
  }
  return { locked: false, remaining_seconds: 0 };
}

/**
 * Get lockout duration in seconds based on how many times user has been locked out.
 */
function getLockoutDuration(lockoutCount: number): number {
  const tierIndex = Math.min(lockoutCount, LOCKOUT_TIERS.length - 1);
  return LOCKOUT_TIERS[tierIndex];
}

serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Validate JWT signature via Supabase auth (not manual atob decode)
    const userId = await getAuthenticatedUserId(req);
    if (!userId) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: corsHeaders },
      );
    }

    const body = await req.json();
    const action = body.action;

    if (!action || !["check", "record-failure", "reset"].includes(action)) {
      return new Response(
        JSON.stringify({ error: "Invalid action. Use: check, record-failure, reset" }),
        { status: 400, headers: corsHeaders },
      );
    }

    const supabase = createSupabaseAdmin();
    const lockout = await getOrCreateLockout(supabase, userId);

    if (!lockout) {
      return new Response(
        JSON.stringify({ error: "Failed to retrieve lockout state" }),
        { status: 500, headers: corsHeaders },
      );
    }

    // --- CHECK ---
    if (action === "check") {
      const status = isLockedOut(lockout);
      return new Response(
        JSON.stringify(status),
        { status: status.locked ? 429 : 200, headers: corsHeaders },
      );
    }

    // --- RECORD FAILURE ---
    if (action === "record-failure") {
      const status = isLockedOut(lockout);
      if (status.locked) {
        return new Response(
          JSON.stringify({ locked: true, remaining_seconds: status.remaining_seconds }),
          { status: 429, headers: corsHeaders },
        );
      }

      // If a previous lockout has expired, reset failed_attempts before counting
      const previouslyLocked = lockout.locked_until && new Date(lockout.locked_until) <= new Date();
      const baseAttempts = previouslyLocked ? 0 : (lockout.failed_attempts ?? 0);
      const newAttempts = baseAttempts + 1;
      const currentLockoutCount = lockout.lockout_count ?? 0;
      const update: Record<string, any> = {
        failed_attempts: newAttempts,
        last_attempt_at: new Date().toISOString(),
      };

      if (newAttempts >= MAX_ATTEMPTS) {
        const lockoutDuration = getLockoutDuration(currentLockoutCount);
        const lockedUntil = new Date(Date.now() + lockoutDuration * 1000);
        update.locked_until = lockedUntil.toISOString();
        // Do NOT reset failed_attempts — keep for audit trail
        update.lockout_count = currentLockoutCount + 1;

        await supabase
          .from("mfa_lockouts")
          .update(update)
          .eq("user_id", userId);

        return new Response(
          JSON.stringify({ locked: true, remaining_seconds: lockoutDuration }),
          { status: 429, headers: corsHeaders },
        );
      }

      await supabase
        .from("mfa_lockouts")
        .update(update)
        .eq("user_id", userId);

      return new Response(
        JSON.stringify({
          locked: false,
          remaining_seconds: 0,
          failed_attempts: newAttempts,
        }),
        { status: 200, headers: corsHeaders },
      );
    }

    // --- RESET (only on successful MFA verification) ---
    if (action === "reset") {
      await supabase
        .from("mfa_lockouts")
        .update({
          failed_attempts: 0,
          locked_until: null,
          last_attempt_at: new Date().toISOString(),
          // Decrease lockout_count (not full reset) so repeat offenders
          // still face escalated lockouts on next failure cycle.
          lockout_count: Math.max(0, (lockout?.lockout_count ?? 1) - 1),
        })
        .eq("user_id", userId);

      return new Response(
        JSON.stringify({ locked: false, remaining_seconds: 0 }),
        { status: 200, headers: corsHeaders },
      );
    }

    return new Response(
      JSON.stringify({ error: "Unhandled action" }),
      { status: 400, headers: corsHeaders },
    );
  } catch (_error) {
    // Generic error message — do not leak internal details
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: corsHeaders },
    );
  }
});
