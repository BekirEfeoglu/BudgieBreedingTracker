/**
 * Shared CORS header utility for all Edge Functions.
 *
 * Reads ALLOWED_ORIGINS env var (comma-separated) and validates the
 * requesting origin against the whitelist. Only reflects matched origins;
 * unknown origins get an empty Access-Control-Allow-Origin header.
 */
export function getCorsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get("Origin") ?? "";
  const raw = Deno.env.get("ALLOWED_ORIGINS") ?? "";
  const allowedOrigins = raw
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  const resolvedOrigin = allowedOrigins.includes(origin) ? origin : "";
  return {
    "Access-Control-Allow-Origin": resolvedOrigin,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Content-Type": "application/json",
  };
}

/**
 * Standard CORS preflight response. Call at the top of every handler:
 *
 * ```ts
 * if (req.method === "OPTIONS") return corsPreflightResponse(req);
 * ```
 */
export function corsPreflightResponse(req: Request): Response {
  return new Response("ok", { headers: getCorsHeaders(req) });
}
