/**
 * Shared rate limiter for Edge Functions.
 *
 * Default tests and local development use an in-memory store. Production
 * functions should pass createSupabaseRateLimitStore("<function-name>") so
 * limits are enforced across Edge Function instances.
 */

export interface RateLimitStore {
  check(
    key: string,
    windowMs: number,
    maxCalls: number,
  ): boolean | Promise<boolean>;
}

interface RateLimiterConfig {
  /** Time window in milliseconds (default: 60_000 = 1 minute) */
  windowMs?: number;
  /** Maximum calls allowed within the window (default: 20) */
  maxCalls?: number;
  /** Optional durable store; defaults to in-memory for tests/local use. */
  store?: RateLimitStore;
}

interface RateLimiter {
  /** Returns true if the request is allowed, false if rate-limited. */
  check(key: string): boolean | Promise<boolean>;
}

const DEFAULT_WINDOW_MS = 60_000;
const DEFAULT_MAX_CALLS = 20;
const MAX_STORE_SIZE = 10_000;

class InMemoryRateLimitStore implements RateLimitStore {
  private readonly store = new Map<string, number[]>();

  check(key: string, windowMs: number, maxCalls: number): boolean {
    const now = Date.now();
    const timestamps = (this.store.get(key) ?? []).filter(
      (t) => now - t < windowMs,
    );

    if (timestamps.length >= maxCalls) {
      this.store.set(key, timestamps);
      return false;
    }

    if (timestamps.length === 0) {
      this.store.delete(key);
    }

    timestamps.push(now);
    this.store.set(key, timestamps);

    if (this.store.size > MAX_STORE_SIZE) {
      for (const [k, v] of this.store) {
        const active = v.filter((t) => now - t < windowMs);
        if (active.length === 0) {
          this.store.delete(k);
        } else {
          this.store.set(k, active);
        }
      }
    }

    return true;
  }
}

class SupabaseRateLimitStore implements RateLimitStore {
  private readonly fallback = new InMemoryRateLimitStore();

  constructor(
    private readonly supabaseUrl: string,
    private readonly serviceRoleKey: string,
    private readonly namespace: string,
  ) {}

  async check(
    key: string,
    windowMs: number,
    maxCalls: number,
  ): Promise<boolean> {
    try {
      const response = await fetch(
        `${this.supabaseUrl}/rest/v1/rpc/check_edge_rate_limit`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "apikey": this.serviceRoleKey,
            "Authorization": `Bearer ${this.serviceRoleKey}`,
          },
          body: JSON.stringify({
            p_key: `${this.namespace}:${key}`,
            p_window_ms: windowMs,
            p_max_calls: maxCalls,
          }),
        },
      );

      if (!response.ok) {
        console.warn(
          `Durable rate-limit check failed: ${response.status}`,
        );
        return this.fallback.check(key, windowMs, maxCalls);
      }

      return await response.json() === true;
    } catch (error) {
      console.warn(`Durable rate-limit check failed: ${error}`);
      return this.fallback.check(key, windowMs, maxCalls);
    }
  }
}

export function createSupabaseRateLimitStore(
  namespace: string,
): RateLimitStore {
  const url = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (
    url == null || url === "" || serviceRoleKey == null ||
    serviceRoleKey === ""
  ) {
    console.warn(
      "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY missing; " +
        "using in-memory Edge Function rate limits",
    );
    return new InMemoryRateLimitStore();
  }

  return new SupabaseRateLimitStore(url, serviceRoleKey, namespace);
}

export function createRateLimiter(config?: RateLimiterConfig): RateLimiter {
  const windowMs = config?.windowMs ?? DEFAULT_WINDOW_MS;
  const maxCalls = config?.maxCalls ?? DEFAULT_MAX_CALLS;
  const store = config?.store ?? new InMemoryRateLimitStore();

  return {
    check(key: string): boolean | Promise<boolean> {
      return store.check(key, windowMs, maxCalls);
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
