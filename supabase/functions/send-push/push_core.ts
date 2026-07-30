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
  /**
   * Opt-in: when true, recipients currently inside their quiet-hours window are
   * dropped from delivery (§5.2). Omitted/false = always deliver, so critical
   * notifications simply leave it unset. Fail-open on any missing config.
   */
  respectQuietHours?: boolean;
}

export interface MessagePushResolution {
  request?: PushRequest;
  error?: string;
  status?: number;
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

/** Extracts the most specific FCM error status/code from a v1 error body. */
export function parseFcmErrorStatus(errorText: string): string | null {
  try {
    const parsed = JSON.parse(errorText) as {
      error?: {
        status?: unknown;
        details?: Array<Record<string, unknown>>;
      };
    };
    for (const detail of parsed.error?.details ?? []) {
      const errorCode = detail.errorCode;
      if (typeof errorCode === "string" && errorCode.trim().length > 0) {
        return errorCode;
      }
    }
    const status = parsed.error?.status;
    return typeof status === "string" && status.trim().length > 0
      ? status
      : null;
  } catch {
    return null;
  }
}

/** Whether the FCM error means the device token should be deactivated. */
export function isPermanentFcmTokenError(status: string | null): boolean {
  return status === "UNREGISTERED" ||
    status === "INVALID_ARGUMENT" ||
    status === "NOT_FOUND" ||
    status === "SENDER_ID_MISMATCH";
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

// ---------------------------------------------------------------------------
// Quiet hours (server-side do-not-disturb) — §5.2
//
// A recipient's quiet-hours window lives in THEIR local time. The client
// (NotificationRateLimiter) already suppresses *local* notifications inside
// this window, but push arrives from FCM and bypasses that check. These pure
// helpers let send-push hold back opt-in ("respectQuietHours") notifications
// for recipients currently inside their window. Everything here FAILS OPEN:
// any missing/disabled/invalid config means "deliver". Critical notifications
// never reach this code — the caller decides suppressibility.
// ---------------------------------------------------------------------------

/** A recipient's quiet-hours window (stored in `profiles.quiet_hours`). */
export interface QuietHours {
  enabled: boolean;
  startHour: number; // 0-23, recipient local time
  endHour: number; // 0-23, recipient local time
  timeZone: string; // IANA name, e.g. "Europe/Istanbul"
}

/**
 * Whether `localHour` (0-23) falls inside the quiet window. Mirrors the client
 * `NotificationRateLimiter.isDoNotDisturbActive` wraparound logic exactly:
 *  - start < end   -> [start, end)             same-day window
 *  - start > end   -> [start, 24) ∪ [0, end)   overnight window
 *  - start == end  -> empty (DND effectively off)
 */
export function isWithinQuietHours(
  localHour: number,
  startHour: number,
  endHour: number,
): boolean {
  if (startHour === endHour) return false;
  if (startHour > endHour) return localHour >= startHour || localHour < endHour;
  return localHour >= startHour && localHour < endHour;
}

/**
 * The recipient's local hour (0-23) for `nowUtc` in `timeZone`, or null when
 * the timezone is invalid (caller then fails open = deliver).
 */
export function localHourInZone(nowUtc: Date, timeZone: string): number | null {
  try {
    const value = new Intl.DateTimeFormat("en-US", {
      timeZone,
      hour: "2-digit",
      hour12: false,
    })
      .formatToParts(nowUtc)
      .find((p) => p.type === "hour")?.value;
    if (value === undefined) return null;
    const hour = Number(value);
    if (!Number.isFinite(hour)) return null;
    return hour % 24; // some ICU builds emit "24" at local midnight
  } catch {
    return null;
  }
}

/**
 * Whether a push to a recipient should be held back right now because they are
 * inside their quiet-hours window. FAIL-OPEN on any missing/disabled/invalid
 * config.
 */
export function isSuppressedByQuietHours(
  quiet: QuietHours | null | undefined,
  nowUtc: Date,
): boolean {
  if (!quiet || quiet.enabled !== true) return false;
  const { startHour, endHour, timeZone } = quiet;
  if (!Number.isInteger(startHour) || !Number.isInteger(endHour)) return false;
  if (startHour < 0 || startHour > 23 || endHour < 0 || endHour > 23) {
    return false;
  }
  if (typeof timeZone !== "string" || timeZone.length === 0) return false;
  const localHour = localHourInZone(nowUtc, timeZone);
  if (localHour === null) return false;
  return isWithinQuietHours(localHour, startHour, endHour);
}
