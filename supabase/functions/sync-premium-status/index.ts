import { corsPreflightResponse, getCorsHeaders } from "../_shared/cors.ts";
import {
  createSupabaseAdmin,
  getAuthenticatedUserId,
} from "../_shared/auth.ts";
import {
  createRateLimiter,
  rateLimitedResponse,
} from "../_shared/rate-limit.ts";
import {
  DEFAULT_ENTITLEMENT_ID,
  resolvePremiumStatus,
} from "./premium_core.ts";

const rateLimiter = createRateLimiter({ windowMs: 60_000, maxCalls: 10 });

async function fetchRevenueCatSubscriber(userId: string): Promise<unknown> {
  const apiKey = Deno.env.get("REVENUECAT_SECRET_API_KEY") ?? "";
  if (!apiKey.startsWith("sk_")) {
    throw new Error("Missing REVENUECAT_SECRET_API_KEY secret");
  }

  const response = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(userId)}`,
    {
      method: "GET",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
    },
  );

  if (response.status === 404) {
    return { subscriber: { entitlements: {} } };
  }

  if (!response.ok) {
    throw new Error(`RevenueCat lookup failed with status ${response.status}`);
  }

  return await response.json();
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return corsPreflightResponse(req);

  const headers = getCorsHeaders(req);

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers },
    );
  }

  try {
    const userId = await getAuthenticatedUserId(req);
    if (!userId) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers },
      );
    }

    if (!rateLimiter.check(userId)) return rateLimitedResponse(headers);

    const supabase = createSupabaseAdmin();
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

    const entitlementId = Deno.env.get("REVENUECAT_PREMIUM_ENTITLEMENT_ID") ??
      DEFAULT_ENTITLEMENT_ID;
    const revenueCatPayload = await fetchRevenueCatSubscriber(userId);
    const status = resolvePremiumStatus(
      revenueCatPayload,
      new Date(),
      entitlementId,
    );
    const now = new Date().toISOString();

    const { error: profileUpdateError } = await supabase
      .from("profiles")
      .update({
        is_premium: status.isPremium,
        subscription_status: status.subscriptionStatus,
        premium_expires_at: status.expiresAt,
        grace_period_until: status.gracePeriodUntil,
        updated_at: now,
      })
      .eq("id", userId);

    if (profileUpdateError) {
      throw new Error(
        `Profile premium sync failed: ${profileUpdateError.message}`,
      );
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
});
