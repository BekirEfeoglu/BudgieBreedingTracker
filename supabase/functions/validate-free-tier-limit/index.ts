import { getCorsHeaders, corsPreflightResponse } from "../_shared/cors.ts";
import { getAuthenticatedUserId, createSupabaseAdmin } from "../_shared/auth.ts";
import { createRateLimiter, rateLimitedResponse } from "../_shared/rate-limit.ts";
import { z } from "npm:zod@3.24.4";
import { parseRequestBody } from "../_shared/validation.ts";

const rateLimiter = createRateLimiter({ windowMs: 60_000, maxCalls: 30 });

const LIMITS: Record<string, number> = {
  birds: 15,
  breeding_pairs: 5,
  incubations: 3,
};

const ALLOWED_TABLES = new Set(Object.keys(LIMITS));

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return corsPreflightResponse(req);

  const headers = getCorsHeaders(req);

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers },
    );
  }

  try {
    const freeTierSchema = z.object({
      table: z.string().min(1, "Missing table parameter"),
    });

    const parsed = await parseRequestBody(req, freeTierSchema, headers);
    if (!parsed.success) return parsed.response;

    const { table } = parsed.data;

    const userId = await getAuthenticatedUserId(req);
    if (!userId) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers },
      );
    }

    if (!ALLOWED_TABLES.has(table)) {
      console.warn(`[validate-free-tier-limit] Unknown table requested: ${table}`);
      return new Response(
        JSON.stringify({ allowed: true }),
        { status: 200, headers },
      );
    }

    if (!rateLimiter.check(userId)) return rateLimitedResponse(headers);

    const supabase = createSupabaseAdmin();
    const limit = LIMITS[table]!;

    const { data: profile } = await supabase
      .from("profiles")
      .select("is_premium, role")
      .eq("id", userId)
      .single();

    if (
      profile?.is_premium ||
      profile?.role === "admin" ||
      profile?.role === "founder"
    ) {
      return new Response(
        JSON.stringify({ allowed: true }),
        { status: 200, headers },
      );
    }

    let query = supabase
      .from(table)
      .select("id", { count: "exact", head: true })
      .eq("user_id", userId);

    if (table !== "incubations") {
      query = query.eq("is_deleted", false);
    }

    if (table === "breeding_pairs") {
      query = query.in("status", ["active", "ongoing"]);
    }
    if (table === "incubations") {
      query = query.eq("status", "active");
    }

    const { count } = await query;
    const allowed = (count ?? 0) < limit;

    return new Response(
      JSON.stringify({ allowed, count, limit }),
      { status: allowed ? 200 : 403, headers },
    );
  } catch (_error) {
    console.error("[validate-free-tier-limit] Error:", _error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers },
    );
  }
});
