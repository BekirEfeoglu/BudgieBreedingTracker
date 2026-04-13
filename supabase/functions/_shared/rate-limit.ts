/**
 * Shared in-memory rate limiter for Edge Functions.
 *
 * Each function configures its own window and max calls.
 * Timestamps are stored per-user in a Map that auto-prunes on check.
 *
 * Usage:
 *   const limiter = createRateLimiter({ windowMs: 60_000, maxCalls: 20 });
 *   if (!limiter.check(userId)) return rateLimitResponse(req);
 */

interface RateLimiterConfig {
  /** Time window in milliseconds (default: 60_000 = 1 minute) */
  windowMs?: number;
  /** Maximum calls allowed within the window (default: 20) */
  maxCalls?: number;
}

interface RateLimiter {
  /** Returns true if the request is allowed, false if rate-limited. */
  check(key: string): boolean;
}

const DEFAULT_WINDOW_MS = 60_000;
const DEFAULT_MAX_CALLS = 20;
const MAX_STORE_SIZE = 10_000;

export function createRateLimiter(config?: RateLimiterConfig): RateLimiter {
  const windowMs = config?.windowMs ?? DEFAULT_WINDOW_MS;
  const maxCalls = config?.maxCalls ?? DEFAULT_MAX_CALLS;
  const store = new Map<string, number[]>();

  return {
    check(key: string): boolean {
      const now = Date.now();
      const timestamps = (store.get(key) ?? []).filter(
        (t) => now - t < windowMs,
      );

      if (timestamps.length >= maxCalls) {
        store.set(key, timestamps);
        return false;
      }

      // Evict empty keys to prevent unbounded memory growth
      if (timestamps.length === 0) {
        store.delete(key);
      }

      timestamps.push(now);
      store.set(key, timestamps);

      // Periodic full eviction: if store grows too large, prune stale keys
      if (store.size > MAX_STORE_SIZE) {
        for (const [k, v] of store) {
          const active = v.filter((t) => now - t < windowMs);
          if (active.length === 0) {
            store.delete(k);
          } else {
            store.set(k, active);
          }
        }
      }

      return true;
    },
  };
}

/**
 * Build a 429 Too Many Requests response.
 */
export function rateLimitedResponse(
  headers: Record<string, string>,
): Response {
  return new Response(
    JSON.stringify({ error: "Rate limited: too many requests" }),
    { status: 429, headers },
  );
}
