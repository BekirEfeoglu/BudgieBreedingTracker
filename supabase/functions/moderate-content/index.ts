// moderate-content — Supabase Edge Function
// Checks user-generated text for policy violations.
// Apple App Store Guideline 1.2: UGC content filtering.

import { getCorsHeaders, corsPreflightResponse } from "../_shared/cors.ts";
import { getAuthenticatedUserId } from "../_shared/auth.ts";
import { createRateLimiter, rateLimitedResponse } from "../_shared/rate-limit.ts";
import { moderateText, MAX_TEXT_LENGTH } from "./moderation.ts";
import { z } from "npm:zod@3.24.4";
import { parseRequestBody } from "../_shared/validation.ts";

const rateLimiter = createRateLimiter({ windowMs: 60_000, maxCalls: 30 });

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

    if (!rateLimiter.check(userId)) return rateLimitedResponse(headers);

    const moderateSchema = z.object({
      text: z.string().optional(),
      type: z.string().optional(),
    });

    const parsed = await parseRequestBody(req, moderateSchema, headers);
    if (!parsed.success) return parsed.response;

    const { text, type } = parsed.data;

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
