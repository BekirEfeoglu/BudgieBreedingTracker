// Keep scanned uploads at 2 MiB raw. Raising this to the general 10 MiB upload
// budget would create a 13.33 MiB base64 field. `parseRequestBody` retains the
// incoming chunks and copies them into a contiguous body before JSON parsing;
// community upload then allocates decoded bytes, and the OpenAI request is
// serialized again. The tighter cap bounds transient Edge memory/CPU and
// authenticated payload-amplification abuse without weakening fail-closed scan.
// Hosted runtime constraints are tracked in `.claude/rules/edge-functions.md`.
export const MAX_IMAGE_BYTES = 2 * 1024 * 1024;
export const MAX_IMAGE_BASE64_CHARS = Math.ceil(MAX_IMAGE_BYTES / 3) * 4;

// JSON keys, MIME, UUID, and the maximum 180-character filename stay well
// below this explicit envelope. It admits the exact raw limit after base64
// inflation while rejecting materially oversized bodies during streaming read.
export const MAX_IMAGE_REQUEST_BODY_BYTES = MAX_IMAGE_BASE64_CHARS + 1024;

export interface ImageModerationResult {
  safe: boolean;
  reason?: string;
  raw?: unknown;
}

/// A provider failure that can be classified without exposing OpenAI's
/// response body to the client or to application logs.
export class OpenAiModerationError extends Error {
  readonly status: number;
  /// Safe, allowlisted provider classification. Raw provider payloads never
  /// leave this module or reach function logs.
  readonly kind: "quota_exhausted" | "rate_limited" | "unavailable";

  constructor(
    status: number,
    kind: "quota_exhausted" | "rate_limited" | "unavailable" = status === 429
      ? "rate_limited"
      : "unavailable",
  ) {
    super(`OpenAI moderation request failed with status ${status}`);
    this.name = "OpenAiModerationError";
    this.status = status;
    this.kind = kind;
  }
}

interface OpenAiErrorResponse {
  error?: {
    code?: unknown;
    type?: unknown;
  };
}

function classifyOpenAiFailure(
  status: number,
  body: string,
): OpenAiModerationError["kind"] {
  if (status !== 429) return "unavailable";

  // The provider's body can contain request diagnostics. Read only the two
  // documented machine fields and keep a small allowlist; never log or return
  // the body itself.
  try {
    const parsed = JSON.parse(body) as OpenAiErrorResponse;
    const code = typeof parsed.error?.code === "string"
      ? parsed.error.code
      : typeof parsed.error?.type === "string"
      ? parsed.error.type
      : "";
    if (code === "insufficient_quota") return "quota_exhausted";
  } catch {
    // A malformed provider failure stays safely classified as rate-limited.
  }
  return "rate_limited";
}

interface OpenAIModerationCategoryMap {
  [key: string]: boolean | undefined;
}

interface OpenAIModerationResult {
  flagged?: boolean;
  categories?: OpenAIModerationCategoryMap;
}

interface OpenAIModerationResponse {
  results?: OpenAIModerationResult[];
}

const BLOCKED_CATEGORY_REASONS: Record<string, string> = {
  sexual: "sexual_content",
  "sexual/minors": "sexual_minors",
  harassment: "harassment",
  "harassment/threatening": "harassment_threatening",
  hate: "hate_content",
  "hate/threatening": "hate_threatening",
  illicit: "illicit_content",
  "illicit/violent": "illicit_violent",
  "self-harm": "self_harm",
  "self-harm/intent": "self_harm_intent",
  "self-harm/instructions": "self_harm_instructions",
  violence: "violence",
  "violence/graphic": "graphic_violence",
};

export function estimateBase64Bytes(base64: string): number {
  const padding = base64.endsWith("==") ? 2 : base64.endsWith("=") ? 1 : 0;
  return Math.floor((base64.length * 3) / 4) - padding;
}

export function validateImageInput(
  imageBase64: string | undefined,
  mimeType: string | undefined,
): ImageModerationResult | null {
  if (!imageBase64 || typeof imageBase64 !== "string") {
    return { safe: false, reason: "invalid_request" };
  }

  if (
    !mimeType ||
    typeof mimeType !== "string" ||
    !mimeType.startsWith("image/")
  ) {
    return { safe: false, reason: "invalid_mime_type" };
  }

  if (estimateBase64Bytes(imageBase64) > MAX_IMAGE_BYTES) {
    return { safe: false, reason: "image_too_large" };
  }

  return null;
}

export function interpretOpenAIModerationResponse(
  response: OpenAIModerationResponse,
): ImageModerationResult {
  const result = response.results?.[0];
  if (!result) {
    return { safe: false, reason: "invalid_provider_response", raw: response };
  }

  const categories = result.categories ?? {};
  for (const [key, reason] of Object.entries(BLOCKED_CATEGORY_REASONS)) {
    if (categories[key]) {
      return { safe: false, reason, raw: result };
    }
  }

  if (result.flagged) {
    return { safe: false, reason: "image_flagged", raw: result };
  }

  return { safe: true, raw: result };
}

export async function moderateImageWithOpenAI(args: {
  apiKey: string;
  imageBase64: string;
  mimeType: string;
}): Promise<ImageModerationResult> {
  const { apiKey, imageBase64, mimeType } = args;

  const res = await fetch("https://api.openai.com/v1/moderations", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: "omni-moderation-latest",
      input: [
        {
          type: "image_url",
          // OpenAI's moderations API requires image_url as an object with a
          // `url` key — a bare string is rejected with HTTP 400 (which the
          // caller turns into a fail-closed 503, blocking all photo posts).
          image_url: {
            url: `data:${mimeType};base64,${imageBase64}`,
          },
        },
      ],
    }),
  });

  if (!res.ok) {
    // The response body can contain provider-specific diagnostic data. Keep it
    // out of client-visible errors and logs; use only an allowlisted category
    // for production diagnosis while retaining the stable fail-closed contract.
    const body = await res.text();
    throw new OpenAiModerationError(
      res.status,
      classifyOpenAiFailure(res.status, body),
    );
  }

  const data = await res.json() as OpenAIModerationResponse;
  return interpretOpenAIModerationResponse(data);
}
