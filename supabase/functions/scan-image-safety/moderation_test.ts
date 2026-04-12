import {
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  estimateBase64Bytes,
  interpretOpenAIModerationResponse,
  MAX_IMAGE_BYTES,
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
