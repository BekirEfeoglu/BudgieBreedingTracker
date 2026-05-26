/**
 * Pure logic for the revenuecat-webhook Edge Function.
 *
 * Kept network/env-free so it can be unit tested without a Deno runtime
 * pulling REVENUECAT_WEBHOOK_AUTH_TOKEN at import time.
 */

export interface ParsedWebhookEvent {
  type: string;
  appUserId: string;
  eventId: string | null;
  isTest: boolean;
}

const PREMIUM_RELEVANT_EVENT_TYPES = new Set([
  "INITIAL_PURCHASE",
  "NON_RENEWING_PURCHASE",
  "RENEWAL",
  "PRODUCT_CHANGE",
  "CANCELLATION",
  "UNCANCELLATION",
  "BILLING_ISSUE",
  "SUBSCRIBER_ALIAS",
  "SUBSCRIPTION_PAUSED",
  "EXPIRATION",
  "TRANSFER",
  "TEMPORARY_ENTITLEMENT_GRANT",
  "SUBSCRIPTION_EXTENDED",
]);

const TEST_EVENT_TYPE = "TEST";

function asObject(value: unknown): Record<string, unknown> | null {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : null;
}

function stringOrNull(value: unknown): string | null {
  return typeof value === "string" && value.trim().length > 0 ? value : null;
}

/**
 * Constant-time string comparison. Avoids leaking timing info that could
 * help an attacker probe the webhook secret one byte at a time.
 */
export function constantTimeEquals(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

/**
 * Verify the `Authorization: Bearer <token>` header against the configured
 * shared secret. Returns false on missing/malformed headers and on mismatch.
 */
export function verifyWebhookAuth(
  authHeader: string | null,
  expectedToken: string,
): boolean {
  if (expectedToken.length < 16) return false;
  if (!authHeader) return false;
  const prefix = "Bearer ";
  if (!authHeader.startsWith(prefix)) return false;
  const provided = authHeader.slice(prefix.length).trim();
  if (provided.length === 0) return false;
  return constantTimeEquals(provided, expectedToken);
}

/**
 * Pull `event.type` and `event.app_user_id` out of a RevenueCat webhook body.
 * Returns null when the payload doesn't look like a RC webhook event so the
 * caller can decide whether to 200 (test/unknown) or 400 (malformed).
 */
export function parseWebhookEvent(body: unknown): ParsedWebhookEvent | null {
  const payload = asObject(body);
  const event = asObject(payload?.event);
  if (!event) return null;

  const rawType = stringOrNull(event.type);
  if (!rawType) return null;
  const type = rawType.toUpperCase();

  const isTest = type === TEST_EVENT_TYPE;

  // RC test events may omit app_user_id. For real events, require it.
  const appUserId = stringOrNull(event.app_user_id) ?? "";
  if (!isTest && appUserId.length === 0) return null;

  return {
    type,
    appUserId,
    eventId: stringOrNull(event.id),
    isTest,
  };
}

/**
 * True when receiving this event should trigger a premium-status refetch.
 * Unknown / future event types still trigger a refetch (defensive default).
 */
export function shouldRefetchPremium(eventType: string): boolean {
  if (eventType === TEST_EVENT_TYPE) return false;
  if (PREMIUM_RELEVANT_EVENT_TYPES.has(eventType)) return true;
  // Unknown event type — refetch defensively. RC may add new types over
  // time and we'd rather over-sync than miss a state change.
  return true;
}
