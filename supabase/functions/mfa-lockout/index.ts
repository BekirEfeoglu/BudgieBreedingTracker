import { getCorsHeaders, corsPreflightResponse } from "../_shared/cors.ts";
import { getAuthenticatedUserId, createSupabaseAdmin } from "../_shared/auth.ts";
import { createRateLimiter, rateLimitedResponse } from "../_shared/rate-limit.ts";
import { z } from "npm:zod@3.24.4";
import { parseRequestBody } from "../_shared/validation.ts";
import {
  computeFailureUpdate,
  computeResetCount,
  isLockedOut,
  type LockoutRow,
} from "./lockout_core.ts";

const rateLimiter = createRateLimiter({ windowMs: 60_000, maxCalls: 30 });

async function getOrCreateLockout(
  supabase: any,
  userId: string,
): Promise<LockoutRow | null> {
  const { data } = await supabase
    .from("mfa_lockouts")
    .select("user_id, failed_attempts, locked_until, last_attempt_at, lockout_count")
    .eq("user_id", userId)
    .single();

  if (data) return data as LockoutRow;

  const { data: created } = await supabase
    .from("mfa_lockouts")
    .upsert(
      { user_id: userId, failed_attempts: 0, lockout_count: 0 },
      { onConflict: "user_id" },
    )
    .select()
    .single();

  return (created ?? null) as LockoutRow | null;
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

    const mfaSchema = z.object({
      action: z.enum(["check", "record-failure", "reset"]),
    });

    const parsed = await parseRequestBody(req, mfaSchema, headers);
    if (!parsed.success) return parsed.response;

    const { action } = parsed.data;

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

      const now = new Date();
      const outcome = computeFailureUpdate(lockout, now);

      const update: Record<string, any> = {
        failed_attempts: outcome.failed_attempts,
        last_attempt_at: now.toISOString(),
      };
      if (outcome.locked) {
        update.locked_until = outcome.locked_until;
        update.lockout_count = outcome.lockout_count;
      }

      await supabase.from("mfa_lockouts").update(update).eq("user_id", userId);

      if (outcome.locked) {
        return new Response(
          JSON.stringify({ locked: true, remaining_seconds: outcome.remaining_seconds }),
          { status: 429, headers },
        );
      }

      return new Response(
        JSON.stringify({
          locked: false,
          remaining_seconds: 0,
          failed_attempts: outcome.failed_attempts,
        }),
        { status: 200, headers },
      );
    }

    if (action === "reset") {
      // Decay policy: only drop lockout_count after a full week of inactivity.
      // Shorter windows (e.g. 24h) would let an attacker alternate wait/brute
      // attempts and keep the tier low; see lockout_core.ts.
      const now = new Date();
      const newLockoutCount = computeResetCount(lockout, now);

      await supabase
        .from("mfa_lockouts")
        .update({
          failed_attempts: 0,
          locked_until: null,
          last_attempt_at: now.toISOString(),
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
