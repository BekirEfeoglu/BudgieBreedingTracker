// Required env vars:
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
//   ALLOWED_ORIGINS — comma-separated list of allowed CORS origins
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

function getCorsHeaders(req: Request) {
  const origin = req.headers.get("Origin") ?? "";
  const raw = Deno.env.get("ALLOWED_ORIGINS") ?? "";
  const allowedOrigins = raw
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
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

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers },
    );
  }

  // Verify admin role via JWT
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

  const {
    data: { user },
    error: authError,
  } = await supabaseAuth.auth.getUser();
  if (authError || !user) {
    return new Response(
      JSON.stringify({ error: "Unauthorized" }),
      { status: 401, headers },
    );
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );

  // Verify caller is admin/founder
  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .single();

  if (!profile || !["admin", "founder"].includes(profile.role)) {
    return new Response(
      JSON.stringify({ error: "Forbidden" }),
      { status: 403, headers },
    );
  }

  try {
    const checks: Record<string, string> = {};
    const startTime = Date.now();

    // 1. Database connectivity check
    const dbStart = Date.now();
    const { error: dbError } = await supabase
      .from("profiles")
      .select("id", { count: "exact", head: true });
    checks["database"] = dbError ? "degraded" : "ok";
    const dbLatency = Date.now() - dbStart;

    // 2. Auth service check
    const authStart = Date.now();
    const { error: authCheckError } = await supabase.auth.admin.listUsers({
      page: 1,
      perPage: 1,
    });
    checks["auth"] = authCheckError ? "degraded" : "ok";
    const authLatency = Date.now() - authStart;

    // 3. Storage service check
    const storageStart = Date.now();
    const { error: storageError } = await supabase.storage.listBuckets();
    checks["storage"] = storageError ? "degraded" : "ok";
    const storageLatency = Date.now() - storageStart;

    const totalLatency = Date.now() - startTime;

    // Overall status: ok if all checks pass, degraded if any fail
    const allOk = Object.values(checks).every((v) => v === "ok");
    const status = allOk ? "ok" : "degraded";

    return new Response(
      JSON.stringify({
        status,
        checks,
        latency: {
          database_ms: dbLatency,
          auth_ms: authLatency,
          storage_ms: storageLatency,
          total_ms: totalLatency,
        },
        timestamp: new Date().toISOString(),
      }),
      { status: 200, headers },
    );
  } catch (_error) {
    return new Response(
      JSON.stringify({
        status: "error",
        error: "Health check failed",
        timestamp: new Date().toISOString(),
      }),
      { status: 500, headers },
    );
  }
});
