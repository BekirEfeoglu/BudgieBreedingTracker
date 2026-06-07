import {
  createSupabaseAdmin,
  getAuthenticatedUserId,
} from "../_shared/auth.ts";
import {
  createRateLimiter,
  createSupabaseRateLimitStore,
  rateLimitedResponse,
} from "../_shared/rate-limit.ts";
import { corsPreflightResponse, getCorsHeaders } from "../_shared/cors.ts";
import { parseRequestBody, z } from "../_shared/validation.ts";
import {
  ImageModerationResult,
  moderateImageWithOpenAI,
  validateImageInput,
} from "../scan-image-safety/moderation.ts";

const BUCKET = "community-photos";
const SIGNED_URL_EXPIRY_SECONDS = 60 * 60 * 24 * 7;
const MAX_BODY_BYTES = 4 * 1024 * 1024;

const rateLimiter = createRateLimiter({
  windowMs: 60_000,
  maxCalls: 20,
  store: createSupabaseRateLimitStore("upload-community-photo"),
});

const uploadSchema = z.object({
  post_id: z.string().uuid(),
  filename: z.string().min(1).max(180),
  image_base64: z.string().optional(),
  mime_type: z.string().optional(),
});

const MIME_TO_EXT: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/gif": "gif",
  "image/webp": "webp",
  "image/heic": "heic",
  "image/heif": "heic",
};

type SupabaseAdminClient = any;

export type UploadCommunityPhotoDeps = {
  getAuthenticatedUserId(req: Request): Promise<string | null>;
  checkRateLimit(userId: string): boolean | Promise<boolean>;
  createAdminClient(): SupabaseAdminClient;
  getOpenAiApiKey(): string;
  moderateImage(args: {
    apiKey: string;
    imageBase64: string;
    mimeType: string;
  }): Promise<ImageModerationResult>;
  nowMs(): number;
  randomUUID(): string;
};

const defaultDeps: UploadCommunityPhotoDeps = {
  getAuthenticatedUserId,
  checkRateLimit: (userId) => rateLimiter.check(userId),
  createAdminClient: createSupabaseAdmin,
  getOpenAiApiKey: () => Deno.env.get("OPENAI_API_KEY") ?? "",
  moderateImage: moderateImageWithOpenAI,
  nowMs: () => Date.now(),
  randomUUID: () => crypto.randomUUID(),
};

function decodeBase64(value: string): Uint8Array | null {
  try {
    const binary = atob(value);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
      bytes[i] = binary.charCodeAt(i);
    }
    return bytes;
  } catch {
    return null;
  }
}

function extensionFor(filename: string): string | null {
  const match = /\.([a-zA-Z0-9]+)$/.exec(filename.trim());
  if (!match) return null;
  const ext = match[1].toLowerCase();
  if (ext === "jpeg") return "jpg";
  if (ext === "heif") return "heic";
  return ext;
}

function hasMagicBytes(bytes: Uint8Array, ext: string): boolean {
  switch (ext) {
    case "jpg":
      return bytes.length >= 3 &&
        bytes[0] === 0xff &&
        bytes[1] === 0xd8 &&
        bytes[2] === 0xff;
    case "png":
      return bytes.length >= 4 &&
        bytes[0] === 0x89 &&
        bytes[1] === 0x50 &&
        bytes[2] === 0x4e &&
        bytes[3] === 0x47;
    case "gif":
      return bytes.length >= 3 &&
        bytes[0] === 0x47 &&
        bytes[1] === 0x49 &&
        bytes[2] === 0x46;
    case "webp":
      return bytes.length >= 12 &&
        bytes[0] === 0x52 &&
        bytes[1] === 0x49 &&
        bytes[2] === 0x46 &&
        bytes[3] === 0x46 &&
        bytes[8] === 0x57 &&
        bytes[9] === 0x45 &&
        bytes[10] === 0x42 &&
        bytes[11] === 0x50;
    case "heic":
      return bytes.length >= 12 &&
        bytes[4] === 0x66 &&
        bytes[5] === 0x74 &&
        bytes[6] === 0x79 &&
        bytes[7] === 0x70 &&
        bytes[8] === 0x68 &&
        bytes[9] === 0x65 &&
        bytes[10] === 0x69 &&
        (bytes[11] === 0x63 || bytes[11] === 0x66);
    default:
      return false;
  }
}

export function uploadCommunityPhotoHandler(
  deps: UploadCommunityPhotoDeps = defaultDeps,
) {
  return async (req: Request): Promise<Response> => {
    if (req.method === "OPTIONS") return corsPreflightResponse(req);

    const headers = getCorsHeaders(req);

    try {
      const userId = await deps.getAuthenticatedUserId(req);
      if (!userId) {
        return new Response(JSON.stringify({ error: "unauthorized" }), {
          status: 401,
          headers,
        });
      }

      if (!(await deps.checkRateLimit(userId))) {
        return rateLimitedResponse(headers);
      }

      const parsed = await parseRequestBody(
        req,
        uploadSchema,
        headers,
        MAX_BODY_BYTES,
      );
      if (!parsed.success) return parsed.response;

      const {
        post_id: postId,
        filename,
        image_base64: imageBase64,
        mime_type: mimeType,
      } = parsed.data;

      const inputError = validateImageInput(imageBase64, mimeType);
      if (inputError) {
        const status = inputError.reason === "image_too_large" ? 413 : 400;
        return new Response(JSON.stringify(inputError), { status, headers });
      }

      const mimeExt = MIME_TO_EXT[mimeType!];
      const fileExt = extensionFor(filename);
      if (!mimeExt || !fileExt || mimeExt !== fileExt) {
        return new Response(
          JSON.stringify({ safe: false, reason: "invalid_mime_type" }),
          { status: 400, headers },
        );
      }

      const bytes = decodeBase64(imageBase64!);
      if (!bytes || !hasMagicBytes(bytes, fileExt)) {
        return new Response(
          JSON.stringify({ safe: false, reason: "invalid_image_bytes" }),
          { status: 400, headers },
        );
      }

      const openAiApiKey = deps.getOpenAiApiKey();
      if (!openAiApiKey) {
        console.warn("[upload-community-photo] OPENAI_API_KEY missing");
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
        return new Response(
          JSON.stringify({ safe: false, reason: moderation.reason }),
          { status: 400, headers },
        );
      }

      const objectPath =
        `${userId}/${postId}/${deps.nowMs()}-${deps.randomUUID()}.${fileExt}`;
      const storage = deps.createAdminClient().storage.from(BUCKET);
      const { error: uploadError } = await storage.upload(objectPath, bytes, {
        contentType: mimeType!,
        upsert: false,
      });
      if (uploadError) {
        return new Response(JSON.stringify({ error: "upload_failed" }), {
          status: 500,
          headers,
        });
      }

      const { data, error: signError } = await storage.createSignedUrl(
        objectPath,
        SIGNED_URL_EXPIRY_SECONDS,
      );
      if (signError || !data?.signedUrl) {
        return new Response(JSON.stringify({ error: "signed_url_failed" }), {
          status: 500,
          headers,
        });
      }

      return new Response(
        JSON.stringify({ signed_url: data.signedUrl, path: objectPath }),
        { headers },
      );
    } catch (error) {
      console.error("[upload-community-photo] Error:", error);
      return new Response(
        JSON.stringify({ safe: false, reason: "safety_scan_unavailable" }),
        { status: 503, headers },
      );
    }
  };
}
