// Pure revocation helpers — extracted for unit testing.

export const GOOGLE_REVOKE_URL = "https://oauth2.googleapis.com/revoke";
export const APPLE_REVOKE_URL = "https://appleid.apple.com/auth/revoke";

export type Provider = "google" | "apple";

export interface RevokeInput {
  provider: Provider;
  provider_token?: string;
  provider_refresh_token?: string;
}

/** Returns the token that should be sent to the provider. */
export function pickToken(input: RevokeInput): string | null {
  return input.provider_token ?? input.provider_refresh_token ?? null;
}

/** Whether the picked token is a refresh token (Apple requires the hint). */
export function isRefreshToken(input: RevokeInput): boolean {
  return !input.provider_token && !!input.provider_refresh_token;
}

export function googleRevokeBody(token: string): string {
  return `token=${encodeURIComponent(token)}`;
}

export function appleRevokeParams(
  token: string,
  clientId: string,
  clientSecret: string,
  refresh: boolean,
): URLSearchParams {
  return new URLSearchParams({
    client_id: clientId,
    client_secret: clientSecret,
    token,
    token_type_hint: refresh ? "refresh_token" : "access_token",
  });
}
