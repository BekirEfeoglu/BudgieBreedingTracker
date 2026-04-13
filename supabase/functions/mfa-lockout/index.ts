import { getCorsHeaders, corsPreflightResponse } from "../_shared/cors.ts";
import { getAuthenticatedUserId, createSupabaseAdmin } from "../_shared/auth.ts";
import { createRateLimiter, rateLimitedResponse } from "../_shared/rate-limit.ts";

const rateLimiter = createRateLimiter({ windowMs: 60_000, maxCalls: 30 });

const MAX_ATTEMPTS = 5;

const LOCKOUT_TIERS = [
  120,   // 1st lockout: 2 minutes
  300,   // 2nd lockout: 5 minutes
  900,   // 3rd lockout: 15 minutes
  3600,  // 4th+ lockout: 1 hour
];

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

function getLockoutDuration(lockoutCount: number): number {
  const tierIndex = Math.min(lockoutCount, LOCKOUT_TIERS.length - 1);
  return LOCKOUT_TIERS[tierIndex];
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return corsPreflightResponse(req);

  const headers = getCorsHeaders(req);

  try {
    const userId = await getAuthenticatedUserId(req);
    if (!userId) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers },
      );
    }

    if (!rateLimiter.check(userId)) return rateLimitedResponse(headers);

    const body = await req.json();
    const action = body.action;

    if (!action || !["check", "record-failure", "reset"].includes(action)) {
      return new Response(
        JSON.stringify({ error: "Invalid action. Use: check, record-failure, reset" }),
        { status: 400, headers },
      );
    }

    const supabase = createSupabaseAdmin();
    const lockout = await getOrCreateLockout(supabase, userId);

    if (!lockout) {
      return new Response(
        JSON.stringify({ error: "Failed to retrieve lockout state" }),
        { status: 500, headers },
      );
    }

    if (action === "check") {
      const status = isLockedOut(lockout);
      return new Response(
        JSON.stringify(status),
        { status: status.locked ? 429 : 200, headers },
      );
    }

    if (action === "record-failure") {
      const status = isLockedOut(lockout);
      if (status.locked) {
        return new Response(
          JSON.stringify({ locked: true, remaining_seconds: status.remaining_seconds }),
          { status: 429, headers },
        );
      }

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
        update.lockout_count = currentLockoutCount + 1;

        await supabase.from("mfa_lockouts").update(update).eq("user_id", userId);

        return new Response(
          JSON.stringify({ locked: true, remaining_seconds: lockoutDuration }),
          { status: 429, headers },
        );
      }

      await supabase.from("mfa_lockouts").update(update).eq("user_id", userId);

      return new Response(
        JSON.stringify({ locked: false, remaining_seconds: 0, failed_attempts: newAttempts }),
        { status: 200, headers },
      );
    }

    if (action === "reset") {
      // Only decay lockout_count if 24+ hours have passed since last attempt
      // This prevents attackers from alternating success/brute-force to keep tier low
      const lastAttempt = lockout?.last_attempt_at ? new Date(lockout.last_attempt_at) : new Date();
      const hoursSinceLastAttempt = (Date.now() - lastAttempt.getTime()) / (1000 * 3600);
      const currentCount = lockout?.lockout_count ?? 0;
      const newLockoutCount = hoursSinceLastAttempt > 24
        ? Math.max(0, currentCount - 1)
        : currentCount;

      await supabase
        .from("mfa_lockouts")
        .update({
          failed_attempts: 0,
          locked_until: null,
          last_attempt_at: new Date().toISOString(),
          lockout_count: newLockoutCount,
        })
        .eq("user_id", userId);

      return new Response(
        JSON.stringify({ locked: false, remaining_seconds: 0 }),
        { status: 200, headers },
      );
    }

    return new Response(
      JSON.stringify({ error: "Unhandled action" }),
      { status: 400, headers },
    );
  } catch (_error) {
    console.error("[mfa-lockout] Error:", _error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers },
    );
  }
});
