import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { createCommunityCommentHandler } from "./handler.ts";

const postId = "00000000-0000-7000-8000-000000000111";

function jsonRequest(body: unknown): Request {
  return new Request("https://example.com/create-community-comment", {
    method: "POST",
    body: JSON.stringify(body),
  });
}

function makeAdmin(overrides: {
  post?: Record<string, unknown> | null;
  blockRows?: Record<string, unknown>[];
  inserted?: Record<string, unknown>[];
} = {}) {
  const inserted = overrides.inserted ?? [];
  const post = overrides.post ?? {
    user_id: "author-user",
    is_deleted: false,
    needs_review: false,
    visibility: "public",
  };
  const blockRows = overrides.blockRows ?? [];

  return {
    from: (table: string) => {
      if (table === "community_posts") {
        return {
          select: () => ({
            eq: () => ({
              single: () => Promise.resolve({ data: post, error: null }),
            }),
          }),
        };
      }
      if (table === "community_blocks") {
        return {
          select: () => ({
            or: () => ({
              limit: () => Promise.resolve({ data: blockRows, error: null }),
            }),
          }),
        };
      }
      return {
        insert: (row: Record<string, unknown>) => {
          inserted.push({ table, ...row });
          return {
            select: () => ({
              single: () =>
                Promise.resolve({
                  data: {
                    id: row.id,
                    post_id: row.post_id,
                    user_id: row.user_id,
                    content: row.content,
                  },
                  error: null,
                }),
            }),
          };
        },
      };
    },
  };
}

function baseDeps(overrides: Record<string, unknown> = {}) {
  return {
    getAuthenticatedUserId: () => Promise.resolve("commenter-user"),
    checkRateLimit: () => Promise.resolve(true),
    createAdminClient: () => makeAdmin(),
    randomUUID: () => "00000000-0000-7000-8000-000000000222",
    ...overrides,
  };
}

Deno.test("create-community-comment rejects missing authentication", async () => {
  const response = await createCommunityCommentHandler(
    baseDeps({ getAuthenticatedUserId: () => Promise.resolve(null) }),
  )(jsonRequest({ post_id: postId, content: "Merhaba" }));

  assertEquals(response.status, 401);
  assertEquals(await response.json(), { error: "unauthorized" });
});

Deno.test("create-community-comment rejects moderated content before insert", async () => {
  const inserted: Record<string, unknown>[] = [];
  const response = await createCommunityCommentHandler(
    baseDeps({ createAdminClient: () => makeAdmin({ inserted }) }),
  )(jsonRequest({ post_id: postId, content: "buy followers cheap now!" }));

  assertEquals(response.status, 400);
  assertEquals((await response.json()).error, "moderation_rejected");
  assertEquals(inserted.length, 0);
});

Deno.test("create-community-comment blocks reciprocal block relationships", async () => {
  const response = await createCommunityCommentHandler(
    baseDeps({
      createAdminClient: () =>
        makeAdmin({ blockRows: [{ id: "existing-block" }] }),
    }),
  )(jsonRequest({ post_id: postId, content: "Temiz yorum" }));

  assertEquals(response.status, 403);
  assertEquals(await response.json(), { error: "blocked_relationship" });
});

Deno.test("create-community-comment inserts with authenticated owner only", async () => {
  const inserted: Record<string, unknown>[] = [];
  const response = await createCommunityCommentHandler(
    baseDeps({ createAdminClient: () => makeAdmin({ inserted }) }),
  )(
    jsonRequest({
      post_id: postId,
      user_id: "spoofed-user",
      content: " Faydalı yorum ",
    }),
  );

  assertEquals(response.status, 200);
  assertEquals(inserted.length, 1);
  assertEquals(inserted[0].table, "community_comments");
  assertEquals(inserted[0].user_id, "commenter-user");
  assertEquals(inserted[0].post_id, postId);
  assertEquals(inserted[0].content, "Faydalı yorum");
});
