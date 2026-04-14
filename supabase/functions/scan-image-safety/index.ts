import { corsPreflightResponse, getCorsHeaders } from "../_shared/cors.ts";
import { getAuthenticatedUserId } from "../_shared/auth.ts";
import { createRateLimiter, rateLimitedResponse } from "../_shared/rate-limit.ts";
import {
  moderateImageWithOpenAI,
  validateImageInput,
} from "./moderation.ts";

const rateLimiter = createRateLimiter({ windowMs: 60_000, maxCalls: 10 });

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return corsPreflightResponse(req);

  const headers = getCorsHeaders(req);

  try {
    const userId = await getAuthenticatedUserId(req);
    if (!userId) {
      return new Response(
        JSON.stringify({ safe: false, reason: "unauthorized" }),
        { status: 401, headers },
      );
    }

    if (!rateLimiter.check(userId)) return rateLimitedResponse(headers);

    // Guard against oversized payloads before parsing body into memory.
    // MAX_IMAGE_BYTES is 2MB of raw image; base64 encoding inflates ~33%,
    // plus JSON overhead — cap at 4MB total to prevent OOM.
    const MAX_BODY_BYTES = 4 * 1024 * 1024;
    const contentLength = parseInt(req.headers.get("content-length") ?? "0", 10);
    if (contentLength > MAX_BODY_BYTES) {
      return new Response(
        JSON.stringify({ safe: false, reason: "image_too_large" }),
        { status: 413, headers },
      );
    }

    let imageBase64: string | undefined;
    let mimeType: string | undefined;
    try {
      ({ image_base64: imageBase64, mime_type: mimeType } = await req.json());
    } catch {
      return new Response(
        JSON.stringify({ safe: false, reason: "invalid_request" }),
        { status: 400, headers },
      );
    }

    const inputError = validateImageInput(imageBase64, mimeType);
    if (inputError) {
      const status = inputError.reason === "image_too_large" ? 413 : 400;
      return new Response(JSON.stringify(inputError), { status, headers });
    }

    const openAiApiKey = Deno.env.get("OPENAI_API_KEY") ?? "";
    if (!openAiApiKey) {
      console.warn("[scan-image-safety] OPENAI_API_KEY missing");
      return new Response(
        JSON.stringify({ safe: false, reason: "safety_scan_unavailable" }),
        { status: 503, headers },
      );
    }

    const moderation = await moderateImageWithOpenAI({
      apiKey: openAiApiKey,
      imageBase64: imageBase64!,
      mimeType: mimeType!,
    });

    if (!moderation.safe) {
      console.log(
        `[scan-image-safety] Rejected: user=${userId}, reason=${moderation.reason}`,
      );
    }

    return new Response(
      JSON.stringify({ safe: moderation.safe, reason: moderation.reason }),
      { headers },
    );
  } catch (error) {
    console.error("[scan-image-safety] Error:", error);
    return new Response(
      JSON.stringify({ safe: false, reason: "safety_scan_unavailable" }),
      { status: 503, headers },
    );
  }
});
