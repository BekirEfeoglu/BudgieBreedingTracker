// moderate-content — Supabase Edge Function
// Checks user-generated text for policy violations.
// Apple App Store Guideline 1.2: UGC content filtering.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ALLOWED_ORIGINS = (Deno.env.get("ALLOWED_ORIGINS") ?? "")
  .split(",")
  .map((o) => o.trim())
  .filter((o) => o.length > 0);

function getCorsHeaders(req: Request) {
  const origin = req.headers.get("Origin") ?? "";
  const allowedOrigin = ALLOWED_ORIGINS.includes(origin) ? origin : "";
  return {
    "Access-Control-Allow-Origin": allowedOrigin,
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
  };
}

// ---------------------------------------------------------------------------
// Prohibited patterns (multilingual: TR, EN, DE)
// ---------------------------------------------------------------------------

const PROHIBITED_PATTERNS: string[] = [
  // Violence & threats (EN)
  "i will kill",
  "death threat",
  "bomb threat",
  // Violence & threats (TR)
  "seni öldürür",
  "bomba atacağ",
  // Violence & threats (DE)
  "ich werde dich töten",
  "bombendrohung",

  // Spam / scam
  "buy followers",
  "free money",
  "click here to win",
  "takipçi satın",
  "bedava para",
  "hemen tıkla kazan",
  "follower kaufen",
  "gratis geld",

  // URL spam
  "bit.ly/",
  "tinyurl.com/",

  // Self-harm
  "how to kill yourself",
  "intihar yöntemi",
  "suizidmethode",
];

// ---------------------------------------------------------------------------
// Moderation logic
// ---------------------------------------------------------------------------

interface ModerationResult {
  allowed: boolean;
  reason?: string;
}

function moderateText(text: string): ModerationResult {
  const normalized = text.toLowerCase();

  // 1. Prohibited keyword check
  for (const pattern of PROHIBITED_PATTERNS) {
    if (normalized.includes(pattern)) {
      return { allowed: false, reason: "content_violation" };
    }
  }

  // 2. Excessive caps detection (>70% uppercase in text > 20 chars)
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

  // 3. Repeated character spam (10+ consecutive same char)
  if (/(.)\1{9,}/.test(normalized)) {
    return { allowed: false, reason: "spam_detected" };
  }

  // 4. Excessive URL count (>3 URLs = spam)
  const urlCount = (normalized.match(/https?:\/\//g) || []).length;
  if (urlCount > 3) {
    return { allowed: false, reason: "spam_detected" };
  }

  return { allowed: true };
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

// Maximum text length to prevent abuse of the moderation endpoint.
const MAX_TEXT_LENGTH = 10000;

serve(async (req: Request) => {
  const cors = getCorsHeaders(req);

  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    // Verify JWT authentication
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ allowed: false, reason: "unauthorized" }),
        { status: 401, headers: { ...cors, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: { headers: { Authorization: authHeader } },
    });

    // Verify the user is authenticated
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(
        JSON.stringify({ allowed: false, reason: "unauthorized" }),
        { status: 401, headers: { ...cors, "Content-Type": "application/json" } }
      );
    }

    // Parse request body
    const { text, type } = await req.json();

    if (!text || typeof text !== "string") {
      return new Response(
        JSON.stringify({ allowed: true }),
        { headers: { ...cors, "Content-Type": "application/json" } }
      );
    }

    // Enforce text length limit to prevent abuse
    if (text.length > MAX_TEXT_LENGTH) {
      return new Response(
        JSON.stringify({ allowed: false, reason: "content_too_long" }),
        { status: 400, headers: { ...cors, "Content-Type": "application/json" } }
      );
    }

    // Run moderation
    const result = moderateText(text);

    // Log violations for admin review
    if (!result.allowed) {
      console.log(
        `[moderate-content] Rejected: user=${user.id}, reason=${result.reason}, type=${type ?? "text"}`
      );
    }

    return new Response(JSON.stringify(result), {
      headers: { ...cors, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("[moderate-content] Error:", error);
    const cors = getCorsHeaders(req);
    // Fail-open: allow but flag for manual review
    return new Response(
      JSON.stringify({ allowed: true, reason: "error_fallback", needs_review: true }),
      { headers: { ...cors, "Content-Type": "application/json" } }
    );
  }
});
