import {
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  estimateBase64Bytes,
  interpretOpenAIModerationResponse,
  MAX_IMAGE_BYTES,
  moderateImageWithOpenAI,
  validateImageInput,
} from "./moderation.ts";

Deno.test("estimateBase64Bytes returns approximate byte count", () => {
  assertEquals(estimateBase64Bytes("QUJDRA=="), 6);
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
  const oversizedBase64 = "a".repeat(
    Math.floor((MAX_IMAGE_BYTES * 4) / 3) + 8,
  );
  assertEquals(
    validateImageInput(oversizedBase64, "image/png"),
    { safe: false, reason: "image_too_large" },
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
