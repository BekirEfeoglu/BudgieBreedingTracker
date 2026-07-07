import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { createCommunityPostHandler } from "./handler.ts";

// Shared with both the create-mode and update-mode moderation-reject tests
// so they can never drift apart from the client filter's keyword list.
const MODERATION_REJECTED_FIXTURE = "I will kill your bird";

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

function birdAwareAdminClient(birdRow: Record<string, unknown> | null) {
  const insertedRows: Record<string, unknown>[] = [];

  return {
    insertedRows,
    client: {
      from: (table: string) => {
        if (table === "birds") {
          return {
            select: (_cols: string) => {
              const query = {
                eq: (_col: string, _v: unknown) => query,
                maybeSingle: () =>
                  Promise.resolve({ data: birdRow, error: null }),
              };
              return query;
            },
          };
        }

        return {
          insert: (row: Record<string, unknown>) => {
            insertedRows.push({ table, ...row });
            return {
              select: () => ({
                single: () => Promise.resolve({ data: row, error: null }),
              }),
            };
          },
        };
      },
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
    jsonRequest({ post: { content: MODERATION_REJECTED_FIXTURE } }),
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

Deno.test("create-community-post rejects bird links not owned by the authenticated user", async () => {
  const admin = birdAwareAdminClient(null);
  const { deps } = baseDeps({ createAdminClient: () => admin.client });

  const response = await createCommunityPostHandler(deps)(
    jsonRequest({
      post: {
        content: "Kus etiketi denemesi",
        bird_id: "00000000-0000-7000-8000-000000000777",
      },
    }),
  );

  assertEquals(response.status, 400);
  assertEquals(await response.json(), { error: "invalid_bird" });
  assertEquals(admin.insertedRows.length, 0);
});

Deno.test("create-community-post derives bird fields from the owned bird row", async () => {
  const birdId = "00000000-0000-7000-8000-000000000777";
  const admin = birdAwareAdminClient({
    id: birdId,
    user_id: "user-auth",
    name: "Mavis",
    mutations: ["opaline", "blue"],
  });
  const { deps } = baseDeps({ createAdminClient: () => admin.client });

  const response = await createCommunityPostHandler(deps)(
    jsonRequest({
      post: {
        content: "Mavis bugun yumurtalikta sakin.",
        bird_id: birdId,
        bird_name: "Spoofed",
        mutation_tags: ["wrong"],
      },
    }),
  );

  assertEquals(response.status, 200);
  assertEquals(admin.insertedRows.length, 1);
  assertEquals(admin.insertedRows[0].bird_id, birdId);
  assertEquals(admin.insertedRows[0].bird_name, "Mavis");
  assertEquals(admin.insertedRows[0].mutation_tags, ["opaline", "blue"]);
});

// baseDeps createAdminClient'ine eklenecek: mevcut from() dönüşüne
// select-chain (fetch existing) ve update-chain mock'ları.
function updateCapableAdminClient(existingRow: Record<string, unknown> | null) {
  const updatedRows: Record<string, unknown>[] = [];
  return {
    updatedRows,
    client: {
      from: (_table: string) => ({
        select: (_cols: string) => ({
          eq: (_col: string, _v: unknown) => ({
            maybeSingle: () =>
              Promise.resolve({ data: existingRow, error: null }),
          }),
        }),
        update: (row: Record<string, unknown>) => ({
          eq: (_col: string, _v: unknown) => ({
            select: (_cols: string) => ({
              single: () =>
                Promise.resolve({
                  data: { ...existingRow, ...row },
                  error: null,
                }),
            }),
          }),
        }),
        insert: (_row: Record<string, unknown>) => ({
          select: () => ({
            single: () => Promise.resolve({ data: _row, error: null }),
          }),
        }),
      }),
    },
  };
}

const FRESH_POST = {
  id: "00000000-0000-7000-8000-00000000aaaa",
  user_id: "user-auth",
  content: "orijinal",
  created_at: new Date(Date.now() - 60_000).toISOString(), // 1 dk önce
  is_deleted: false,
};

Deno.test("update mode edits own fresh post", async () => {
  const admin = updateCapableAdminClient(FRESH_POST);
  const { deps } = baseDeps({ createAdminClient: () => admin.client });
  const response = await createCommunityPostHandler(deps)(
    jsonRequest({
      post: { id: FRESH_POST.id, content: "duzeltilmis icerik" },
      mode: "update",
    }),
  );
  assertEquals(response.status, 200);
  const body = await response.json();
  assertEquals(body.post.content, "duzeltilmis icerik");
});

Deno.test("update mode rejects after 5-minute window", async () => {
  const stale = {
    ...FRESH_POST,
    created_at: new Date(Date.now() - 6 * 60_000).toISOString(),
  };
  const admin = updateCapableAdminClient(stale);
  const { deps } = baseDeps({ createAdminClient: () => admin.client });
  const response = await createCommunityPostHandler(deps)(
    jsonRequest({
      post: { id: stale.id, content: "gec kaldim" },
      mode: "update",
    }),
  );
  assertEquals(response.status, 400);
  assertEquals((await response.json()).error, "edit_window_expired");
});

Deno.test("update mode rejects non-author", async () => {
  const foreign = { ...FRESH_POST, user_id: "someone-else" };
  const admin = updateCapableAdminClient(foreign);
  const { deps } = baseDeps({ createAdminClient: () => admin.client });
  const response = await createCommunityPostHandler(deps)(
    jsonRequest({
      post: { id: foreign.id, content: "baskasinin postu" },
      mode: "update",
    }),
  );
  assertEquals(response.status, 403);
  assertEquals((await response.json()).error, "not_post_author");
});

Deno.test("update mode rejects missing post", async () => {
  const admin = updateCapableAdminClient(null);
  const { deps } = baseDeps({ createAdminClient: () => admin.client });
  const response = await createCommunityPostHandler(deps)(
    jsonRequest({
      post: { id: FRESH_POST.id, content: "yok" },
      mode: "update",
    }),
  );
  assertEquals(response.status, 400);
  assertEquals((await response.json()).error, "post_not_found");
});

Deno.test("update mode runs moderation on new content", async () => {
  const admin = updateCapableAdminClient(FRESH_POST);
  const { deps } = baseDeps({ createAdminClient: () => admin.client });
  // moderate-content keyword listesinden bilinen bir kelime kullan —
  // mevcut create-mode moderation testindeki fixture'la AYNI kelimeyi al.
  const response = await createCommunityPostHandler(deps)(
    jsonRequest({
      post: { id: FRESH_POST.id, content: MODERATION_REJECTED_FIXTURE },
      mode: "update",
    }),
  );
  assertEquals(response.status, 400);
  assertEquals((await response.json()).error, "moderation_rejected");
});

Deno.test("update mode requires post id", async () => {
  const { deps } = baseDeps();
  const response = await createCommunityPostHandler(deps)(
    jsonRequest({ post: { content: "id yok" }, mode: "update" }),
  );
  assertEquals(response.status, 400);
});
