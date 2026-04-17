// Pure push-delivery helpers — extracted for unit testing.

export const MAX_USER_IDS = 100;
export const MAX_TOKENS = 500;
export const TITLE_MAX = 200;
export const BODY_MAX = 1000;
export const BATCH_SIZE = 50;

export interface PushRequest {
  userId?: string;
  userIds?: string[];
  tokens?: string[];
  title: string;
  body: string;
  payload?: string;
  data?: Record<string, string | number | boolean>;
  dryRun?: boolean;
}

export function normalizeData(
  request: Pick<PushRequest, "payload" | "data">,
): Record<string, string> {
  const normalized: Record<string, string> = {};
  if (request.payload) normalized.payload = request.payload;
  for (const [key, value] of Object.entries(request.data ?? {})) {
    normalized[key] = String(value);
  }
  return normalized;
}

/** De-duplicates tokens and caps at MAX_TOKENS. */
export function clampTokens(tokens: string[]): string[] {
  const unique = [...new Set(tokens)];
  return unique.slice(0, MAX_TOKENS);
}

/**
 * Authorization guard for push targets.
 * Non-admins may only push to themselves (via userId/userIds matching caller).
 * Raw `tokens` arrays bypass the DB ownership check, so they are admin-only.
 * Returns a reason string when the request must be rejected, null when allowed.
 */
export function authorizePushTargets(
  request: Pick<PushRequest, "userId" | "userIds" | "tokens">,
  callerId: string,
  isAdmin: boolean,
): string | null {
  if ((request.tokens?.length ?? 0) > 0 && !isAdmin) {
    return "forbidden: raw tokens require admin role";
  }
  const ids = request.userIds ?? (request.userId ? [request.userId] : []);
  if (isAdmin) return null;
  const foreign = ids.filter((id) => id !== callerId);
  return foreign.length > 0
    ? "forbidden: non-admin caller may only push to self"
    : null;
}

export function validateUserIdsCount(ids: string[]): void {
  if (ids.length > MAX_USER_IDS) {
    throw new Error(
      `Too many userIds: ${ids.length} exceeds limit of ${MAX_USER_IDS}`,
    );
  }
}

/**
 * Collapses a title or body to its allowed size after trimming whitespace.
 */
export function clampText(input: string, max: number): string {
  return input.trim().slice(0, max);
}

/** Maps batch success/failure counts to an HTTP status code. */
export function resultStatus(success: number, failure: number): number {
  if (failure === 0) return 200;
  if (success === 0) return 502;
  return 207; // partial success
}

/** Splits a list into fixed-size batches. */
export function batch<T>(items: T[], size: number = BATCH_SIZE): T[][] {
  if (size <= 0) throw new Error("batch size must be positive");
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += size) {
    out.push(items.slice(i, i + size));
  }
  return out;
}
