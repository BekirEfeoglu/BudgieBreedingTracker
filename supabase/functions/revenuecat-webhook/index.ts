// deno-lint-ignore-file no-explicit-any
import { corsPreflightResponse, getCorsHeaders } from "../_shared/cors.ts";
import { createSupabaseAdmin } from "../_shared/auth.ts";
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
 *   4. Refetch full subscriber state from RC REST API
 *   5. resolvePremiumStatus + write to profiles + user_subscriptions
 *      (mirrors sync-premium-status so client pull and server push converge)
 *
 * Errors are logged but the response is always 200 unless auth fails,
 * so RC doesn't retry indefinitely on a transient DB blip. Real failures
 * surface in the next client pull on app open.
 */
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return corsPreflightResponse(req);

  const headers = getCorsHeaders(req);

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers },
    );
  }

  const expectedToken = Deno.env.get("REVENUECAT_WEBHOOK_AUTH_TOKEN") ?? "";
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
    const supabase = createSupabaseAdmin();

    // Verify the app_user_id maps to a real Supabase user before writing.
    // RC may forward aliases or sandbox IDs that don't exist in our DB.
    const { data: profile, error: profileLookupError } = await supabase
      .from("profiles")
      .select("id, role")
      .eq("id", event.appUserId)
      .maybeSingle();

    if (profileLookupError) {
      console.error(
        "[revenuecat-webhook] Profile lookup failed:",
        profileLookupError.message,
      );
      return new Response(
        JSON.stringify({ success: false, error: "profile_lookup_failed" }),
        { status: 200, headers },
      );
    }

    if (!profile) {
      console.warn(
        `[revenuecat-webhook] No profile for app_user_id=${event.appUserId} (event=${event.type})`,
      );
      return new Response(
        JSON.stringify({ success: false, unknown_user: true }),
        { status: 200, headers },
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

    const entitlementId = Deno.env.get("REVENUECAT_PREMIUM_ENTITLEMENT_ID") ??
      DEFAULT_ENTITLEMENT_ID;
    const revenueCatPayload = await fetchRevenueCatSubscriber(event.appUserId);
    const status = resolvePremiumStatus(
      revenueCatPayload,
      new Date(),
      entitlementId,
    );
    const now = new Date().toISOString();

    const { data: syncedProfile, error: profileUpdateError } = await supabase
      .from("profiles")
      .update({
        is_premium: status.isPremium,
        subscription_status: status.subscriptionStatus,
        premium_expires_at: status.expiresAt,
        grace_period_until: status.gracePeriodUntil,
        updated_at: now,
      })
      .eq("id", event.appUserId)
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
            user_id: event.appUserId,
            plan: status.productIdentifier ?? "premium",
            status: "active",
            current_period_end: status.expiresAt,
            updated_at: now,
          },
          { onConflict: "user_id" },
        );

      if (upsertError) {
        throw new Error(`Subscription upsert failed: ${upsertError.message}`);
      }
    } else {
      const { error: subscriptionUpdateError } = await supabase
        .from("user_subscriptions")
        .update({
          status: status.subscriptionRecordStatus,
          current_period_end: status.expiresAt,
          updated_at: now,
        })
        .eq("user_id", event.appUserId);

      if (subscriptionUpdateError) {
        throw new Error(
          `Subscription status sync failed: ${subscriptionUpdateError.message}`,
        );
      }
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
    // Return 200 so RC doesn't enter retry storm; client pull will repair.
    return new Response(
      JSON.stringify({ success: false, error: "internal_error" }),
      { status: 200, headers },
    );
  }
});
