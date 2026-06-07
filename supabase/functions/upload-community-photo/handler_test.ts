import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { uploadCommunityPhotoHandler } from "./handler.ts";

const postId = "00000000-0000-7000-8000-000000000333";
const tinyJpegBase64 = btoa(
  String.fromCharCode(0xff, 0xd8, 0xff, 0xdb, 0x00, 0x43),
);

function jsonRequest(body: unknown): Request {
  return new Request("https://example.com/upload-community-photo", {
    method: "POST",
    body: JSON.stringify(body),
  });
}

function validBody(overrides: Record<string, unknown> = {}) {
  return {
    post_id: postId,
    filename: "photo.jpg",
    image_base64: tinyJpegBase64,
    mime_type: "image/jpeg",
    ...overrides,
  };
}

function baseDeps(overrides: Record<string, unknown> = {}) {
  const uploaded: Record<string, unknown>[] = [];
  return {
    uploaded,
    deps: {
      getAuthenticatedUserId: () => Promise.resolve("uploader-user"),
      checkRateLimit: () => Promise.resolve(true),
      getOpenAiApiKey: () => "test-openai-key",
      moderateImage: () => Promise.resolve({ safe: true }),
      nowMs: () => 1700000000000,
      randomUUID: () => "00000000-0000-7000-8000-000000000444",
      createAdminClient: () => ({
        storage: {
          from: (bucket: string) => ({
            upload: (
              path: string,
              bytes: Uint8Array,
              options: Record<string, unknown>,
            ) => {
              uploaded.push({ bucket, path, bytes, options });
              return Promise.resolve({ error: null });
            },
            createSignedUrl: (path: string, expiresIn: number) =>
              Promise.resolve({
                data: {
                  signedUrl:
                    `https://example.supabase.co/storage/v1/object/sign/community-photos/${path}`,
                },
                error: null,
                expiresIn,
              }),
          }),
        },
      }),
      ...overrides,
    },
  };
}

Deno.test("upload-community-photo rejects missing authentication", async () => {
  const { deps } = baseDeps({
    getAuthenticatedUserId: () => Promise.resolve(null),
  });

  const response = await uploadCommunityPhotoHandler(deps)(
    jsonRequest(validBody()),
  );

  assertEquals(response.status, 401);
  assertEquals(await response.json(), { error: "unauthorized" });
});

Deno.test("upload-community-photo rejects invalid image bytes", async () => {
  const { deps, uploaded } = baseDeps();

  const response = await uploadCommunityPhotoHandler(deps)(
    jsonRequest(validBody({ image_base64: btoa("not-a-jpeg") })),
  );

  assertEquals(response.status, 400);
  assertEquals(await response.json(), {
    safe: false,
    reason: "invalid_image_bytes",
  });
  assertEquals(uploaded.length, 0);
});

Deno.test("upload-community-photo fails closed when image scanner is unavailable", async () => {
  const { deps, uploaded } = baseDeps({ getOpenAiApiKey: () => "" });

  const response = await uploadCommunityPhotoHandler(deps)(
    jsonRequest(validBody()),
  );

  assertEquals(response.status, 503);
  assertEquals(await response.json(), {
    safe: false,
    reason: "safety_scan_unavailable",
  });
  assertEquals(uploaded.length, 0);
});

Deno.test("upload-community-photo rejects unsafe moderation result before upload", async () => {
  const { deps, uploaded } = baseDeps({
    moderateImage: () =>
      Promise.resolve({ safe: false, reason: "image_flagged" }),
  });

  const response = await uploadCommunityPhotoHandler(deps)(
    jsonRequest(validBody()),
  );

  assertEquals(response.status, 400);
  assertEquals(await response.json(), {
    safe: false,
    reason: "image_flagged",
  });
  assertEquals(uploaded.length, 0);
});

Deno.test("upload-community-photo uploads under authenticated user path", async () => {
  const { deps, uploaded } = baseDeps();

  const response = await uploadCommunityPhotoHandler(deps)(
    jsonRequest(validBody()),
  );

  assertEquals(response.status, 200);
  assertEquals(uploaded.length, 1);
  assertEquals(uploaded[0].bucket, "community-photos");
  assertEquals(
    uploaded[0].path,
    "uploader-user/00000000-0000-7000-8000-000000000333/" +
      "1700000000000-00000000-0000-7000-8000-000000000444.jpg",
  );
  assertEquals((await response.json()).path, uploaded[0].path);
});
