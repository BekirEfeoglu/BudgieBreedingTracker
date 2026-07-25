import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { createScanImageSafetyHandler } from "./handler.ts";
import {
  MAX_IMAGE_BYTES,
  MAX_IMAGE_REQUEST_BODY_BYTES,
  validateImageInput,
} from "./moderation.ts";

function jsonRequest(body: unknown): Request {
  return new Request("https://example.com/scan-image-safety", {
    method: "POST",
    body: JSON.stringify(body),
  });
}

function malformedRequest(): Request {
  return new Request("https://example.com/scan-image-safety", {
    method: "POST",
    body: "{not valid json",
  });
}

function baseDeps(overrides: Record<string, unknown> = {}) {
  return {
    getAuthenticatedUserId: () => Promise.resolve("test-user"),
    checkRateLimit: () => Promise.resolve(true),
    validateImageInput: () => null,
    getOpenAiApiKey: () => "test-api-key",
    moderateImage: () => Promise.resolve({ safe: true }),
    ...overrides,
  };
}

Deno.test("scan-image-safety rejects missing/invalid authentication", async () => {
  const response = await createScanImageSafetyHandler(
    baseDeps({ getAuthenticatedUserId: () => Promise.resolve(null) }),
  )(jsonRequest({ image_base64: "QUJDRA==", mime_type: "image/jpeg" }));

  assertEquals(response.status, 401);
  assertEquals(await response.json(), {
    safe: false,
    reason: "unauthorized",
  });
});

Deno.test("scan-image-safety rejects malformed body", async () => {
  const response = await createScanImageSafetyHandler(baseDeps())(
    malformedRequest(),
  );

  assertEquals(response.status, 400);
  // The other half of the bespoke parse remap: non-413 parse failures report
  // invalid_request, never image_too_large.
  assertEquals(await response.json(), {
    safe: false,
    reason: "invalid_request",
  });
});

Deno.test("scan-image-safety fails closed when OPENAI_API_KEY missing", async () => {
  const response = await createScanImageSafetyHandler(
    baseDeps({ getOpenAiApiKey: () => "" }),
  )(jsonRequest({ image_base64: "QUJDRA==", mime_type: "image/jpeg" }));

  assertEquals(response.status, 503);
  assertEquals(await response.json(), {
    safe: false,
    reason: "safety_scan_unavailable",
  });
});

Deno.test("scan-image-safety allows a safe image", async () => {
  const response = await createScanImageSafetyHandler(baseDeps())(
    jsonRequest({ image_base64: "QUJDRA==", mime_type: "image/jpeg" }),
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { safe: true });
});

// --- 2 MiB raw boundary ---------------------------------------------------
// Mirrors upload-community-photo/handler_test.ts, but this function does NOT
// share its sibling's response shape: oversize is remapped to a 413 with
// `image_too_large`, while every other parse failure stays 400/invalid_request.
// These run the REAL validateImageInput instead of the baseDeps stub.

const ENCODED_LIMIT_CHARS = Math.ceil(MAX_IMAGE_BYTES / 3) * 4;

Deno.test("scan-image-safety accepts exactly 2MB raw", async () => {
  let moderated = 0;
  const exactLimitJpegBase64 = `/9j/${"A".repeat(ENCODED_LIMIT_CHARS - 5)}=`;

  const response = await createScanImageSafetyHandler(
    baseDeps({
      validateImageInput,
      moderateImage: () => {
        moderated++;
        return Promise.resolve({ safe: true });
      },
    }),
  )(
    jsonRequest({
      image_base64: exactLimitJpegBase64,
      mime_type: "image/jpeg",
    }),
  );

  assertEquals(response.status, 200);
  assertEquals(await response.json(), { safe: true });
  assertEquals(moderated, 1);
});

Deno.test("scan-image-safety rejects one raw byte above 2MB", async () => {
  let moderated = 0;
  const oversizedJpegBase64 = `/9j/${"A".repeat(ENCODED_LIMIT_CHARS - 4)}`;

  const response = await createScanImageSafetyHandler(
    baseDeps({
      validateImageInput,
      moderateImage: () => {
        moderated++;
        return Promise.resolve({ safe: true });
      },
    }),
  )(
    jsonRequest({
      image_base64: oversizedJpegBase64,
      mime_type: "image/jpeg",
    }),
  );

  assertEquals(response.status, 413);
  assertEquals(await response.json(), {
    safe: false,
    reason: "image_too_large",
  });
  assertEquals(moderated, 0);
});

Deno.test("scan-image-safety remaps an oversized request body to 413 image_too_large", async () => {
  let moderated = 0;
  // Beyond the streaming body cap, so parseRequestBody aborts the read with a
  // 413 before schema validation — the branch the handler remaps.
  const overBodyBase64 = "A".repeat(MAX_IMAGE_REQUEST_BODY_BYTES + 1);

  const response = await createScanImageSafetyHandler(
    baseDeps({
      validateImageInput,
      moderateImage: () => {
        moderated++;
        return Promise.resolve({ safe: true });
      },
    }),
  )(
    jsonRequest({ image_base64: overBodyBase64, mime_type: "image/jpeg" }),
  );

  assertEquals(response.status, 413);
  assertEquals(await response.json(), {
    safe: false,
    reason: "image_too_large",
  });
  assertEquals(moderated, 0);
});
