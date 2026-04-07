// Pure moderation logic — extracted for testability.
// No Deno.serve or request handling here.

export const PROHIBITED_PATTERNS: string[] = [
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

export interface ModerationResult {
  allowed: boolean;
  reason?: string;
}

export const MAX_TEXT_LENGTH = 10000;

export function moderateText(text: string): ModerationResult {
  const normalized = text.toLowerCase();

  for (const pattern of PROHIBITED_PATTERNS) {
    if (normalized.includes(pattern)) {
      return { allowed: false, reason: "content_violation" };
    }
  }

  if (text.length > 20) {
    // Fix: original logic had a flawed ternary that misidentified cased chars.
    // Correct check: char is uppercase AND has a lowercase form (i.e. is a letter).
    const upperCount = [...text].filter(
      (ch) => ch === ch.toUpperCase() && ch !== ch.toLowerCase()
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
