import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  aggregateStatus,
  buildHealthSnapshot,
} from "./health_core.ts";

Deno.test("aggregateStatus returns ok when all checks ok", () => {
  assertEquals(
    aggregateStatus({ database: "ok", auth: "ok", storage: "ok" }),
    "ok",
  );
});

Deno.test("aggregateStatus returns degraded if any check is degraded", () => {
  assertEquals(
    aggregateStatus({ database: "ok", auth: "degraded", storage: "ok" }),
    "degraded",
  );
});

Deno.test("aggregateStatus returns degraded on empty input", () => {
  assertEquals(aggregateStatus({}), "degraded");
});

Deno.test("buildHealthSnapshot preserves inputs and sets status", () => {
  const snap = buildHealthSnapshot(
    { database: "ok", auth: "ok", storage: "ok" },
    { database_ms: 10, auth_ms: 20, storage_ms: 30, total_ms: 60 },
    "2026-04-17T12:00:00Z",
  );
  assertEquals(snap.status, "ok");
  assertEquals(snap.latency.total_ms, 60);
  assertEquals(snap.timestamp, "2026-04-17T12:00:00Z");
});

Deno.test("buildHealthSnapshot marks degraded on any failing check", () => {
  const snap = buildHealthSnapshot(
    { database: "degraded", auth: "ok", storage: "ok" },
    { database_ms: 500, auth_ms: 20, storage_ms: 30, total_ms: 550 },
    "2026-04-17T12:00:00Z",
  );
  assertEquals(snap.status, "degraded");
});
