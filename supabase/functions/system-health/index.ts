import { getCorsHeaders, corsPreflightResponse } from "../_shared/cors.ts";
import { getAuthenticatedUserId, createSupabaseAdmin } from "../_shared/auth.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return corsPreflightResponse(req);

  const headers = getCorsHeaders(req);

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers },
    );
  }

  // Verify admin role via JWT
  const userId = await getAuthenticatedUserId(req);
  if (!userId) {
    return new Response(
      JSON.stringify({ error: "Unauthorized" }),
      { status: 401, headers },
    );
  }

  const supabase = createSupabaseAdmin();

  // Verify caller is admin/founder
  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", userId)
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
    const allOk = Object.values(checks).every((v) => v === "ok");

    return new Response(
      JSON.stringify({
        status: allOk ? "ok" : "degraded",
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
