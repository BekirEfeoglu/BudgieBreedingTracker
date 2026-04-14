import { getCorsHeaders, corsPreflightResponse } from "../_shared/cors.ts";
import {
  getAuthenticatedUserId,
  requireAdminRole,
  createSupabaseAdmin,
} from "../_shared/auth.ts";
import { createRateLimiter, rateLimitedResponse } from "../_shared/rate-limit.ts";
import { SignJWT, importPKCS8 } from "npm:jose@5.9.6";

const rateLimiter = createRateLimiter({ windowMs: 60_000, maxCalls: 10 });

type PushRequest = {
  userId?: string;
  userIds?: string[];
  tokens?: string[];
  title: string;
  body: string;
  payload?: string;
  data?: Record<string, string | number | boolean>;
  dryRun?: boolean;
};

async function createAccessToken(): Promise<string> {
  const rawServiceAccount = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON") ?? "";
  if (!rawServiceAccount) {
    throw new Error("Missing GOOGLE_SERVICE_ACCOUNT_JSON secret");
  }

  const serviceAccount = JSON.parse(rawServiceAccount);
  const now = Math.floor(Date.now() / 1000);
  const privateKey = await importPKCS8(serviceAccount.private_key, "RS256");

  const jwt = await new SignJWT({
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(serviceAccount.client_email)
    .setSubject(serviceAccount.client_email)
    .setAudience(serviceAccount.token_uri)
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(privateKey);

  const response = await fetch(serviceAccount.token_uri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!response.ok) {
    throw new Error(`Google OAuth failed: ${response.status} ${await response.text()}`);
  }

  const json = await response.json();
  return json.access_token as string;
}

function normalizeData(request: PushRequest): Record<string, string> {
  const normalized: Record<string, string> = {};
  if (request.payload) normalized.payload = request.payload;
  for (const [key, value] of Object.entries(request.data ?? {})) {
    normalized[key] = String(value);
  }
  return normalized;
}

const MAX_USER_IDS = 100;
const MAX_TOKENS = 500;

async function resolveTokens(request: PushRequest): Promise<string[]> {
  if (request.tokens && request.tokens.length > 0) {
    const unique = [...new Set(request.tokens)];
    return unique.slice(0, MAX_TOKENS);
  }

  const ids = request.userIds ?? (request.userId ? [request.userId] : []);
  if (ids.length === 0) return [];
  if (ids.length > MAX_USER_IDS) {
    throw new Error(`Too many userIds: ${ids.length} exceeds limit of ${MAX_USER_IDS}`);
  }

  const supabase = createSupabaseAdmin();
  const { data, error } = await supabase
    .from("fcm_tokens")
    .select("token")
    .in("user_id", ids)
    .eq("is_active", true);

  if (error) {
    throw new Error(`Failed to resolve FCM tokens: ${error.message}`);
  }

  const unique = [...new Set((data ?? []).map((row: { token: string }) => row.token))];
  return unique.slice(0, MAX_TOKENS);
}

async function sendToFcm(
  accessToken: string,
  projectId: string,
  token: string,
  request: PushRequest,
) {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        validate_only: request.dryRun === true,
        message: {
          token,
          notification: { title: request.title, body: request.body },
          data: normalizeData(request),
          android: { priority: "high" },
          apns: {
            headers: { "apns-priority": "10" },
            payload: { aps: { sound: "default" } },
          },
        },
      }),
    },
  );

  if (!response.ok) {
    const errorText = await response.text();
    console.error(`[send-push] FCM delivery failed: ${errorText}`);
    return { ok: false };
  }

  await response.json();
  return { ok: true };
}


Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return corsPreflightResponse(req);

  const headers = getCorsHeaders(req);

  try {
    const callerId = await getAuthenticatedUserId(req);
    if (!callerId) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers },
      );
    }

    const isAdmin = await requireAdminRole(callerId);
    if (!isAdmin) {
      return new Response(
        JSON.stringify({ error: "Forbidden: admin role required" }),
        { status: 403, headers },
      );
    }

    if (!rateLimiter.check(callerId)) return rateLimitedResponse(headers);

    const request = await req.json() as PushRequest;
    if (!request.title?.trim() || !request.body?.trim()) {
      return new Response(
        JSON.stringify({ error: "title and body are required" }),
        { status: 400, headers },
      );
    }

    request.title = request.title.trim().slice(0, 200);
    request.body = request.body.trim().slice(0, 1000);

    const projectId = Deno.env.get("FIREBASE_PROJECT_ID") ?? "";
    if (!projectId) {
      console.error("[send-push] Missing FIREBASE_PROJECT_ID secret");
      return new Response(
        JSON.stringify({ error: "Internal server error" }),
        { status: 500, headers },
      );
    }

    const tokens = await resolveTokens(request);
    if (tokens.length === 0) {
      return new Response(
        JSON.stringify({ success: 0, failure: 0 }),
        { status: 200, headers },
      );
    }

    const accessToken = await createAccessToken();

    const BATCH_SIZE = 50;
    let successCount = 0;
    let failureCount = 0;
    for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
      const batch = tokens.slice(i, i + BATCH_SIZE);
      const results = await Promise.all(
        batch.map((token) => sendToFcm(accessToken, projectId, token, request)),
      );
      successCount += results.filter((item) => item.ok).length;
      failureCount += results.filter((item) => !item.ok).length;
    }

    const status = failureCount === 0 ? 200 : successCount === 0 ? 502 : 207;
    return new Response(
      JSON.stringify({ success: successCount, failure: failureCount }),
      { status, headers },
    );
  } catch (error) {
    console.error("[send-push] Error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers },
    );
  }
});
