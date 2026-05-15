# Feature: statistics

**Purpose**: Breeding performance analytics — charts, hatch rates, success metrics.

## Key Screens

- Statistics dashboard
- Individual metric detail views
- Date range selector

## Key Providers

- Statistics providers use `.select()` to narrow rebuild scope (HomeScreen audit 2026-04-19)
- `StreamProvider` or `FutureProvider` depending on data freshness requirements
- `personalRecordsProvider(userId)` — computes best breeding season, most productive pair, and longest-lived bird.
- `seasonComparisonProvider(userId)` — compares the two latest egg seasons by egg count, fertility rate, hatched chicks, and live chicks.
- `healthTrendSummaryProvider(userId)` — summarizes busiest health month, most visited bird, and average treatment/follow-up duration.
- `clutchesStreamProvider(userId)` — local Drift clutch feed used by personal record calculations.

## Charts

Uses `fl_chart ^1.2.0`. Chart types: line, bar, pie.

## Highlight Cards

- Overview tab shows `PersonalRecordsCard` after quick insights.
- Breeding tab shows `SeasonComparisonCard` near the top, scoped to the latest two seasons found from egg dates.
- Health tab shows `HealthTrendSummaryCard` before the monthly trend chart.
- Cards use localized empty states and should stay read-only analytics; writes belong in the source feature flows.

## Export

- `StatisticsScreen` has a PDF share action in the app bar.
- `PdfExportService.generateStatisticsReport(...)` exports personal records, season comparison, and health trend summary as a compact report.
- The screen reads existing highlight providers and shares an in-memory `application/pdf` via `share_plus`; export failures are logged with `AppLogger` and surfaced through localized snackbars.

## Data Sources

Aggregates from multiple Drift DAOs (birds, eggs, chicks, breeding pairs). Heavy Drift queries should be profiled with `Stopwatch` + `AppLogger.debug('perf', ...)`.

## Rules

- `.claude/rules/performance.md` — Drift query budgets (p50 < 20ms, p99 < 50ms)
- `.claude/rules/providers.md` — `ref.watch().select(...)` to minimize rebuilds

## See Also

- [[features/home]]
- [[features/_features-index]]
