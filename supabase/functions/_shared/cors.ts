/**
 * Shared CORS header utility for all Edge Functions.
 *
 * Reads ALLOWED_ORIGINS env var (comma-separated) and validates the
 * requesting origin against the whitelist. Only reflects matched origins;
 * unknown origins get an empty Access-Control-Allow-Origin header.
 *
 * Note: CORS only affects browser-based callers. Mobile and server clients
 * bypass CORS entirely. Authentication via JWT is the primary access control.
 */
export function getCorsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get("Origin") ?? "";
  const raw = Deno.env.get("ALLOWED_ORIGINS") ?? "";
  const allowedOrigins = raw
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  const headers: Record<string, string> = {
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Content-Type": "application/json",
    "Vary": "Origin",
  };
  if (allowedOrigins.includes(origin)) {
    headers["Access-Control-Allow-Origin"] = origin;
  }
  return headers;
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
