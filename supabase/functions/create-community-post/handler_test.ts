import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { createCommunityPostHandler } from "./handler.ts";

function jsonRequest(body: unknown): Request {
  return new Request("https://example.com/create-community-post", {
    method: "POST",
    body: JSON.stringify(body),
  });
}

function baseDeps(overrides: Record<string, unknown> = {}) {
  const insertedRows: Record<string, unknown>[] = [];
  return {
    insertedRows,
    deps: {
      getAuthenticatedUserId: () => Promise.resolve("user-auth"),
      checkRateLimit: () => Promise.resolve(true),
      createAuthClient: () => ({
        rpc: () => Promise.resolve({ data: { allowed: true }, error: null }),
      }),
      createAdminClient: () => ({
        from: (table: string) => ({
          insert: (row: Record<string, unknown>) => {
            insertedRows.push({ table, ...row });
            return {
              select: () => ({
                single: () =>
                  Promise.resolve({
                    data: {
                      id: row.id,
                      user_id: row.user_id,
                      content: row.content,
                      post_type: row.post_type,
                    },
                    error: null,
                  }),
              }),
            };
          },
        }),
      }),
      randomUUID: () => "00000000-0000-7000-8000-000000000001",
      ...overrides,
    },
  };
}

Deno.test("create-community-post rejects missing authentication", async () => {
  const { deps } = baseDeps({
    getAuthenticatedUserId: () => Promise.resolve(null),
  });

  const response = await createCommunityPostHandler(deps)(
    jsonRequest({ post: { content: "Merhaba" } }),
  );

  assertEquals(response.status, 401);
  assertEquals(await response.json(), { error: "unauthorized" });
});

Deno.test("create-community-post rejects invalid request bodies", async () => {
  const { deps } = baseDeps();

  const response = await createCommunityPostHandler(deps)(
    jsonRequest({ post: { content: "" } }),
  );

  assertEquals(response.status, 400);
});

Deno.test("create-community-post rejects moderated content before insert", async () => {
  const { deps, insertedRows } = baseDeps();

  const response = await createCommunityPostHandler(deps)(
    jsonRequest({ post: { content: "I will kill your bird" } }),
  );

  assertEquals(response.status, 400);
  assertEquals((await response.json()).error, "moderation_rejected");
  assertEquals(insertedRows.length, 0);
});

Deno.test("create-community-post inserts with authenticated owner only", async () => {
  const { deps, insertedRows } = baseDeps();

  const response = await createCommunityPostHandler(deps)(
    jsonRequest({
      post: {
        id: "00000000-0000-7000-8000-000000000123",
        user_id: "spoofed-user",
        created_at: "2020-01-01T00:00:00Z",
        content: "Temiz topluluk paylasimi",
        post_type: "tip",
      },
    }),
  );

  assertEquals(response.status, 200);
  assertEquals(insertedRows.length, 1);
  assertEquals(insertedRows[0].table, "community_posts");
  assertEquals(insertedRows[0].user_id, "user-auth");
  assertEquals(insertedRows[0].content, "Temiz topluluk paylasimi");
  assertEquals(insertedRows[0].post_type, "tip");
  assertEquals("created_at" in insertedRows[0], false);
});
