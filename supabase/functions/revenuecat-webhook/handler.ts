// deno-lint-ignore-file no-explicit-any
import { corsPreflightResponse, getCorsHeaders } from "../_shared/cors.ts";
import { createSupabaseAdmin } from "../_shared/auth.ts";
import { resolveManualPremiumOverride } from "../_shared/premium_override.ts";
import { fetchRevenueCatSubscriber } from "../_shared/revenuecat.ts";
import {
  DEFAULT_ENTITLEMENT_ID,
  profileMatchesPremiumStatus,
  resolvePremiumStatus,
} from "../sync-premium-status/premium_core.ts";
import {
  parseWebhookEvent,
  shouldRefetchPremium,
  verifyWebhookAuth,
} from "./webhook_core.ts";

type SupabaseAdminClient = any;

export type RevenueCatWebhookDeps = {
  getWebhookAuthToken(): string;
  getEntitlementId(): string;
  createAdminClient(): SupabaseAdminClient;
  fetchSubscriber(appUserId: string): Promise<unknown>;
  now(): Date;
};

const defaultDeps: RevenueCatWebhookDeps = {
  getWebhookAuthToken: () =>
    Deno.env.get("REVENUECAT_WEBHOOK_AUTH_TOKEN") ?? "",
  getEntitlementId: () =>
    Deno.env.get("REVENUECAT_PREMIUM_ENTITLEMENT_ID") ??
      DEFAULT_ENTITLEMENT_ID,
  createAdminClient: createSupabaseAdmin,
  fetchSubscriber: fetchRevenueCatSubscriber,
  now: () => new Date(),
};

/**
 * RevenueCat -> Supabase webhook receiver.
 *
 * Auth model differs from every other Edge Function in this repo:
 * verify_jwt = false (config.toml) because RevenueCat does not send a
 * Supabase JWT — instead, RC sends a static `Authorization: Bearer <secret>`
 * header that we verify against REVENUECAT_WEBHOOK_AUTH_TOKEN.
 *
 * Flow:
 *   1. Verify shared secret (constant-time)
 *   2. Parse event { type, app_user_id }
 *   3. If test event, ack with 200 (lets RC dashboard verify reachability)
 *   4. Preserve any explicit admin-managed premium override
 *   5. Otherwise refetch full subscriber state from RC REST API
 *   6. resolvePremiumStatus + write to profiles + user_subscriptions
 *      (mirrors sync-premium-status so client pull and server push converge)
 *
 * Transient processing failures return 503 so RevenueCat can retry. The write
 * is idempotent because every delivery refetches the complete subscriber state
 * and applies it through the atomic per-user RPC.
 */
export function createRevenueCatWebhookHandler(
  deps: RevenueCatWebhookDeps = defaultDeps,
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

    const expectedToken = deps.getWebhookAuthToken();
    if (expectedToken.length < 16) {
      console.error(
        "[revenuecat-webhook] REVENUECAT_WEBHOOK_AUTH_TOKEN missing or too short",
      );
      return new Response(
        JSON.stringify({ error: "Server misconfigured" }),
        { status: 500, headers },
      );
    }

    if (!verifyWebhookAuth(req.headers.get("Authorization"), expectedToken)) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers },
      );
    }

    let body: unknown;
    try {
      body = await req.json();
    } catch {
      return new Response(
        JSON.stringify({ error: "Invalid JSON" }),
        { status: 400, headers },
      );
    }

    const event = parseWebhookEvent(body);
    if (!event) {
      return new Response(
        JSON.stringify({ error: "Malformed event payload" }),
        { status: 400, headers },
      );
    }

    if (event.isTest) {
      console.log(
        "[revenuecat-webhook] TEST event received — auth + reachability OK",
      );
      return new Response(
        JSON.stringify({ success: true, test: true }),
        { status: 200, headers },
      );
    }

    if (!shouldRefetchPremium(event.type)) {
      return new Response(
        JSON.stringify({ success: true, skipped: true, type: event.type }),
        { status: 200, headers },
      );
    }

    try {
      const supabase = deps.createAdminClient();

      // Verify the app_user_id maps to a real Supabase user before writing.
      // RC may forward aliases or sandbox IDs that don't exist in our DB.
      const { data: profile, error: profileLookupError } = await supabase
        .from("profiles")
        .select("id, role")
        .eq("id", event.appUserId)
        .maybeSingle();

      if (profileLookupError) {
        throw new Error(
          `Profile lookup failed: ${profileLookupError.message}`,
        );
      }

      if (!profile) {
        console.warn(
          `[revenuecat-webhook] No profile for app_user_id=${event.appUserId} (event=${event.type})`,
        );
        return new Response(
          JSON.stringify({ success: false, unknown_user: true }),
          {
            status: 503,
            headers: { ...headers, "Retry-After": "60" },
          },
        );
      }

      // Founders/admins bypass premium gates regardless of RC state —
      // mirror sync-premium-status's role short-circuit.
      if (profile.role && ["admin", "founder"].includes(profile.role)) {
        return new Response(
          JSON.stringify({ success: true, role_based: true }),
          { status: 200, headers },
        );
      }

      const { data: subscription, error: subscriptionLookupError } =
        await supabase
          .from("user_subscriptions")
          .select("plan, status, provider")
          .eq("user_id", event.appUserId)
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
            type: event.type,
            is_premium: manualOverride.isPremium,
            manual_override: true,
          }),
          { status: 200, headers },
        );
      }

      const entitlementId = deps.getEntitlementId();
      const revenueCatPayload = await deps.fetchSubscriber(event.appUserId);
      const nowDate = deps.now();
      const status = resolvePremiumStatus(
        revenueCatPayload,
        nowDate,
        entitlementId,
      );

      const { data: appliedStatus, error: applyError } = await supabase.rpc(
        "apply_verified_premium_status",
        {
          p_user_id: event.appUserId,
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
            type: event.type,
            is_premium: appliedStatus.is_premium === true,
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
          type: event.type,
          is_premium: status.isPremium,
        }),
        { status: 200, headers },
      );
    } catch (error) {
      console.error("[revenuecat-webhook] Error:", error);
      return new Response(
        JSON.stringify({ success: false, error: "internal_error" }),
        {
          status: 503,
          headers: { ...headers, "Retry-After": "60" },
        },
      );
    }
  };
}
