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

      const entitlementId = deps.getEntitlementId();
      const revenueCatPayload = await deps.fetchSubscriber(userId);
      const nowDate = deps.now();
      const status = resolvePremiumStatus(
        revenueCatPayload,
        nowDate,
        entitlementId,
      );
      const now = nowDate.toISOString();

      const { data: syncedProfile, error: profileUpdateError } =
        await supabase
          .from("profiles")
          .update({
            is_premium: status.isPremium,
            subscription_status: status.subscriptionStatus,
            premium_expires_at: status.expiresAt,
            grace_period_until: status.gracePeriodUntil,
            updated_at: now,
          })
          .eq("id", userId)
          .select(
            "is_premium, subscription_status, premium_expires_at, grace_period_until",
          )
          .single();

      if (profileUpdateError) {
        throw new Error(
          `Profile premium sync failed: ${profileUpdateError.message}`,
        );
      }

      if (!profileMatchesPremiumStatus(syncedProfile, status)) {
        throw new Error("Profile premium sync verification failed");
      }

      if (status.isPremium) {
        const { error: upsertError } = await supabase
          .from("user_subscriptions")
          .upsert(
            {
              user_id: userId,
              plan: status.productIdentifier ?? "premium",
              status: "active",
              current_period_end: status.expiresAt,
              updated_at: now,
            },
            { onConflict: "user_id" },
          );

        if (upsertError) {
          throw new Error(
            `Subscription upsert failed: ${upsertError.message}`,
          );
        }
      } else {
        const { error: subscriptionUpdateError } = await supabase
          .from("user_subscriptions")
          .update({
            status: status.subscriptionRecordStatus,
            current_period_end: status.expiresAt,
            updated_at: now,
          })
          .eq("user_id", userId);

        if (subscriptionUpdateError) {
          throw new Error(
            `Subscription status sync failed: ${subscriptionUpdateError.message}`,
          );
        }
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
