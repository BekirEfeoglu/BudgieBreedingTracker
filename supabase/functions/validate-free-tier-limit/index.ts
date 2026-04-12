import { getCorsHeaders, corsPreflightResponse } from "../_shared/cors.ts";
import { getAuthenticatedUserId, createSupabaseAdmin } from "../_shared/auth.ts";

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
    let body: { table?: string };
    try {
      body = await req.json();
    } catch {
      return new Response(
        JSON.stringify({ error: "Invalid JSON body" }),
        { status: 400, headers },
      );
    }
    const { table } = body;

    if (!table) {
      return new Response(
        JSON.stringify({ error: "Missing table parameter" }),
        { status: 400, headers },
      );
    }

    if (!ALLOWED_TABLES.has(table)) {
      return new Response(
        JSON.stringify({ allowed: true }),
        { status: 200, headers },
      );
    }

    const userId = await getAuthenticatedUserId(req);
    if (!userId) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers },
      );
    }

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
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers },
    );
  }
});
