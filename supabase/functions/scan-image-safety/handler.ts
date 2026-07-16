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
  validateImageInput as defaultValidateImageInput,
} from "./moderation.ts";

const rateLimiter = createRateLimiter({
  windowMs: 60_000,
  maxCalls: 10,
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
      console.error("[scan-image-safety] Error:", error);
      return new Response(
        JSON.stringify({ safe: false, reason: "safety_scan_unavailable" }),
        { status: 503, headers },
      );
    }
  };
}
