export type ManualPremiumOverride = {
  isPremium: boolean;
  subscriptionStatus: "premium" | "free";
};

/**
 * Resolves an admin-managed premium decision from the subscription row.
 *
 * `provider = manual` is an explicit server-side override. RevenueCat pull
 * and webhook syncs must not replace it until an admin changes the decision.
 */
export function resolveManualPremiumOverride(
  subscription: unknown,
): ManualPremiumOverride | null {
  if (!subscription || typeof subscription !== "object") return null;

  const row = subscription as Record<string, unknown>;
  if (row.provider !== "manual") return null;

  const isPremium = row.plan === "premium" &&
    (row.status === "active" || row.status === "trial");

  return {
    isPremium,
    subscriptionStatus: isPremium ? "premium" : "free",
  };
}
