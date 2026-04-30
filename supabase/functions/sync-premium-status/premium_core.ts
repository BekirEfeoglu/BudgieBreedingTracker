export const DEFAULT_ENTITLEMENT_ID = "premium";

type JsonObject = Record<string, unknown>;

export interface PremiumStatus {
  isPremium: boolean;
  subscriptionStatus: "premium" | "free";
  subscriptionRecordStatus: "active" | "expired";
  expiresAt: string | null;
  gracePeriodUntil: string | null;
  productIdentifier: string | null;
}

function asObject(value: unknown): JsonObject | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? value as JsonObject
    : null;
}

function stringOrNull(value: unknown): string | null {
  return typeof value === "string" && value.trim().length > 0 ? value : null;
}

function parseDate(value: string | null): Date | null {
  if (value === null) return null;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function addDays(date: Date, days: number): string {
  const copy = new Date(date.getTime());
  copy.setUTCDate(copy.getUTCDate() + days);
  return copy.toISOString();
}

export function resolvePremiumStatus(
  revenueCatPayload: unknown,
  now: Date = new Date(),
  entitlementId = DEFAULT_ENTITLEMENT_ID,
): PremiumStatus {
  const payload = asObject(revenueCatPayload);
  const subscriber = asObject(payload?.subscriber);
  const entitlements = asObject(subscriber?.entitlements);
  const entitlement = asObject(entitlements?.[entitlementId]);

  const expiresAt = stringOrNull(entitlement?.expires_date);
  const graceExpiresAt = stringOrNull(entitlement?.grace_period_expires_date);
  const productIdentifier = stringOrNull(entitlement?.product_identifier);

  const expiryDate = parseDate(expiresAt);
  const graceDate = parseDate(graceExpiresAt);

  const isLifetime = entitlement !== null && expiresAt === null;
  const isActiveByExpiry = expiryDate !== null && expiryDate > now;
  const isPremium = isLifetime || isActiveByExpiry;

  let gracePeriodUntil: string | null = null;
  if (!isPremium) {
    if (graceDate !== null && graceDate > now) {
      gracePeriodUntil = graceDate.toISOString();
    } else if (expiryDate !== null) {
      gracePeriodUntil = addDays(expiryDate, 30);
    }
  }

  return {
    isPremium,
    subscriptionStatus: isPremium ? "premium" : "free",
    subscriptionRecordStatus: isPremium ? "active" : "expired",
    expiresAt,
    gracePeriodUntil,
    productIdentifier,
  };
}
