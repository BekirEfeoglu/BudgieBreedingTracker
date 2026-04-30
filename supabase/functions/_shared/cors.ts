/**
 * Shared CORS + security header utility for all Edge Functions.
 *
 * Reads ALLOWED_ORIGINS env var (comma-separated) and validates the
 * requesting origin against the whitelist. Only reflects matched origins;
 * unknown origins get an empty Access-Control-Allow-Origin header.
 *
 * Also attaches a baseline of HTTP security headers analogous to what
 * Helmet.js sets in Node — HSTS, X-Content-Type-Options, Referrer-Policy,
 * X-Frame-Options, and a strict CSP that blocks scripts/iframes since
 * Edge Functions only return JSON.
 *
 * Note: CORS only affects browser-based callers. Mobile and server clients
 * bypass CORS entirely. Authentication via JWT is the primary access control.
 */

/** Baseline security headers applied to every Edge Function response. */
const SECURITY_HEADERS: Record<string, string> = {
  // Force HTTPS for 2 years incl. subdomains; preload-eligible.
  "Strict-Transport-Security": "max-age=63072000; includeSubDomains; preload",
  // Prevent MIME sniffing (browsers honor declared Content-Type only).
  "X-Content-Type-Options": "nosniff",
  // Edge Function JSON should never be embedded in a browser frame.
  "X-Frame-Options": "DENY",
  // Don't leak full URL paths via Referer header.
  "Referrer-Policy": "strict-origin-when-cross-origin",
  // No browser features required for JSON responses.
  "Permissions-Policy": "camera=(), geolocation=(), microphone=()",
  // Tight CSP for JSON endpoints — blocks all script/iframe/object loading
  // even if a response is mis-rendered as HTML.
  "Content-Security-Policy":
    "default-src 'none'; frame-ancestors 'none'; base-uri 'none'",
};

export function getCorsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get("Origin") ?? "";
  const raw = Deno.env.get("ALLOWED_ORIGINS") ?? "";
  const allowedOrigins = raw
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  const headers: Record<string, string> = {
    ...SECURITY_HEADERS,
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
