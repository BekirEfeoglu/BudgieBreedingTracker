import { corsPreflightResponse, getCorsHeaders } from "../_shared/cors.ts";
import { getAuthenticatedUserId } from "../_shared/auth.ts";
import {
  moderateImageWithOpenAI,
  validateImageInput,
} from "./moderation.ts";

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
