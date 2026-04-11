export const MAX_IMAGE_BYTES = 2 * 1024 * 1024;

export interface ImageModerationResult {
  safe: boolean;
  reason?: string;
  raw?: unknown;
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
  return Math.floor((base64.length * 3) / 4);
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
          image_url: `data:${mimeType};base64,${imageBase64}`,
        },
      ],
    }),
  });

  if (!res.ok) {
    const errorText = await res.text();
    throw new Error(`OpenAI moderation failed (${res.status}): ${errorText}`);
  }

  const data = await res.json() as OpenAIModerationResponse;
  return interpretOpenAIModerationResponse(data);
}
