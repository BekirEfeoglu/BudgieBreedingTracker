import {
  createSupabaseAdmin,
  getAuthenticatedUserId,
} from "../_shared/auth.ts";
import {
  createRateLimiter,
  createSupabaseRateLimitStore,
  rateLimitedResponse,
} from "../_shared/rate-limit.ts";
import { corsPreflightResponse, getCorsHeaders } from "../_shared/cors.ts";
import { parseRequestBody, z } from "../_shared/validation.ts";
import { moderateText } from "../moderate-content/moderation.ts";

const rateLimiter = createRateLimiter({
  windowMs: 60_000,
  maxCalls: 30,
  store: createSupabaseRateLimitStore("create-community-comment"),
});

const commentSchema = z.object({
  post_id: z.string().uuid(),
  content: z.string().min(1).max(1000),
});

type SupabaseAdminClient = any;
type SupabaseError = { message?: string } | null;

export type CreateCommunityCommentDeps = {
  getAuthenticatedUserId(req: Request): Promise<string | null>;
  checkRateLimit(userId: string): boolean | Promise<boolean>;
  createAdminClient(): SupabaseAdminClient;
  randomUUID(): string;
};

const defaultDeps: CreateCommunityCommentDeps = {
  getAuthenticatedUserId,
  checkRateLimit: (userId) => rateLimiter.check(userId),
  createAdminClient: createSupabaseAdmin,
  randomUUID: () => crypto.randomUUID(),
};

export function createCommunityCommentHandler(
  deps: CreateCommunityCommentDeps = defaultDeps,
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

      const parsed = await parseRequestBody(req, commentSchema, headers);
      if (!parsed.success) return parsed.response;

      const postId = parsed.data.post_id;
      const content = parsed.data.content.trim();
      if (!content) {
        return new Response(JSON.stringify({ error: "content_required" }), {
          status: 400,
          headers,
        });
      }

      const moderation = moderateText(content);
      if (!moderation.allowed) {
        return new Response(
          JSON.stringify({
            error: "moderation_rejected",
            reason: moderation.reason,
          }),
          { status: 400, headers },
        );
      }

      const admin = deps.createAdminClient();
      const { data: post, error: postError } = await (admin
        .from("community_posts")
        .select("user_id,is_deleted,needs_review,visibility") as {
          eq(column: string, value: string): {
            single(): Promise<{
              data: Record<string, unknown> | null;
              error: SupabaseError;
            }>;
          };
        })
        .eq("id", postId)
        .single();

      if (
        postError ||
        !post ||
        post.is_deleted === true ||
        post.needs_review === true ||
        post.visibility !== "public"
      ) {
        return new Response(JSON.stringify({ error: "post_not_found" }), {
          status: 404,
          headers,
        });
      }

      const authorId = post.user_id as string;
      if (authorId !== userId) {
        const { data: blocks, error: blockError } = await (admin
          .from("community_blocks")
          .select("id") as {
            or(expression: string): {
              limit(limit: number): Promise<{
                data: Record<string, unknown>[] | null;
                error: SupabaseError;
              }>;
            };
          })
          .or(
            `and(user_id.eq.${userId},blocked_user_id.eq.${authorId}),` +
              `and(user_id.eq.${authorId},blocked_user_id.eq.${userId})`,
          )
          .limit(1);

        if (blockError) {
          return new Response(
            JSON.stringify({ error: "block_check_failed" }),
            { status: 500, headers },
          );
        }
        if (Array.isArray(blocks) && blocks.length > 0) {
          return new Response(
            JSON.stringify({ error: "blocked_relationship" }),
            { status: 403, headers },
          );
        }
      }

      const inserter = admin.from("community_comments").insert;
      if (!inserter) {
        throw new Error("community_comments insert unavailable");
      }
      const { data, error } = await inserter({
        id: deps.randomUUID(),
        post_id: postId,
        user_id: userId,
        content,
        is_deleted: false,
      })
        .select("id,post_id,user_id,content,created_at")
        .single();

      if (error) {
        return new Response(JSON.stringify({ error: "insert_failed" }), {
          status: 400,
          headers,
        });
      }

      return new Response(JSON.stringify({ comment: data }), { headers });
    } catch (error) {
      console.error("[create-community-comment] Error:", error);
      return new Response(
        JSON.stringify({ error: "create_community_comment_failed" }),
        { status: 500, headers },
      );
    }
  };
}
