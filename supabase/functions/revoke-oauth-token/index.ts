import { getCorsHeaders, corsPreflightResponse } from "../_shared/cors.ts";
import { getAuthenticatedUserId } from "../_shared/auth.ts";
import { createRateLimiter, rateLimitedResponse } from "../_shared/rate-limit.ts";

const rateLimiter = createRateLimiter({ windowMs: 60_000, maxCalls: 5 });

const GOOGLE_REVOKE_URL = "https://oauth2.googleapis.com/revoke";
const APPLE_REVOKE_URL = "https://appleid.apple.com/auth/revoke";

interface RevokeRequest {
  provider: "google" | "apple";
  provider_token?: string;
  provider_refresh_token?: string;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return corsPreflightResponse(req);

  const headers = getCorsHeaders(req);

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers,
    });
  }

  try {
    // Verify authenticated user — only the token owner should revoke
    const userId = await getAuthenticatedUserId(req);
    if (!userId) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers },
      );
    }

    if (!rateLimiter.check(userId)) return rateLimitedResponse(headers);

    const body: RevokeRequest = await req.json();
    const { provider, provider_token, provider_refresh_token } = body;

    if (!provider) {
      return new Response(
        JSON.stringify({ error: "Missing 'provider' field" }),
        { status: 400, headers },
      );
    }

    const token = provider_token || provider_refresh_token;
    if (!token) {
      return new Response(
        JSON.stringify({
          error: "Missing token (provider_token or provider_refresh_token)",
        }),
        { status: 400, headers },
      );
    }

    if (provider === "google") {
      return await revokeGoogle(token, headers);
    } else if (provider === "apple") {
      return await revokeApple(token, !!provider_refresh_token, headers);
    } else {
      return new Response(
        JSON.stringify({ error: `Unsupported provider: ${provider}` }),
        { status: 400, headers },
      );
    }
  } catch (e) {
    console.error("[revoke-oauth-token] Error:", e);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers },
    );
  }
});

async function revokeGoogle(
  token: string,
  headers: Record<string, string>,
): Promise<Response> {
  const res = await fetch(GOOGLE_REVOKE_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `token=${encodeURIComponent(token)}`,
  });

  if (res.ok) {
    console.log("[revoke-oauth-token] Google token revoked successfully");
    return new Response(
      JSON.stringify({ success: true, provider: "google" }),
      { status: 200, headers },
    );
  }

  const errorBody = await res.text();
  console.warn(`[revoke-oauth-token] Google revoke failed (${res.status}): ${errorBody}`);
  return new Response(
    JSON.stringify({ success: false, provider: "google", error: "revocation_failed" }),
    { status: 200, headers },
  );
}

async function revokeApple(
  token: string,
  isRefreshToken: boolean,
  headers: Record<string, string>,
): Promise<Response> {
  const clientId = Deno.env.get("APPLE_CLIENT_ID");
  const clientSecret = Deno.env.get("APPLE_CLIENT_SECRET");

  if (!clientId || !clientSecret) {
    console.warn("[revoke-oauth-token] Apple credentials not configured");
    return new Response(
      JSON.stringify({ success: false, provider: "apple", error: "Apple credentials not configured on server" }),
      { status: 200, headers },
    );
  }

  const params = new URLSearchParams({
    client_id: clientId,
    client_secret: clientSecret,
    token: token,
    token_type_hint: isRefreshToken ? "refresh_token" : "access_token",
  });

  const res = await fetch(APPLE_REVOKE_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: params.toString(),
  });

  if (res.ok) {
    console.log("[revoke-oauth-token] Apple token revoked successfully");
    return new Response(
      JSON.stringify({ success: true, provider: "apple" }),
      { status: 200, headers },
    );
  }

  const errorBody = await res.text();
  console.warn(`[revoke-oauth-token] Apple revoke failed (${res.status}): ${errorBody}`);
  return new Response(
    JSON.stringify({ success: false, provider: "apple", error: "revocation_failed" }),
    { status: 200, headers },
  );
}
