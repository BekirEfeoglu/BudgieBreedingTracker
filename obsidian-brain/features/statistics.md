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

SQL-side aggregation is partial, not universal. `chickSurvivalProvider` is
backed by `ChicksDao.watchHealthStatusCounts` (SQL `GROUP BY health_status`,
see [[features/chicks]]) and `healthRecordTypeDistributionProvider` uses
`HealthRecordsDao.watchCountsByTypeInRange` (see [[features/health_records]]).
A 2026-07-01 audit found 10 other providers still materialize full entity
streams and aggregate in Dart instead: `speciesDistributionProvider`,
`colorMutationDistributionProvider`, `ageDistributionProvider`,
`summaryStatsProvider` (partially), `trendStatsProvider`,
`quickInsightsProvider`, `incubationDurationProvider`,
`personalRecordsProvider`, `seasonComparisonProvider`,
`healthTrendSummaryProvider` — not yet fixed.

## Known Issues (2026-07-01 audit)

Comprehensive read-only audit — findings reported, most still open:

- Fixed 2026-07-02: `chickSurvivalProvider`'s `total` had drifted to
  `healthy+sick+deceased` (excluding `unknown`), diverging from
  `summaryStatsProvider`'s `chicks.length`-style total (which always included
  `unknown`) — same underlying data showed two different survival-rate
  percentages. Reverted to include `unknown` in both, and the two providers
  now share one `chickHealthCountsProvider` (`statistics_providers.dart`)
  instead of each opening its own `watchHealthStatusCounts` subscription.
- Fixed 2026-07-02: 4 charts (`breeding_success_chart`, `fertility_trend_chart`,
  `egg_production_chart`, `monthly_trend_chart`) rendered the raw
  zero-padded month digits (`keys[index].split('-')[1]` -> `"01"`..`"12"`)
  instead of a localized month name. New `monthAbbreviation(context, key)`
  helper in `chart_utils.dart` (`DateFormat.MMM(locale)`) used by all 4.
- Fixed 2026-07-11: `HealthTrendSummaryCard`'s "Peak Month" row rendered the
  raw `'YYYY-MM'` key (`2026-01`) as-is. New year-aware
  `monthYearLabel(context, monthKey)` helper in `chart_utils.dart`
  (`DateFormat.yMMM`) — kept separate from `monthAbbreviation` because a single
  peak-month point needs the year (a 12-month period can span two years).
- Verified 2026-07-02, not auto-fixed (needs design input, not a mechanical
  bug fix): chart series colors (`AppColors.success/warning/info` etc.) are
  fixed constants, not `Theme.of(context).colorScheme`-derived — but this is
  the same established pattern used for badges/status colors app-wide, not
  statistics-specific. Computed actual WCAG 1.4.11 contrast (not just
  "unverified" as the prior audit left it): against the light-theme surface
  (`neutral50` `#F8FAFC`) `success`/`warning`/`info` land at ~2.0-2.3:1,
  under the 3:1 non-text minimum — the opposite of the "dark mode" framing,
  it's a **light-theme** contrast gap. `error` passes both themes (3.6:1
  light, 4.7:1 dark). Fixing this app-wide means picking new semantic color
  values (a design decision affecting every `AppColors.success/warning/info`
  consumer, not just charts) — left open pending design review.
- Fixed 2026-07-09: `gender_pie_chart` and `chick_survival_chart` now use the
  documented `< 3` insufficient-data threshold. Zero totals still render
  `ChartEmpty`; totals of 1-2 render `ChartLowData` with a compact table
  instead of a misleading pie chart.
- 6 charts format numbers/percentages without `NumberFormat` — not
  reverified this pass.

## Rules

- `.claude/rules/statistics.md` — fl_chart patterns, Drift-side aggregation, premium gating (export, custom filter, AI insight), accessibility (color-blind palette + tabular alt view)
- `.claude/rules/performance.md` — Drift query budgets (p50 < 20ms, p99 < 50ms)
- `.claude/rules/providers.md` — `ref.watch().select(...)` to minimize rebuilds

## See Also

- [[features/home]]
- [[features/chicks]]
- [[features/health_records]]
- [[features/_features-index]]
