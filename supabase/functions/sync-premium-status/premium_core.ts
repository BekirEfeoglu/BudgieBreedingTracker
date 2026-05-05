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

export interface PremiumProfileSnapshot {
  is_premium?: unknown;
  subscription_status?: unknown;
  premium_expires_at?: unknown;
  grace_period_until?: unknown;
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

function normalizeInstant(value: unknown): string | null {
  const raw = stringOrNull(value);
  if (raw === null) return null;
  const parsed = new Date(raw);
  return Number.isNaN(parsed.getTime()) ? raw : parsed.toISOString();
}

function sameInstant(left: unknown, right: unknown): boolean {
  return normalizeInstant(left) === normalizeInstant(right);
}

export function profileMatchesPremiumStatus(
  profile: PremiumProfileSnapshot | null | undefined,
  status: PremiumStatus,
): boolean {
  if (!profile) return false;

  return profile.is_premium === status.isPremium &&
    profile.subscription_status === status.subscriptionStatus &&
    sameInstant(profile.premium_expires_at, status.expiresAt) &&
    sameInstant(profile.grace_period_until, status.gracePeriodUntil);
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
