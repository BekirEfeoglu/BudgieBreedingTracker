// deno-lint-ignore-file no-explicit-any
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
import { resolveManualPremiumOverride } from "../_shared/premium_override.ts";
import { fetchRevenueCatSubscriber } from "../_shared/revenuecat.ts";
import {
  DEFAULT_ENTITLEMENT_ID,
  profileMatchesPremiumStatus,
  resolvePremiumStatus,
} from "./premium_core.ts";

const rateLimiter = createRateLimiter({
  windowMs: 60_000,
  maxCalls: 10,
  store: createSupabaseRateLimitStore("sync-premium-status"),
});

type SupabaseAdminClient = any;

export type SyncPremiumStatusDeps = {
  getAuthenticatedUserId(req: Request): Promise<string | null>;
  checkRateLimit(userId: string): boolean | Promise<boolean>;
  createAdminClient(): SupabaseAdminClient;
  getEntitlementId(): string;
  fetchSubscriber(userId: string): Promise<unknown>;
  now(): Date;
};

const defaultDeps: SyncPremiumStatusDeps = {
  getAuthenticatedUserId,
  checkRateLimit: (userId) => rateLimiter.check(userId),
  createAdminClient: createSupabaseAdmin,
  getEntitlementId: () =>
    Deno.env.get("REVENUECAT_PREMIUM_ENTITLEMENT_ID") ??
      DEFAULT_ENTITLEMENT_ID,
  fetchSubscriber: fetchRevenueCatSubscriber,
  now: () => new Date(),
};

export function createSyncPremiumStatusHandler(
  deps: SyncPremiumStatusDeps = defaultDeps,
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
      const userId = await deps.getAuthenticatedUserId(req);
      if (!userId) {
        return new Response(
          JSON.stringify({ error: "Unauthorized" }),
          { status: 401, headers },
        );
      }

      if (!(await deps.checkRateLimit(userId))) {
        return rateLimitedResponse(headers);
      }

      const supabase = deps.createAdminClient();
      const { data: profile, error: profileError } = await supabase
        .from("profiles")
        .select("role")
        .eq("id", userId)
        .single();

      if (profileError) {
        throw new Error(`Profile lookup failed: ${profileError.message}`);
      }

      if (profile && ["admin", "founder"].includes(profile.role)) {
        return new Response(
          JSON.stringify({
            success: true,
            is_premium: true,
            subscription_status: "premium",
            role_based: true,
          }),
          { status: 200, headers },
        );
      }

      const { data: subscription, error: subscriptionLookupError } =
        await supabase
          .from("user_subscriptions")
          .select("plan, status, provider")
          .eq("user_id", userId)
          .maybeSingle();

      if (subscriptionLookupError) {
        throw new Error(
          `Subscription lookup failed: ${subscriptionLookupError.message}`,
        );
      }

      const manualOverride = resolveManualPremiumOverride(subscription);
      if (manualOverride) {
        return new Response(
          JSON.stringify({
            success: true,
            is_premium: manualOverride.isPremium,
            subscription_status: manualOverride.subscriptionStatus,
            premium_expires_at: null,
            grace_period_until: null,
            manual_override: true,
          }),
          { status: 200, headers },
        );
      }

      const entitlementId = deps.getEntitlementId();
      const revenueCatPayload = await deps.fetchSubscriber(userId);
      const nowDate = deps.now();
      const status = resolvePremiumStatus(
        revenueCatPayload,
        nowDate,
        entitlementId,
      );

      const { data: appliedStatus, error: applyError } = await supabase.rpc(
        "apply_verified_premium_status",
        {
          p_user_id: userId,
          p_is_premium: status.isPremium,
          p_subscription_status: status.subscriptionStatus,
          p_premium_expires_at: status.expiresAt,
          p_grace_period_until: status.gracePeriodUntil,
          p_plan: status.productIdentifier ?? "premium",
          p_subscription_record_status: status.subscriptionRecordStatus,
        },
      );

      if (applyError) {
        throw new Error(
          `Atomic premium sync failed: ${applyError.message}`,
        );
      }

      if (appliedStatus?.manual_override === true) {
        return new Response(
          JSON.stringify({
            success: true,
            is_premium: appliedStatus.is_premium === true,
            subscription_status: appliedStatus.subscription_status,
            premium_expires_at: null,
            grace_period_until: null,
            manual_override: true,
          }),
          { status: 200, headers },
        );
      }

      if (!profileMatchesPremiumStatus(appliedStatus, status)) {
        throw new Error("Profile premium sync verification failed");
      }

      return new Response(
        JSON.stringify({
          success: true,
          is_premium: status.isPremium,
          subscription_status: status.subscriptionStatus,
          premium_expires_at: status.expiresAt,
          grace_period_until: status.gracePeriodUntil,
        }),
        { status: 200, headers },
      );
    } catch (error) {
      console.error("[sync-premium-status] Error:", error);
      return new Response(
        JSON.stringify({ error: "Internal server error" }),
        { status: 500, headers },
      );
    }
  };
}
