import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { createScanImageSafetyHandler } from "./handler.ts";

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
