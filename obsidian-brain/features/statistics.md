# Feature: statistics

**Purpose**: Breeding performance analytics — charts, hatch rates, success metrics.

## Key Screens

- Statistics dashboard
- Individual metric detail views
- Date range selector

## Key Providers

- Statistics providers use `.select()` to narrow rebuild scope (HomeScreen audit 2026-04-19)
- `StreamProvider` or `FutureProvider` depending on data freshness requirements

## Charts

Uses `fl_chart ^1.2.0`. Chart types: line, bar, pie.

## Data Sources

Aggregates from multiple Drift DAOs (birds, eggs, chicks, breeding pairs). Heavy Drift queries should be profiled with `Stopwatch` + `AppLogger.debug('perf', ...)`.

## Rules

- `.claude/rules/performance.md` — Drift query budgets (p50 < 20ms, p99 < 50ms)
- `.claude/rules/providers.md` — `ref.watch().select(...)` to minimize rebuilds

## See Also

- [[features/home]]
- [[features/_features-index]]
