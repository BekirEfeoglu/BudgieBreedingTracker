import { corsPreflightResponse, getCorsHeaders } from "../_shared/cors.ts";
import {
  createSupabaseAdmin,
  getAuthenticatedUserId,
} from "../_shared/auth.ts";
import {
  createRateLimiter,
  createSupabaseRateLimitStore,
  rateLimitedResponse,
} from "../_shared/rate-limit.ts";
import { z } from "npm:zod@3.24.4";
import { parseRequestBody } from "../_shared/validation.ts";
import {
  evaluateLimit,
  getLimit,
  getStatusFilter,
  isAllowedTable,
  isExemptProfile,
  shouldFilterDeleted,
} from "./limits_core.ts";

const rateLimiter = createRateLimiter({
  windowMs: 60_000,
  maxCalls: 30,
  store: createSupabaseRateLimitStore("validate-free-tier-limit"),
});

const freeTierSchema = z.object({
  table: z.string().min(1, "Missing table parameter"),
});

type SupabaseAdminClient = any;

export type ValidateFreeTierLimitDeps = {
  getAuthenticatedUserId(req: Request): Promise<string | null>;
  checkRateLimit(userId: string): boolean | Promise<boolean>;
  createAdminClient(): SupabaseAdminClient;
};

const defaultDeps: ValidateFreeTierLimitDeps = {
  getAuthenticatedUserId,
  checkRateLimit: (userId) => rateLimiter.check(userId),
  createAdminClient: createSupabaseAdmin,
};

export function createValidateFreeTierLimitHandler(
  deps: ValidateFreeTierLimitDeps = defaultDeps,
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

    try {
      // Auth first (consistent with the other handlers): an unauthenticated
      // caller gets 401, not a 400 leaking body-shape details.
      const userId = await deps.getAuthenticatedUserId(req);
      if (!userId) {
        return new Response(
          JSON.stringify({ error: "Unauthorized" }),
          { status: 401, headers },
        );
      }

      const parsed = await parseRequestBody(req, freeTierSchema, headers);
      if (!parsed.success) return parsed.response;

      const { table } = parsed.data;

      if (!isAllowedTable(table)) {
        // Fail-closed: an attacker could otherwise bypass free-tier enforcement
        // by sending an unknown/misspelled table name. Reject at the boundary.
        console.warn(
          `[validate-free-tier-limit] Unknown table requested: ${table}`,
        );
        return new Response(
          JSON.stringify({ allowed: false, error: "invalid_table" }),
          { status: 400, headers },
        );
      }

      if (!(await deps.checkRateLimit(userId))) {
        return rateLimitedResponse(headers);
      }

      const supabase = deps.createAdminClient();
      const limit = getLimit(table)!;

      const { data: profile } = await supabase
        .from("profiles")
        .select("is_premium, role, grace_period_until")
        .eq("id", userId)
        .single();

      if (isExemptProfile(profile)) {
        return new Response(
          JSON.stringify({ allowed: true }),
          { status: 200, headers },
        );
      }

      let query = supabase
        .from(table)
        .select("id", { count: "exact", head: true })
        .eq("user_id", userId);

      if (shouldFilterDeleted(table)) {
        query = query.eq("is_deleted", false);
      }

      const statusFilter = getStatusFilter(table);
      if (statusFilter) {
        query = statusFilter.length === 1
          ? query.eq("status", statusFilter[0])
          : query.in("status", statusFilter);
      }

      const { count } = await query;
      const result = evaluateLimit(count, limit);

      return new Response(
        JSON.stringify(result),
        { status: result.allowed ? 200 : 403, headers },
      );
    } catch (_error) {
      console.error("[validate-free-tier-limit] Error:", _error);
      return new Response(
        JSON.stringify({ error: "Internal server error" }),
        { status: 500, headers },
      );
    }
  };
}
