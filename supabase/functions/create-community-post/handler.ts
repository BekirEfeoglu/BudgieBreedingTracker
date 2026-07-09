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
    // Premium ceiling is 10 photos/post (free is client-capped at 3); the
    // server cap must not sit below the premium max or premium posts 400.
    image_urls: z.array(z.string().url()).max(10).optional(),
    bird_id: z.string().uuid().optional(),
    bird_name: z.string().max(100).optional(),
    mutation_tags: z.array(z.string().trim().max(50)).max(10).optional(),
  }),
  mode: z.enum(["create", "update"]).optional(),
});

const EDIT_WINDOW_MS = 5 * 60 * 1000;

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
type SelectQuery = {
  eq(column: string, value: unknown): SelectQuery;
  maybeSingle(): Promise<InsertResponse>;
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
      select(columns: string): { single(): Promise<InsertResponse> };
    };
    select(columns: string): SelectQuery;
    update(row: Record<string, unknown>): {
      eq(column: string, value: unknown): {
        select(columns: string): { single(): Promise<InsertResponse> };
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

type LinkedBird = {
  id: string;
  name: string | null;
  mutationTags: string[];
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

function normalizeStringArray(value: unknown): string[] {
  if (Array.isArray(value)) {
    return value
      .filter((item): item is string => typeof item === "string")
      .map((item) => item.trim())
      .filter((item) => item.length > 0)
      .slice(0, 10);
  }

  if (typeof value === "string") {
    try {
      return normalizeStringArray(JSON.parse(value));
    } catch {
      const trimmed = value.trim();
      return trimmed.length > 0 ? [trimmed].slice(0, 10) : [];
    }
  }

  return [];
}

async function fetchOwnedBird(
  admin: TypedSupabaseAdminClient,
  userId: string,
  birdId: string,
): Promise<LinkedBird | null> {
  const { data, error } = await admin
    .from("birds")
    .select("id,user_id,name,mutations")
    .eq("id", birdId)
    .eq("user_id", userId)
    .maybeSingle();

  if (error || !data) return null;

  const name = typeof data.name === "string" ? data.name.trim() : "";

  return {
    id: typeof data.id === "string" ? data.id : birdId,
    name: name.length > 0 ? name : null,
    mutationTags: normalizeStringArray(data.mutations),
  };
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
      const admin = deps.createAdminClient() as TypedSupabaseAdminClient;
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

      if (parsed.data.mode === "update") {
        if (!input.id) {
          return new Response(JSON.stringify({ error: "post_id_required" }), {
            status: 400,
            headers,
          });
        }
        const { data: existing, error: fetchError } = await admin
          .from("community_posts")
          .select("id,user_id,content,created_at,is_deleted")
          .eq("id", input.id)
          .maybeSingle();

        if (fetchError || !existing || existing.is_deleted === true) {
          return new Response(JSON.stringify({ error: "post_not_found" }), {
            status: 400,
            headers,
          });
        }
        if (existing.user_id !== userId) {
          return new Response(JSON.stringify({ error: "not_post_author" }), {
            status: 403,
            headers,
          });
        }
        const createdAtMs = Date.parse(String(existing.created_at));
        if (
          !Number.isFinite(createdAtMs) ||
          Date.now() - createdAtMs > EDIT_WINDOW_MS
        ) {
          return new Response(
            JSON.stringify({ error: "edit_window_expired" }),
            { status: 400, headers },
          );
        }

        const newHash = await sha256Hex(content);
        const { data: updated, error: updateError } = await admin
          .from("community_posts")
          .update({
            content,
            content_hash: newHash,
            edited_at: new Date().toISOString(),
          })
          .eq("id", input.id)
          .select(
            "id,user_id,content,title,post_type,image_urls,tags,bird_id,bird_name,mutation_tags,created_at,edited_at",
          )
          .single();

        if (updateError) {
          return new Response(JSON.stringify({ error: "update_failed" }), {
            status: 400,
            headers,
          });
        }
        return new Response(JSON.stringify({ post: updated }), { headers });
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

      const linkedBird = input.bird_id
        ? await fetchOwnedBird(admin, userId, input.bird_id)
        : null;
      if (input.bird_id && linkedBird == null) {
        return new Response(JSON.stringify({ error: "invalid_bird" }), {
          status: 400,
          headers,
        });
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
        ...(linkedBird ? { bird_id: linkedBird.id } : {}),
        ...(linkedBird?.name ? { bird_name: linkedBird.name } : {}),
        ...(linkedBird && linkedBird.mutationTags.length > 0
          ? { mutation_tags: linkedBird.mutationTags }
          : {}),
      };

      const { data, error } = await admin
        .from("community_posts")
        .insert(row)
        .select(
          "id,user_id,content,title,post_type,image_urls,tags,bird_id,bird_name,mutation_tags,created_at",
        )
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
