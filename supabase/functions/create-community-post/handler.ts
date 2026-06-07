import {
  createSupabaseAdmin,
  createSupabaseAuth,
  getAuthenticatedUserId,
} from "../_shared/auth.ts";
import {
  createRateLimiter,
  createSupabaseRateLimitStore,
  rateLimitedResponse,
} from "../_shared/rate-limit.ts";
import { corsPreflightResponse, getCorsHeaders } from "../_shared/cors.ts";
import { parseRequestBody, z } from "../_shared/validation.ts";
import {
  MAX_TEXT_LENGTH,
  moderateText,
} from "../moderate-content/moderation.ts";

const rateLimiter = createRateLimiter({
  windowMs: 60_000,
  maxCalls: 10,
  store: createSupabaseRateLimitStore("create-community-post"),
});

const postSchema = z.object({
  post: z.object({
    id: z.string().uuid().optional(),
    content: z.string().min(1).max(5000),
    title: z.string().max(200).nullable().optional(),
    post_type: z.enum([
      "text",
      "photo",
      "poll",
      "question",
      "tip",
      "achievement",
      "guide",
      "showcase",
      "general",
    ]).optional(),
    tags: z.array(z.string().trim().min(1).max(40)).max(10).optional(),
    image_urls: z.array(z.string().url()).max(6).optional(),
  }),
});

type GuardResult = { allowed?: boolean; reason?: string } | null;
type SupabaseRpcClient = any;
type SupabaseAdminClient = any;
type GuardResponse = {
  data: GuardResult;
  error: { message?: string } | null;
};
type InsertResponse = {
  data: Record<string, unknown> | null;
  error: { message?: string } | null;
};
type TypedSupabaseRpcClient = {
  rpc(
    name: string,
    params: Record<string, unknown>,
  ): Promise<GuardResponse>;
};
type TypedSupabaseAdminClient = {
  from(table: string): {
    insert(row: Record<string, unknown>): {
      select(columns: string): {
        single(): Promise<InsertResponse>;
      };
    };
  };
};

export type CreateCommunityPostDeps = {
  getAuthenticatedUserId(req: Request): Promise<string | null>;
  checkRateLimit(userId: string): boolean | Promise<boolean>;
  createAuthClient(req: Request): SupabaseRpcClient;
  createAdminClient(): SupabaseAdminClient;
  randomUUID(): string;
};

const defaultDeps: CreateCommunityPostDeps = {
  getAuthenticatedUserId,
  checkRateLimit: (userId) => rateLimiter.check(userId),
  createAuthClient: createSupabaseAuth,
  createAdminClient: createSupabaseAdmin,
  randomUUID: () => crypto.randomUUID(),
};

async function sha256Hex(value: string): Promise<string> {
  const encoded = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", encoded);
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function isCommunityPhotoUrl(url: string, userId: string, postId: string) {
  try {
    const parsed = new URL(url);
    const path = decodeURIComponent(parsed.pathname);
    const prefix =
      `/storage/v1/object/sign/community-photos/${userId}/${postId}/`;
    return path.startsWith(prefix);
  } catch {
    return false;
  }
}

export function createCommunityPostHandler(
  deps: CreateCommunityPostDeps = defaultDeps,
) {
  return async (req: Request): Promise<Response> => {
    if (req.method === "OPTIONS") return corsPreflightResponse(req);

    const headers = getCorsHeaders(req);

    try {
      const userId = await deps.getAuthenticatedUserId(req);
      if (!userId) {
        return new Response(JSON.stringify({ error: "unauthorized" }), {
          status: 401,
          headers,
        });
      }

      if (!(await deps.checkRateLimit(userId))) {
        return rateLimitedResponse(headers);
      }

      const parsed = await parseRequestBody(req, postSchema, headers);
      if (!parsed.success) return parsed.response;

      const input = parsed.data.post;
      const postId = input.id ?? deps.randomUUID();
      const content = input.content.trim();
      const title = input.title?.trim();
      const textToModerate = [title, content]
        .filter((part): part is string => Boolean(part && part.length > 0))
        .join(" ");

      if (!content) {
        return new Response(JSON.stringify({ error: "content_required" }), {
          status: 400,
          headers,
        });
      }
      if (textToModerate.length > MAX_TEXT_LENGTH) {
        return new Response(JSON.stringify({ error: "content_too_long" }), {
          status: 400,
          headers,
        });
      }

      const moderation = moderateText(textToModerate);
      if (!moderation.allowed) {
        return new Response(
          JSON.stringify({
            error: "moderation_rejected",
            reason: moderation.reason,
          }),
          { status: 400, headers },
        );
      }

      const imageUrls = input.image_urls ?? [];
      if (imageUrls.some((url) => !isCommunityPhotoUrl(url, userId, postId))) {
        return new Response(JSON.stringify({ error: "invalid_image_url" }), {
          status: 400,
          headers,
        });
      }

      const contentHash = await sha256Hex(content);
      const { data: guard, error: guardError } = await (deps
        .createAuthClient(req) as TypedSupabaseRpcClient)
        .rpc("check_community_post_allowed", {
          p_content_hash: contentHash,
        });
      if (guardError || guard?.allowed !== true) {
        return new Response(
          JSON.stringify({
            error: "post_guard_denied",
            reason: guard?.reason ?? "guard_check_failed",
          }),
          { status: 429, headers },
        );
      }

      const row = {
        id: postId,
        user_id: userId,
        content,
        content_hash: contentHash,
        post_type: input.post_type ?? "general",
        is_deleted: false,
        ...(title ? { title } : {}),
        ...(input.tags ? { tags: input.tags } : {}),
        ...(imageUrls.length > 0 ? { image_urls: imageUrls } : {}),
      };

      const { data, error } = await (deps
        .createAdminClient() as TypedSupabaseAdminClient)
        .from("community_posts")
        .insert(row)
        .select("id,user_id,content,title,post_type,image_urls,tags,created_at")
        .single();

      if (error) {
        return new Response(JSON.stringify({ error: "insert_failed" }), {
          status: 400,
          headers,
        });
      }

      return new Response(JSON.stringify({ post: data }), { headers });
    } catch (error) {
      console.error("[create-community-post] Error:", error);
      return new Response(
        JSON.stringify({ error: "create_community_post_failed" }),
        { status: 500, headers },
      );
    }
  };
}
