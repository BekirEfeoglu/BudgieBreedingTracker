import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { SignJWT, importPKCS8 } from "npm:jose@5.9.6";

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

const corsHeaders = {
  "Access-Control-Allow-Origin": Deno.env.get("ALLOWED_ORIGINS") ?? "",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Content-Type": "application/json",
};

function createSupabaseAuth(req: Request) {
  return createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
    {
      global: {
        headers: {
          Authorization: req.headers.get("Authorization") ?? "",
        },
      },
    },
  );
}

function createSupabaseAdmin() {
  return createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );
}

function isServiceRoleToken(token: string): boolean {
  try {
    const payload = JSON.parse(atob(token.split(".")[1]));
    return payload.role === "service_role";
  } catch {
    return false;
  }
}

async function getAuthenticatedUserId(req: Request): Promise<string | null> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return null;

  const token = authHeader.replace("Bearer ", "");
  if (isServiceRoleToken(token)) {
    return "service_role";
  }

  const supabase = createSupabaseAuth(req);
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) return null;
  return user.id;
}

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

async function resolveTokens(request: PushRequest): Promise<string[]> {
  if (request.tokens && request.tokens.length > 0) {
    return [...new Set(request.tokens)];
  }

  const ids = request.userIds ?? (request.userId ? [request.userId] : []);
  if (ids.length == 0) return [];

  const supabase = createSupabaseAdmin();
  const { data, error } = await supabase
    .from("fcm_tokens")
    .select("token")
    .in("user_id", ids)
    .eq("is_active", true);

  if (error) {
    throw new Error(`Failed to resolve FCM tokens: ${error.message}`);
  }

  return [...new Set((data ?? []).map((row: { token: string }) => row.token))];
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
          notification: {
            title: request.title,
            body: request.body,
          },
          data: normalizeData(request),
          android: {
            priority: "high",
          },
          apns: {
            headers: {
              "apns-priority": "10",
            },
            payload: {
              aps: {
                sound: "default",
              },
            },
          },
        },
      }),
    },
  );

  if (!response.ok) {
    return {
      ok: false,
      token,
      error: await response.text(),
    };
  }

  return {
    ok: true,
    token,
    response: await response.json(),
  };
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const callerId = await getAuthenticatedUserId(req);
    if (!callerId) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: corsHeaders },
      );
    }

    const request = await req.json() as PushRequest;
    if (!request.title?.trim() || !request.body?.trim()) {
      return new Response(
        JSON.stringify({ error: "title and body are required" }),
        { status: 400, headers: corsHeaders },
      );
    }

    const projectId = Deno.env.get("FIREBASE_PROJECT_ID") ?? "";
    if (!projectId) {
      return new Response(
        JSON.stringify({ error: "Missing FIREBASE_PROJECT_ID secret" }),
        { status: 500, headers: corsHeaders },
      );
    }

    const tokens = await resolveTokens(request);
    if (tokens.length === 0) {
      return new Response(
        JSON.stringify({ success: 0, failure: 0, results: [] }),
        { status: 200, headers: corsHeaders },
      );
    }

    const accessToken = await createAccessToken();
    const results = await Promise.all(
      tokens.map((token) => sendToFcm(accessToken, projectId, token, request)),
    );

    return new Response(
      JSON.stringify({
        callerId,
        success: results.filter((item) => item.ok).length,
        failure: results.filter((item) => !item.ok).length,
        results,
      }),
      { status: 200, headers: corsHeaders },
    );
  } catch (error) {
    console.error("[send-push] Error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: corsHeaders },
    );
  }
});
