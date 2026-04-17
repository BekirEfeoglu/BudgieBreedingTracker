// Pure health-check aggregation — extracted for unit testing.

export type CheckStatus = "ok" | "degraded";

export interface Latency {
  database_ms: number;
  auth_ms: number;
  storage_ms: number;
  total_ms: number;
}

export interface HealthSnapshot {
  status: CheckStatus;
  checks: Record<string, CheckStatus>;
  latency: Latency;
  timestamp: string;
}

export function aggregateStatus(
  checks: Record<string, CheckStatus>,
): CheckStatus {
  const values = Object.values(checks);
  if (values.length === 0) return "degraded";
  return values.every((v) => v === "ok") ? "ok" : "degraded";
}

export function buildHealthSnapshot(
  checks: Record<string, CheckStatus>,
  latency: Latency,
  timestamp: string,
): HealthSnapshot {
  return {
    status: aggregateStatus(checks),
    checks,
    latency,
    timestamp,
  };
}
