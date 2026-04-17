import { getCorsHeaders, corsPreflightResponse } from "../_shared/cors.ts";
import {
  getAuthenticatedUserId,
  requireAdminRole,
  createSupabaseAdmin,
} from "../_shared/auth.ts";
import { createRateLimiter, rateLimitedResponse } from "../_shared/rate-limit.ts";
import { SignJWT, importPKCS8 } from "npm:jose@5.9.6";
import { z } from "npm:zod@3.24.4";
import { parseRequestBody } from "../_shared/validation.ts";
import {
  authorizePushTargets,
  BATCH_SIZE,
  BODY_MAX,
  batch as batchItems,
  clampText,
  clampTokens,
  MAX_TOKENS,
  normalizeData,
  type PushRequest,
  resultStatus,
  TITLE_MAX,
  validateUserIdsCount,
} from "./push_core.ts";

const rateLimiter = createRateLimiter({ windowMs: 60_000, maxCalls: 10 });

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

async function resolveTokens(request: PushRequest): Promise<string[]> {
  if (request.tokens && request.tokens.length > 0) {
    return clampTokens(request.tokens);
  }

  const ids = request.userIds ?? (request.userId ? [request.userId] : []);
  if (ids.length === 0) return [];
  validateUserIdsCount(ids);

  const supabase = createSupabaseAdmin();
  const { data, error } = await supabase
    .from("fcm_tokens")
    .select("token")
    .in("user_id", ids)
    .eq("is_active", true);

  if (error) {
    throw new Error(`Failed to resolve FCM tokens: ${error.message}`);
  }

  return clampTokens((data ?? []).map((row: { token: string }) => row.token));
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

    if (!rateLimiter.check(callerId)) return rateLimitedResponse(headers);

    const pushSchema = z.object({
      userId: z.string().optional(),
      userIds: z.array(z.string()).optional(),
      tokens: z.array(z.string()).optional(),
      title: z.string().min(1, "title is required"),
      body: z.string().min(1, "body is required"),
      payload: z.string().optional(),
      data: z.record(z.union([z.string(), z.number(), z.boolean()])).optional(),
      dryRun: z.boolean().optional(),
    });

    const parsed = await parseRequestBody(req, pushSchema, headers);
    if (!parsed.success) return parsed.response;

    const request: PushRequest = parsed.data;
    request.title = clampText(request.title, TITLE_MAX);
    request.body = clampText(request.body, BODY_MAX);

    const projectId = Deno.env.get("FIREBASE_PROJECT_ID") ?? "";
    if (!projectId) {
      console.error("[send-push] Missing FIREBASE_PROJECT_ID secret");
      return new Response(
        JSON.stringify({ error: "Internal server error" }),
        { status: 500, headers },
      );
    }

    // Authorization: non-admin callers may only push to themselves.
    // Raw `tokens` arrays bypass DB ownership checks and are admin-only.
    const authError = authorizePushTargets(request, callerId, isAdmin);
    if (authError) {
      return new Response(
        JSON.stringify({ error: authError }),
        { status: 403, headers },
      );
    }

    // Audit log: record who-pushed-to-whom when admin targets other users
    // or uses raw device tokens (no userId resolution).
    const targetIds = request.userIds ?? (request.userId ? [request.userId] : []);
    const crossUser = targetIds.filter((id) => id !== callerId);
    if (isAdmin && (crossUser.length > 0 || (request.tokens?.length ?? 0) > 0)) {
      console.info(
        `[send-push] admin_audit caller=${callerId} ` +
          `cross_user_targets=${crossUser.length} ` +
          `raw_tokens=${request.tokens?.length ?? 0}`,
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

    let successCount = 0;
    let failureCount = 0;
    for (const tokenBatch of batchItems(tokens, BATCH_SIZE)) {
      const results = await Promise.all(
        tokenBatch.map((token) => sendToFcm(accessToken, projectId, token, request)),
      );
      successCount += results.filter((item) => item.ok).length;
      failureCount += results.filter((item) => !item.ok).length;
    }

    return new Response(
      JSON.stringify({ success: successCount, failure: failureCount }),
      { status: resultStatus(successCount, failureCount), headers },
    );
  } catch (error) {
    console.error("[send-push] Error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers },
    );
  }
});
