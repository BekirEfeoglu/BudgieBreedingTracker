import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const MAX_ATTEMPTS = 5;
const LOCKOUT_SECONDS = 120; // 2 minutes

const headers = { "Content-Type": "application/json" };

function getUserIdFromJwt(req: Request): string | null {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return null;
  try {
    const token = authHeader.split(" ")[1];
    const payload = JSON.parse(atob(token.split(".")[1]));
    return payload.sub ?? null;
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
    .select("*")
    .eq("user_id", userId)
    .single();

  if (data) return data;

  const { data: created } = await supabase
    .from("mfa_lockouts")
    .upsert({ user_id: userId, failed_attempts: 0 }, { onConflict: "user_id" })
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

serve(async (req) => {
  try {
    const userId = getUserIdFromJwt(req);
    if (!userId) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers },
      );
    }

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

    // --- CHECK ---
    if (action === "check") {
      const status = isLockedOut(lockout);
      return new Response(
        JSON.stringify(status),
        { status: status.locked ? 429 : 200, headers },
      );
    }

    // --- RECORD FAILURE ---
    if (action === "record-failure") {
      const status = isLockedOut(lockout);
      if (status.locked) {
        return new Response(
          JSON.stringify({ locked: true, remaining_seconds: status.remaining_seconds }),
          { status: 429, headers },
        );
      }

      const newAttempts = (lockout.failed_attempts ?? 0) + 1;
      const update: Record<string, any> = {
        failed_attempts: newAttempts,
        last_attempt_at: new Date().toISOString(),
      };

      if (newAttempts >= MAX_ATTEMPTS) {
        const lockedUntil = new Date(Date.now() + LOCKOUT_SECONDS * 1000);
        update.locked_until = lockedUntil.toISOString();
        update.failed_attempts = 0;
      }

      await supabase
        .from("mfa_lockouts")
        .update(update)
        .eq("user_id", userId);

      if (newAttempts >= MAX_ATTEMPTS) {
        return new Response(
          JSON.stringify({ locked: true, remaining_seconds: LOCKOUT_SECONDS }),
          { status: 429, headers },
        );
      }

      return new Response(
        JSON.stringify({
          locked: false,
          remaining_seconds: 0,
          failed_attempts: newAttempts,
        }),
        { status: 200, headers },
      );
    }

    // --- RESET ---
    if (action === "reset") {
      await supabase
        .from("mfa_lockouts")
        .update({
          failed_attempts: 0,
          locked_until: null,
          last_attempt_at: new Date().toISOString(),
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
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers },
    );
  }
});
