import { corsPreflightResponse, getCorsHeaders } from "../_shared/cors.ts";
import { getAuthenticatedUserId } from "../_shared/auth.ts";
import {
  createRateLimiter,
  createSupabaseRateLimitStore,
  rateLimitedResponse,
} from "../_shared/rate-limit.ts";
import { parseRequestBody, z } from "../_shared/validation.ts";
import {
  ImageModerationResult,
  MAX_IMAGE_REQUEST_BODY_BYTES,
  moderateImageWithOpenAI as defaultModerateImage,
  OpenAiModerationError,
  validateImageInput as defaultValidateImageInput,
} from "./moderation.ts";

// One user action fans out to one scan PER IMAGE, and the largest legitimate
// burst is a premium community post at 10 photos (_premiumMaxImages). At the
// previous 10/min that consumed the entire budget in a single attempt: if the
// submission then failed for any other reason — network, text moderation, the
// free-tier check, a Storage error — every scan in the retry returned 429, and
// because ImageSafetyService fails CLOSED the user saw "image rejected" rather
// than a throttle. 30 leaves room for three full attempts and matches the
// sibling moderate-content limiter, so there is one number to reason about.
// The ceiling stays bounded: per-user, authenticated, and every call is already
// capped at 2 MiB.
export const MAX_SCANS_PER_MINUTE = 30;

const rateLimiter = createRateLimiter({
  windowMs: 60_000,
  maxCalls: MAX_SCANS_PER_MINUTE,
  store: createSupabaseRateLimitStore("scan-image-safety"),
});

const scanSchema = z.object({
  image_base64: z.string().optional(),
  mime_type: z.string().optional(),
});

export type ScanImageSafetyDeps = {
  getAuthenticatedUserId(req: Request): Promise<string | null>;
  checkRateLimit(userId: string): boolean | Promise<boolean>;
  validateImageInput(
    imageBase64: string | undefined,
    mimeType: string | undefined,
  ): ImageModerationResult | null;
  getOpenAiApiKey(): string;
  moderateImage(args: {
    apiKey: string;
    imageBase64: string;
    mimeType: string;
  }): Promise<ImageModerationResult>;
};

const defaultDeps: ScanImageSafetyDeps = {
  getAuthenticatedUserId,
  checkRateLimit: (userId) => rateLimiter.check(userId),
  validateImageInput: defaultValidateImageInput,
  getOpenAiApiKey: () => Deno.env.get("OPENAI_API_KEY") ?? "",
  moderateImage: defaultModerateImage,
};

export function createScanImageSafetyHandler(
  deps: ScanImageSafetyDeps = defaultDeps,
) {
  return async (req: Request): Promise<Response> => {
    if (req.method === "OPTIONS") return corsPreflightResponse(req);

    const headers = getCorsHeaders(req);

    try {
      const userId = await deps.getAuthenticatedUserId(req);
      if (!userId) {
        return new Response(
          JSON.stringify({ safe: false, reason: "unauthorized" }),
          { status: 401, headers },
        );
      }

      if (!(await deps.checkRateLimit(userId))) {
        return rateLimitedResponse(headers);
      }

      // MAX_IMAGE_BYTES is 2MB raw image; base64 inflates roughly 33%.
      // Use streaming parsing so chunked requests cannot bypass the cap.
      const parsed = await parseRequestBody(
        req,
        scanSchema,
        headers,
        MAX_IMAGE_REQUEST_BODY_BYTES,
      );
      if (!parsed.success) {
        const status = parsed.response.status === 413 ? 413 : 400;
        return new Response(
          JSON.stringify({
            safe: false,
            reason: status === 413 ? "image_too_large" : "invalid_request",
          }),
          { status, headers },
        );
      }

      const { image_base64: imageBase64, mime_type: mimeType } = parsed.data;

      const inputError = deps.validateImageInput(imageBase64, mimeType);
      if (inputError) {
        const status = inputError.reason === "image_too_large" ? 413 : 400;
        return new Response(JSON.stringify(inputError), { status, headers });
      }

      const openAiApiKey = deps.getOpenAiApiKey();
      if (!openAiApiKey) {
        console.warn("[scan-image-safety] OPENAI_API_KEY missing");
        return new Response(
          JSON.stringify({ safe: false, reason: "safety_scan_unavailable" }),
          { status: 503, headers },
        );
      }

      const moderation = await deps.moderateImage({
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
      // An exhausted provider quota is recoverable from the user's point of
      // view, but uploads must still fail closed until a scan succeeds. Expose
      // only a stable reason code — never OpenAI's raw response body.
      const reason =
        error instanceof OpenAiModerationError && error.status === 429
          ? "safety_scan_rate_limited"
          : "safety_scan_unavailable";
      const errorSummary = error instanceof OpenAiModerationError
        ? `OpenAI moderation request failed with status ${error.status}, kind=${error.kind}`
        : error instanceof Error
        ? error.name
        : "unknown error";
      console.error("[scan-image-safety] Error:", errorSummary);
      return new Response(
        JSON.stringify({ safe: false, reason }),
        { status: 503, headers },
      );
    }
  };
}
