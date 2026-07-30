import { corsPreflightResponse, getCorsHeaders } from "../_shared/cors.ts";
import {
  createSupabaseAdmin,
  getAuthenticatedUserId,
  requireAdminRole,
} from "../_shared/auth.ts";
import {
  createRateLimiter,
  createSupabaseRateLimitStore,
  rateLimitedResponse,
} from "../_shared/rate-limit.ts";
import { importPKCS8, SignJWT } from "npm:jose@5.9.6";
import { z } from "npm:zod@3.24.4";
import { parseRequestBody } from "../_shared/validation.ts";
import {
  authorizePushTargets,
  batch as batchItems,
  BATCH_SIZE,
  BODY_MAX,
  clampText,
  clampTokens,
  isPermanentFcmTokenError,
  isSuppressedByQuietHours,
  MAX_TOKENS,
  type MessagePushResolution,
  normalizeData,
  parseFcmErrorStatus,
  type PushRequest,
  type QuietHours,
  resultStatus,
  TITLE_MAX,
  validateUserIdsCount,
} from "./push_core.ts";

const rateLimiter = createRateLimiter({
  windowMs: 60_000,
  maxCalls: 10,
  store: createSupabaseRateLimitStore("send-push"),
});

const manualPushSchema = z.object({
  userId: z.string().optional(),
  userIds: z.array(z.string()).optional(),
  tokens: z.array(z.string()).optional(),
  title: z.string().min(1, "title is required"),
  body: z.string().min(1, "body is required"),
  payload: z.string().optional(),
  data: z.record(z.union([z.string(), z.number(), z.boolean()])).optional(),
  dryRun: z.boolean().optional(),
  respectQuietHours: z.boolean().optional(),
}).strict();

const messagePushSchema = z.object({
  messageId: z.string().uuid(),
}).strict();

const pushSchema = z.union([manualPushSchema, messagePushSchema]);

type SupabaseAdminClient = any;

export type SendPushDeps = {
  getAuthenticatedUserId(req: Request): Promise<string | null>;
  requireAdminRole(userId: string): Promise<boolean>;
  checkRateLimit(callerId: string): boolean | Promise<boolean>;
  createAdminClient(): SupabaseAdminClient;
  resolveMessagePush(
    messageId: string,
    callerId: string,
    admin: SupabaseAdminClient,
  ): Promise<MessagePushResolution>;
  getProjectId(): string | undefined;
  createAccessToken(): Promise<string>;
  resolveTokens(
    request: PushRequest,
    admin: SupabaseAdminClient,
  ): Promise<string[]>;
  sendToFcm(
    accessToken: string,
    projectId: string,
    token: string,
    request: PushRequest,
  ): Promise<{ ok: boolean; token: string; permanentTokenFailure: boolean }>;
  deactivateFcmTokens(
    tokens: string[],
    admin: SupabaseAdminClient,
  ): Promise<void>;
  now(): Date;
};

async function defaultCreateAccessToken(): Promise<string> {
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
    throw new Error(
      `Google OAuth failed: ${response.status} ${await response.text()}`,
    );
  }

  const json = await response.json();
  return json.access_token as string;
}

async function defaultResolveTokens(
  request: PushRequest,
  admin: SupabaseAdminClient,
): Promise<string[]> {
  if (request.tokens && request.tokens.length > 0) {
    return clampTokens(request.tokens);
  }

  const ids = request.userIds ?? (request.userId ? [request.userId] : []);
  if (ids.length === 0) return [];
  validateUserIdsCount(ids);

  const { data, error } = await admin
    .from("fcm_tokens")
    .select("token")
    .in("user_id", ids)
    .eq("is_active", true);

  if (error) {
    throw new Error(`Failed to resolve FCM tokens: ${error.message}`);
  }

  return clampTokens((data ?? []).map((row: { token: string }) => row.token));
}

export async function resolvePersistedMessagePush(
  messageId: string,
  callerId: string,
  admin: SupabaseAdminClient,
): Promise<MessagePushResolution> {
  const { data: message, error: messageError } = await admin
    .from("messages")
    .select("id, conversation_id, sender_id")
    .eq("id", messageId)
    .maybeSingle();

  if (messageError) {
    throw new Error(`Failed to resolve message push: ${messageError.message}`);
  }
  if (!message || message.sender_id !== callerId) {
    return { error: "Forbidden", status: 403 };
  }

  const { data: participants, error: participantError } = await admin
    .from("conversation_participants")
    .select("user_id")
    .eq("conversation_id", message.conversation_id)
    .eq("is_left", false)
    .eq("is_muted", false)
    .neq("user_id", callerId);

  if (participantError) {
    throw new Error(
      `Failed to resolve message recipients: ${participantError.message}`,
    );
  }

  const participantRows = (participants ?? []) as Array<{
    user_id?: unknown;
  }>;
  const userIds: string[] = [
    ...new Set<string>(
      participantRows
        .map((row: { user_id?: unknown }) => row.user_id)
        .filter((id: unknown): id is string =>
          typeof id === "string" && id.length > 0
        ),
    ),
  ];
  validateUserIdsCount(userIds);

  return {
    request: {
      userIds,
      // Lock-screen-safe copy: message text and sender identity are not put in
      // the remote notification. The authenticated deep link opens the thread.
      title: "BudgieBreedingTracker",
      body: "💬",
      payload: `message:${message.conversation_id}`,
      data: {
        type: "message",
        entity_id: message.conversation_id,
      },
      respectQuietHours: true,
    },
  };
}

async function defaultSendToFcm(
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
    const errorStatus = parseFcmErrorStatus(errorText);
    console.error(`[send-push] FCM delivery failed: ${errorText}`);
    return {
      ok: false,
      token,
      permanentTokenFailure: isPermanentFcmTokenError(errorStatus),
    };
  }

  await response.json();
  return { ok: true, token, permanentTokenFailure: false };
}

async function defaultDeactivateFcmTokens(
  tokens: string[],
  admin: SupabaseAdminClient,
): Promise<void> {
  const uniqueTokens = [...new Set(tokens)];
  if (uniqueTokens.length === 0) return;

  const { error } = await admin
    .from("fcm_tokens")
    .update({ is_active: false })
    .in("token", uniqueTokens);

  if (error) {
    console.error(
      `[send-push] Failed to deactivate ${uniqueTokens.length} invalid tokens: ${error.message}`,
    );
    return;
  }

  console.info(
    `[send-push] Deactivated ${uniqueTokens.length} permanent-failure tokens`,
  );
}

const defaultDeps: SendPushDeps = {
  getAuthenticatedUserId,
  requireAdminRole,
  checkRateLimit: (callerId) => rateLimiter.check(callerId),
  createAdminClient: createSupabaseAdmin,
  resolveMessagePush: resolvePersistedMessagePush,
  getProjectId: () => Deno.env.get("FIREBASE_PROJECT_ID"),
  createAccessToken: defaultCreateAccessToken,
  resolveTokens: defaultResolveTokens,
  sendToFcm: defaultSendToFcm,
  deactivateFcmTokens: defaultDeactivateFcmTokens,
  now: () => new Date(),
};

export function createSendPushHandler(deps: SendPushDeps = defaultDeps) {
  return async (req: Request): Promise<Response> => {
    if (req.method === "OPTIONS") return corsPreflightResponse(req);

    const headers = getCorsHeaders(req);

    try {
      const callerId = await deps.getAuthenticatedUserId(req);
      if (!callerId) {
        return new Response(
          JSON.stringify({ error: "Unauthorized" }),
          { status: 401, headers },
        );
      }

      const isAdmin = await deps.requireAdminRole(callerId);

      if (!(await deps.checkRateLimit(callerId))) {
        return rateLimitedResponse(headers);
      }

      const parsed = await parseRequestBody(req, pushSchema, headers);
      if (!parsed.success) return parsed.response;

      const admin = deps.createAdminClient();
      const parsedRequest = parsed.data;
      const isMessagePush = "messageId" in parsedRequest;
      let request: PushRequest;
      if (isMessagePush) {
        const resolved = await deps.resolveMessagePush(
          parsedRequest.messageId,
          callerId,
          admin,
        );
        if (!resolved.request) {
          return new Response(
            JSON.stringify({ error: resolved.error ?? "Forbidden" }),
            { status: resolved.status ?? 403, headers },
          );
        }
        request = resolved.request;
      } else {
        request = parsedRequest;
      }
      request.title = clampText(request.title, TITLE_MAX);
      request.body = clampText(request.body, BODY_MAX);

      const projectId = deps.getProjectId() ?? "";
      if (!projectId) {
        console.error("[send-push] Missing FIREBASE_PROJECT_ID secret");
        return new Response(
          JSON.stringify({ error: "Internal server error" }),
          { status: 500, headers },
        );
      }

      // Authorization: non-admin callers may only push to themselves.
      // Raw `tokens` arrays bypass DB ownership checks and are admin-only.
      const authError = isMessagePush
        ? null
        : authorizePushTargets(request, callerId, isAdmin);
      if (authError) {
        return new Response(
          JSON.stringify({ error: authError }),
          { status: 403, headers },
        );
      }

      // Audit log: record who-pushed-to-whom when admin targets other users
      // or uses raw device tokens (no userId resolution).
      const targetIds = request.userIds ??
        (request.userId ? [request.userId] : []);
      const crossUser = targetIds.filter((id) => id !== callerId);
      if (
        !isMessagePush &&
        isAdmin &&
        (crossUser.length > 0 || (request.tokens?.length ?? 0) > 0)
      ) {
        console.info(
          `[send-push] admin_audit caller=${callerId} ` +
            `cross_user_targets=${crossUser.length} ` +
            `raw_tokens=${request.tokens?.length ?? 0}`,
        );
      }

      // Quiet hours (§5.2): for opt-in notifications, drop recipients currently
      // inside their configured quiet-hours window. Fail-open — any missing/
      // invalid config or lookup error still delivers. Raw-token pushes aren't
      // filtered (no user to look up); critical notifications simply omit
      // `respectQuietHours`, so they are never held back here.
      let deliveryRequest = request;
      if (
        request.respectQuietHours === true &&
        (request.tokens?.length ?? 0) === 0
      ) {
        const ids = request.userIds ?? (request.userId ? [request.userId] : []);
        if (ids.length > 0) {
          // `profiles.id` IS the auth user id (no separate user_id column), and
          // push targets are auth user ids (fcm_tokens.user_id -> auth.users.id).
          const { data: rows, error } = await admin
            .from("profiles")
            .select("id, quiet_hours")
            .in("id", ids);
          if (error) {
            console.error(
              `[send-push] quiet-hours lookup failed (delivering all): ${error.message}`,
            );
          } else {
            const now = deps.now();
            const suppressed = new Set(
              (rows ?? [])
                .filter((row: { id: string; quiet_hours: unknown }) =>
                  isSuppressedByQuietHours(
                    row.quiet_hours as QuietHours | null,
                    now,
                  )
                )
                .map((row: { id: string }) => row.id),
            );
            if (suppressed.size > 0) {
              const delivered = ids.filter((id) => !suppressed.has(id));
              console.info(
                `[send-push] quiet_hours suppressed=${suppressed.size} ` +
                  `delivered=${delivered.length}`,
              );
              deliveryRequest = {
                ...request,
                userId: undefined,
                userIds: delivered,
              };
              if (delivered.length === 0) {
                return new Response(
                  JSON.stringify({
                    success: 0,
                    failure: 0,
                    suppressed: suppressed.size,
                  }),
                  { status: 200, headers },
                );
              }
            }
          }
        }
      }

      const tokens = await deps.resolveTokens(deliveryRequest, admin);
      if (tokens.length === 0) {
        return new Response(
          JSON.stringify({ success: 0, failure: 0 }),
          { status: 200, headers },
        );
      }

      const accessToken = await deps.createAccessToken();

      let successCount = 0;
      let failureCount = 0;
      const tokensToDeactivate: string[] = [];
      for (const tokenBatch of batchItems(tokens, BATCH_SIZE)) {
        const results = await Promise.all(
          tokenBatch.map((token) =>
            deps.sendToFcm(accessToken, projectId, token, request)
          ),
        );
        successCount += results.filter((item) => item.ok).length;
        failureCount += results.filter((item) => !item.ok).length;
        tokensToDeactivate.push(
          ...results
            .filter((item) => item.permanentTokenFailure)
            .map((item) => item.token),
        );
      }

      await deps.deactivateFcmTokens(tokensToDeactivate, admin);

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
  };
}
