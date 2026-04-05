// moderate-content — Supabase Edge Function
// Checks user-generated text for policy violations.
// Apple App Store Guideline 1.2: UGC content filtering.

import { getCorsHeaders, corsPreflightResponse } from "../_shared/cors.ts";
import { getAuthenticatedUserId } from "../_shared/auth.ts";

const PROHIBITED_PATTERNS: string[] = [
  // Violence & threats (EN/TR/DE)
  "i will kill", "death threat", "bomb threat",
  "seni öldürür", "bomba atacağ",
  "ich werde dich töten", "bombendrohung",
  // Spam / scam
  "buy followers", "free money", "click here to win",
  "takipçi satın", "bedava para", "hemen tıkla kazan",
  "follower kaufen", "gratis geld",
  // URL spam
  "bit.ly/", "tinyurl.com/",
  // Self-harm
  "how to kill yourself", "intihar yöntemi", "suizidmethode",
];

interface ModerationResult {
  allowed: boolean;
  reason?: string;
}

function moderateText(text: string): ModerationResult {
  const normalized = text.toLowerCase();

  for (const pattern of PROHIBITED_PATTERNS) {
    if (normalized.includes(pattern)) {
      return { allowed: false, reason: "content_violation" };
    }
  }

  if (text.length > 20) {
    const upperCount = [...text].filter(
      (ch) => ch !== ch.toLowerCase() && ch !== ch.toUpperCase()
        ? false
        : ch !== ch.toLowerCase()
    ).length;
    if (upperCount / text.length > 0.7) {
      return { allowed: false, reason: "excessive_caps" };
    }
  }

  if (/(.)\1{9,}/.test(normalized)) {
    return { allowed: false, reason: "spam_detected" };
  }

  const urlCount = (normalized.match(/https?:\/\//g) || []).length;
  if (urlCount > 3) {
    return { allowed: false, reason: "spam_detected" };
  }

  return { allowed: true };
}

const MAX_TEXT_LENGTH = 10000;

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

    const { text, type } = await req.json();

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
    // Fail-open: allow but flag for manual review
    return new Response(
      JSON.stringify({ allowed: true, reason: "error_fallback", needs_review: true }),
      { headers },
    );
  }
});
