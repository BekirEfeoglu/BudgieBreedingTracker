import { corsPreflightResponse, getCorsHeaders } from "../_shared/cors.ts";
import {
  createSupabaseAdmin,
  getAuthenticatedUserId,
  requireAdminRole,
} from "../_shared/auth.ts";
import {
  createRateLimiter,
  createSupabaseRateLimitStore,
  rateLimitedResponse,
} from "../_shared/rate-limit.ts";
import { buildHealthSnapshot, type CheckStatus } from "./health_core.ts";

const rateLimiter = createRateLimiter({
  windowMs: 60_000,
  maxCalls: 10,
  store: createSupabaseRateLimitStore("system-health"),
});

type SupabaseAdminClient = any;

export type SystemHealthDeps = {
  getAuthenticatedUserId(req: Request): Promise<string | null>;
  requireAdminRole(userId: string): Promise<boolean>;
  checkRateLimit(userId: string): boolean | Promise<boolean>;
  createAdminClient(): SupabaseAdminClient;
  now(): Date;
};

const defaultDeps: SystemHealthDeps = {
  getAuthenticatedUserId,
  requireAdminRole,
  checkRateLimit: (userId) => rateLimiter.check(userId),
  createAdminClient: createSupabaseAdmin,
  now: () => new Date(),
};

export function createSystemHealthHandler(
  deps: SystemHealthDeps = defaultDeps,
) {
  return async (req: Request): Promise<Response> => {
    if (req.method === "OPTIONS") return corsPreflightResponse(req);

    const headers = getCorsHeaders(req);

    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "Method not allowed" }),
        { status: 405, headers },
      );
    }

    // Verify admin role via JWT
    const userId = await deps.getAuthenticatedUserId(req);
    if (!userId) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers },
      );
    }

    if (!(await deps.checkRateLimit(userId))) return rateLimitedResponse(headers);

    // Verify caller is admin/founder using shared auth utility
    const isAdmin = await deps.requireAdminRole(userId);
    if (!isAdmin) {
      return new Response(
        JSON.stringify({ error: "Forbidden" }),
        { status: 403, headers },
      );
    }

    const supabase = deps.createAdminClient();

    try {
      const checks: Record<string, CheckStatus> = {};
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
      const snapshot = buildHealthSnapshot(
        checks,
        {
          database_ms: dbLatency,
          auth_ms: authLatency,
          storage_ms: storageLatency,
          total_ms: totalLatency,
        },
        deps.now().toISOString(),
      );

      return new Response(JSON.stringify(snapshot), { status: 200, headers });
    } catch (_error) {
      console.error("[system-health] Error:", _error);
      return new Response(
        JSON.stringify({
          status: "error",
          error: "Health check failed",
          timestamp: deps.now().toISOString(),
        }),
        { status: 500, headers },
      );
    }
  };
}
