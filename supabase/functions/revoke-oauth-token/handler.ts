import { corsPreflightResponse, getCorsHeaders } from "../_shared/cors.ts";
import { getAuthenticatedUserId } from "../_shared/auth.ts";
import {
  createRateLimiter,
  createSupabaseRateLimitStore,
  rateLimitedResponse,
} from "../_shared/rate-limit.ts";
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

const rateLimiter = createRateLimiter({
  windowMs: 60_000,
  maxCalls: 5,
  store: createSupabaseRateLimitStore("revoke-oauth-token"),
});

const revokeSchema = z.object({
  provider: z.enum(["google", "apple"]),
  provider_token: z.string().optional(),
  provider_refresh_token: z.string().optional(),
}).refine(
  (data) => data.provider_token || data.provider_refresh_token,
  { message: "Missing token (provider_token or provider_refresh_token)" },
);

export type RevokeOauthTokenDeps = {
  getAuthenticatedUserId(req: Request): Promise<string | null>;
  checkRateLimit(userId: string): boolean | Promise<boolean>;
  fetchImpl: typeof fetch;
  getAppleClientId(): string | undefined;
  getAppleClientSecret(): string | undefined;
};

const defaultDeps: RevokeOauthTokenDeps = {
  getAuthenticatedUserId,
  checkRateLimit: (userId) => rateLimiter.check(userId),
  fetchImpl: fetch,
  getAppleClientId: () => Deno.env.get("APPLE_CLIENT_ID"),
  getAppleClientSecret: () => Deno.env.get("APPLE_CLIENT_SECRET"),
};

async function revokeGoogle(
  token: string,
  headers: Record<string, string>,
  deps: RevokeOauthTokenDeps,
): Promise<Response> {
  const res = await deps.fetchImpl(GOOGLE_REVOKE_URL, {
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
  console.warn(
    `[revoke-oauth-token] Google revoke failed (${res.status}): ${errorBody}`,
  );
  return new Response(
    JSON.stringify({
      success: false,
      provider: "google",
      error: "revocation_failed",
    }),
    { status: 502, headers },
  );
}

async function revokeApple(
  token: string,
  isRefresh: boolean,
  headers: Record<string, string>,
  deps: RevokeOauthTokenDeps,
): Promise<Response> {
  const clientId = deps.getAppleClientId();
  const clientSecret = deps.getAppleClientSecret();

  if (!clientId || !clientSecret) {
    console.warn("[revoke-oauth-token] Apple credentials not configured");
    return new Response(
      JSON.stringify({
        success: false,
        provider: "apple",
        error: "not_configured",
      }),
      { status: 500, headers },
    );
  }

  const params = appleRevokeParams(
    token,
    clientId,
    clientSecret,
    isRefresh,
  );

  const res = await deps.fetchImpl(APPLE_REVOKE_URL, {
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
  console.warn(
    `[revoke-oauth-token] Apple revoke failed (${res.status}): ${errorBody}`,
  );
  return new Response(
    JSON.stringify({
      success: false,
      provider: "apple",
      error: "revocation_failed",
    }),
    { status: 502, headers },
  );
}

export function createRevokeOauthTokenHandler(
  deps: RevokeOauthTokenDeps = defaultDeps,
) {
  return async (req: Request): Promise<Response> => {
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
      const userId = await deps.getAuthenticatedUserId(req);
      if (!userId) {
        return new Response(
          JSON.stringify({ error: "Unauthorized" }),
          { status: 401, headers },
        );
      }

      if (!(await deps.checkRateLimit(userId))) {
        return rateLimitedResponse(headers);
      }

      const parsed = await parseRequestBody(req, revokeSchema, headers);
      if (!parsed.success) return parsed.response;

      const token = pickToken(parsed.data)!;
      const refresh = isRefreshToken(parsed.data);

      if (parsed.data.provider === "google") {
        return await revokeGoogle(token, headers, deps);
      } else {
        return await revokeApple(token, refresh, headers, deps);
      }
    } catch (e) {
      console.error("[revoke-oauth-token] Error:", e);
      return new Response(
        JSON.stringify({ error: "Internal server error" }),
        { status: 500, headers },
      );
    }
  };
}
