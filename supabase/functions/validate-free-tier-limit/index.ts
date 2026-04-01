// Required env vars:
//   SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
//   ALLOWED_ORIGINS — comma-separated list of allowed CORS origins
//                     (e.g. "https://app.example.com,https://staging.example.com")
//                     Must be set before deploying if web clients will call this function.
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const LIMITS: Record<string, number> = {
  birds: 15,
  breeding_pairs: 5,
  incubations: 3,
};

const ALLOWED_TABLES = new Set(Object.keys(LIMITS));

function getCorsHeaders(req: Request) {
  const origin = req.headers.get("Origin") ?? "";
  const raw = Deno.env.get("ALLOWED_ORIGINS") ?? "";
  const allowedOrigins = raw
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  if (allowedOrigins.length === 0 && origin) {
    console.warn(
      "ALLOWED_ORIGINS env is empty — CORS will reject browser requests. " +
      `Requesting origin: ${origin}`,
    );
  }
  // Only reflect the origin when it is explicitly listed; never fall back to
  // a wildcard or the first entry for unknown callers.
  const resolvedOrigin = allowedOrigins.includes(origin) ? origin : "";
  return {
    "Access-Control-Allow-Origin": resolvedOrigin,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Content-Type": "application/json",
  };
}

serve(async (req) => {
  const headers = getCorsHeaders(req);

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers });
  }

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

    // Validate table against allowlist before any query
    if (!ALLOWED_TABLES.has(table)) {
      return new Response(
        JSON.stringify({ allowed: true }),
        { status: 200, headers },
      );
    }

    // Extract user_id from JWT instead of trusting request body
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers },
      );
    }

    const supabaseAuth = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user }, error: authError } = await supabaseAuth.auth.getUser();
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers },
      );
    }

    const user_id = user.id;

    // Use service role client for data queries (bypasses RLS)
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const limit = LIMITS[table]!;

    const { data: profile } = await supabase
      .from("profiles")
      .select("is_premium, role")
      .eq("id", user_id)
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
      .eq("user_id", user_id);

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
      {
        status: allowed ? 200 : 403,
        headers,
      },
    );
  } catch (_error) {
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: getCorsHeaders(req) },
    );
  }
});
