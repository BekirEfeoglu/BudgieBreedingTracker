// Pure lockout state logic extracted from index.ts so it can be unit-tested
// without booting Deno.serve or a Supabase client.

export const MAX_ATTEMPTS = 5;

export const LOCKOUT_TIERS = [
  120,   // 1st lockout: 2 minutes
  300,   // 2nd lockout: 5 minutes
  900,   // 3rd lockout: 15 minutes
  3600,  // 4th+ lockout: 1 hour
];

export const LOCKOUT_DECAY_HOURS = 7 * 24; // 7 days

export interface LockoutRow {
  user_id: string;
  failed_attempts: number | null;
  locked_until: string | null;
  last_attempt_at: string | null;
  lockout_count: number | null;
}

export function isLockedOut(
  lockout: Pick<LockoutRow, "locked_until"> | null | undefined,
  now: Date = new Date(),
): { locked: boolean; remaining_seconds: number } {
  if (!lockout?.locked_until) return { locked: false, remaining_seconds: 0 };
  const lockedUntil = new Date(lockout.locked_until);
  if (now < lockedUntil) {
    const remaining = Math.ceil((lockedUntil.getTime() - now.getTime()) / 1000);
    return { locked: true, remaining_seconds: remaining };
  }
  return { locked: false, remaining_seconds: 0 };
}

export function getLockoutDuration(lockoutCount: number): number {
  const tierIndex = Math.min(
    Math.max(0, lockoutCount),
    LOCKOUT_TIERS.length - 1,
  );
  return LOCKOUT_TIERS[tierIndex];
}

export interface FailureOutcome {
  locked: boolean;
  remaining_seconds: number;
  failed_attempts: number;
  lockout_count: number;
  locked_until: string | null;
}

export function computeFailureUpdate(
  lockout: LockoutRow,
  now: Date = new Date(),
): FailureOutcome {
  const expiredPriorLockout = lockout.locked_until &&
    new Date(lockout.locked_until) <= now;
  const baseAttempts = expiredPriorLockout ? 0 : (lockout.failed_attempts ?? 0);
  const newAttempts = baseAttempts + 1;
  const currentLockoutCount = lockout.lockout_count ?? 0;

  if (newAttempts >= MAX_ATTEMPTS) {
    const duration = getLockoutDuration(currentLockoutCount);
    const lockedUntil = new Date(now.getTime() + duration * 1000);
    return {
      locked: true,
      remaining_seconds: duration,
      failed_attempts: newAttempts,
      lockout_count: currentLockoutCount + 1,
      locked_until: lockedUntil.toISOString(),
    };
  }

  return {
    locked: false,
    remaining_seconds: 0,
    failed_attempts: newAttempts,
    lockout_count: currentLockoutCount,
    locked_until: lockout.locked_until,
  };
}

export function computeResetCount(
  lockout: Pick<LockoutRow, "lockout_count" | "last_attempt_at"> | null,
  now: Date = new Date(),
): number {
  const lastAttempt = lockout?.last_attempt_at
    ? new Date(lockout.last_attempt_at)
    : now;
  const hoursSinceLastAttempt =
    (now.getTime() - lastAttempt.getTime()) / (1000 * 3600);
  const currentCount = lockout?.lockout_count ?? 0;
  return hoursSinceLastAttempt > LOCKOUT_DECAY_HOURS
    ? Math.max(0, currentCount - 1)
    : currentCount;
}
