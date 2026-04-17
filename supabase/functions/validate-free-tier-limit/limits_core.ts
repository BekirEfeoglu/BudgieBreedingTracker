// Pure free-tier limit policy — extracted for unit testing.
// Server-side is the source of truth; client-side limits are a UX hint only.

export const LIMITS: Record<string, number> = {
  birds: 15,
  breeding_pairs: 5,
  incubations: 3,
  marketplace_listings: 3,
};

export const ALLOWED_TABLES = new Set(Object.keys(LIMITS));

export interface ProfileSnapshot {
  is_premium?: boolean | null;
  role?: string | null;
}

export function isExemptProfile(profile: ProfileSnapshot | null | undefined): boolean {
  if (!profile) return false;
  if (profile.is_premium) return true;
  return profile.role === "admin" || profile.role === "founder";
}

export function isAllowedTable(table: string): boolean {
  return ALLOWED_TABLES.has(table);
}

export function getLimit(table: string): number | null {
  return Object.prototype.hasOwnProperty.call(LIMITS, table)
    ? LIMITS[table]
    : null;
}

/** Whether to filter out soft-deleted rows when counting. */
export function shouldFilterDeleted(table: string): boolean {
  return table !== "incubations";
}

/**
 * Returns the `status` filter to apply (or null if none).
 * Kept in sync with index.ts — if you add a table, update both.
 */
export function getStatusFilter(table: string): string[] | null {
  if (table === "breeding_pairs") return ["active", "ongoing"];
  if (table === "incubations" || table === "marketplace_listings") {
    return ["active"];
  }
  return null;
}

export function evaluateLimit(
  count: number | null | undefined,
  limit: number,
): { allowed: boolean; count: number; limit: number } {
  const actual = count ?? 0;
  return { allowed: actual < limit, count: actual, limit };
}
