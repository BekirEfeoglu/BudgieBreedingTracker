/**
 * Shared RevenueCat REST helpers for Edge Functions.
 *
 * Two callers today:
 *   - sync-premium-status: client-initiated pull (app open / restore purchase)
 *   - revenuecat-webhook: RevenueCat server -> Supabase push on subscription events
 *
 * Both refetch the full subscriber record so resolvePremiumStatus is
 * the single source of truth, regardless of what triggered the sync.
 */

const REVENUECAT_API_BASE = "https://api.revenuecat.com/v1";

export async function fetchRevenueCatSubscriber(
  appUserId: string,
  fetchImpl: typeof fetch = fetch,
): Promise<unknown> {
  const apiKey = Deno.env.get("REVENUECAT_SECRET_API_KEY") ?? "";
  if (!apiKey.startsWith("sk_")) {
    throw new Error("Missing REVENUECAT_SECRET_API_KEY secret");
  }

  const response = await fetchImpl(
    `${REVENUECAT_API_BASE}/subscribers/${encodeURIComponent(appUserId)}`,
    {
      method: "GET",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
    },
  );

  if (response.status === 404) {
    // RC has no record yet (user never made a purchase). Treat as free.
    return { subscriber: { entitlements: {} } };
  }

  if (!response.ok) {
    throw new Error(`RevenueCat lookup failed with status ${response.status}`);
  }

  return await response.json();
}
