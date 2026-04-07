// moderate-content — Supabase Edge Function
// Checks user-generated text for policy violations.
// Apple App Store Guideline 1.2: UGC content filtering.

import { getCorsHeaders, corsPreflightResponse } from "../_shared/cors.ts";
import { getAuthenticatedUserId } from "../_shared/auth.ts";
import { moderateText, MAX_TEXT_LENGTH } from "./moderation.ts";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return corsPreflightResponse(req);

  const headers = getCorsHeaders(req);

  try {
    const userId = await getAuthenticatedUserId(req);
    if (!userId) {
      return new Response(
        JSON.stringify({ allowed: false, reason: "unauthorized" }),
        { status: 401, headers },
      );
    }

    let text: string | undefined;
    let type: string | undefined;
    try {
      ({ text, type } = await req.json());
    } catch {
      return new Response(
        JSON.stringify({ allowed: false, reason: "invalid_request" }),
        { status: 400, headers },
      );
    }

    // Empty or non-string text: nothing to moderate, allow through.
    // This is intentional — empty content is rejected at the form validation
    // layer, not the moderation layer.
    if (!text || typeof text !== "string") {
      return new Response(
        JSON.stringify({ allowed: true }),
        { headers },
      );
    }

    if (text.length > MAX_TEXT_LENGTH) {
      return new Response(
        JSON.stringify({ allowed: false, reason: "content_too_long" }),
        { status: 400, headers },
      );
    }

    const result = moderateText(text);

    if (!result.allowed) {
      console.log(
        `[moderate-content] Rejected: user=${userId}, reason=${result.reason}, type=${type ?? "text"}`,
      );
    }

    return new Response(JSON.stringify(result), { headers });
  } catch (error) {
    console.error("[moderate-content] Error:", error);
    // Fail-closed: reject content when moderation is unavailable
    return new Response(
      JSON.stringify({ allowed: false, reason: "moderation_unavailable" }),
      { status: 503, headers },
    );
  }
});
