import { getCorsHeaders, corsPreflightResponse } from "../_shared/cors.ts";
import { getAuthenticatedUserId } from "../_shared/auth.ts";
import { createRateLimiter, rateLimitedResponse } from "../_shared/rate-limit.ts";
import { z } from "npm:zod@3.24.4";
import { parseRequestBody } from "../_shared/validation.ts";
import {
  APPLE_REVOKE_URL,
  appleRevokeParams,
  GOOGLE_REVOKE_URL,
  googleRevokeBody,
  isRefreshToken,
  pickToken,
} from "./revoke_core.ts";

const rateLimiter = createRateLimiter({ windowMs: 60_000, maxCalls: 5 });

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

    const revokeSchema = z.object({
      provider: z.enum(["google", "apple"]),
      provider_token: z.string().optional(),
      provider_refresh_token: z.string().optional(),
    }).refine(
      (data) => data.provider_token || data.provider_refresh_token,
      { message: "Missing token (provider_token or provider_refresh_token)" },
    );

    const parsed = await parseRequestBody(req, revokeSchema, headers);
    if (!parsed.success) return parsed.response;

    const token = pickToken(parsed.data)!;
    const refresh = isRefreshToken(parsed.data);

    if (parsed.data.provider === "google") {
      return await revokeGoogle(token, headers);
    } else {
      return await revokeApple(token, refresh, headers);
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
    body: googleRevokeBody(token),
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
    { status: 502, headers },
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
      JSON.stringify({ success: false, provider: "apple", error: "not_configured" }),
      { status: 500, headers },
    );
  }

  const params = appleRevokeParams(token, clientId, clientSecret, isRefreshToken);

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
    { status: 502, headers },
  );
}
