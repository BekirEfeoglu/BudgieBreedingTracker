import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  estimateBase64Bytes,
  interpretOpenAIModerationResponse,
  MAX_IMAGE_BYTES,
  moderateImageWithOpenAI,
  OpenAiModerationError,
  validateImageInput,
} from "./moderation.ts";

Deno.test("estimateBase64Bytes accounts for base64 padding", () => {
  assertEquals(estimateBase64Bytes("QQ=="), 1);
  assertEquals(estimateBase64Bytes("QUI="), 2);
  assertEquals(estimateBase64Bytes("QUJD"), 3);
  assertEquals(estimateBase64Bytes("QUJDRA=="), 4);
});

Deno.test("validateImageInput rejects missing image", () => {
  assertEquals(
    validateImageInput(undefined, "image/jpeg"),
    { safe: false, reason: "invalid_request" },
  );
});

Deno.test("validateImageInput rejects invalid mime type", () => {
  assertEquals(
    validateImageInput("abcd", "text/plain"),
    { safe: false, reason: "invalid_mime_type" },
  );
});

Deno.test("validateImageInput rejects oversized image", () => {
  const encodedLength = Math.ceil(MAX_IMAGE_BYTES / 3) * 4;
  const oversizedBase64 = "A".repeat(encodedLength);
  assertEquals(
    validateImageInput(oversizedBase64, "image/png"),
    { safe: false, reason: "image_too_large" },
  );
});

Deno.test("validateImageInput allows exactly the raw byte limit", () => {
  const encodedLength = Math.ceil(MAX_IMAGE_BYTES / 3) * 4;
  const exactLimitBase64 = `${"A".repeat(encodedLength - 1)}=`;

  assertEquals(
    estimateBase64Bytes(exactLimitBase64),
    MAX_IMAGE_BYTES,
  );
  assertEquals(
    validateImageInput(exactLimitBase64, "image/png"),
    null,
  );
});

Deno.test("validateImageInput allows valid image payload", () => {
  assertEquals(
    validateImageInput("QUJDRA==", "image/jpeg"),
    null,
  );
});

Deno.test("interpretOpenAIModerationResponse allows clean response", () => {
  const result = interpretOpenAIModerationResponse({
    results: [{ flagged: false, categories: { violence: false } }],
  });

  assertEquals(result.safe, true);
  assertEquals(result.reason, undefined);
});

Deno.test("interpretOpenAIModerationResponse rejects blocked category", () => {
  const result = interpretOpenAIModerationResponse({
    results: [
      {
        flagged: true,
        categories: { "sexual/minors": true },
      },
    ],
  });

  assertEquals(result.safe, false);
  assertEquals(result.reason, "sexual_minors");
});

Deno.test("interpretOpenAIModerationResponse rejects generic flagged result", () => {
  const result = interpretOpenAIModerationResponse({
    results: [{ flagged: true, categories: {} }],
  });

  assertEquals(result.safe, false);
  assertEquals(result.reason, "image_flagged");
});

Deno.test("interpretOpenAIModerationResponse rejects empty provider response", () => {
  const result = interpretOpenAIModerationResponse({});

  assertEquals(result.safe, false);
  assertEquals(result.reason, "invalid_provider_response");
});

Deno.test("moderateImageWithOpenAI sends image_url as an object with a url key", async () => {
  const originalFetch = globalThis.fetch;
  let capturedBody: string | undefined;
  globalThis.fetch = ((_url: string | URL | Request, init?: RequestInit) => {
    capturedBody = init?.body as string;
    return Promise.resolve(
      new Response(
        JSON.stringify({ results: [{ flagged: false, categories: {} }] }),
        { status: 200 },
      ),
    );
  }) as typeof fetch;

  try {
    await moderateImageWithOpenAI({
      apiKey: "test-key",
      imageBase64: "QUJDRA==",
      mimeType: "image/jpeg",
    });

    const parsed = JSON.parse(capturedBody ?? "{}");
    const imageUrl = parsed.input?.[0]?.image_url;
    // Must be an object { url }, NOT a bare string (OpenAI rejects the string).
    assertEquals(typeof imageUrl, "object");
    assertEquals(imageUrl.url, "data:image/jpeg;base64,QUJDRA==");
  } finally {
    globalThis.fetch = originalFetch;
  }
});

Deno.test("moderateImageWithOpenAI safely classifies provider quota failures", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = (() =>
    Promise.resolve(
      new Response(
        JSON.stringify({
          error: { code: "insufficient_quota", message: "provider detail" },
        }),
        { status: 429 },
      ),
    )) as typeof fetch;

  try {
    let error: unknown;
    try {
      await moderateImageWithOpenAI({
        apiKey: "test-key",
        imageBase64: "QUJDRA==",
        mimeType: "image/jpeg",
      });
    } catch (caught) {
      error = caught;
    }

    assertEquals(error instanceof OpenAiModerationError, true);
    assertEquals((error as OpenAiModerationError).status, 429);
    assertEquals((error as OpenAiModerationError).kind, "quota_exhausted");
    assertEquals((error as Error).message.includes("provider detail"), false);
  } finally {
    globalThis.fetch = originalFetch;
  }
});
