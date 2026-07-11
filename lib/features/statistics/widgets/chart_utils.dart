import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Localized short month abbreviation for a monthly-series key's month part
/// (`'YYYY-MM'`, e.g. `'2026-01'` -> `'Oca'` tr / `'Jan'` en), never the raw
/// zero-padded digits (datetime-format.md: locale-aware `DateFormat`, not a
/// literal number).
///
/// Falls back to `tr` (master language, localization.md) when there is no
/// `EasyLocalization` ancestor: `context.locale` force-unwraps
/// `EasyLocalization.of(context)` and throws otherwise, but most widget
/// tests in this repo intentionally mount a plain `MaterialApp` without it
/// (test_support/l10n_lookup.dart) — this must degrade, not crash.
String monthAbbreviation(BuildContext context, String monthKey) {
  final month = int.tryParse(monthKey.split('-').last) ?? 1;
  final locale = EasyLocalization.of(context)?.locale.toString() ?? 'tr';
  return DateFormat.MMM(locale).format(DateTime(2024, month));
}

/// Locale-aware `month year` label for a `'YYYY-MM'` series key
/// (`'2026-01'` -> `'Oca 2026'` tr / `'Jan 2026'` en). Unlike
/// [monthAbbreviation] this keeps the year — use it for a single-point display
/// (e.g. a peak-month highlight) where the year is not implied by a surrounding
/// month series. Returns the raw key on a malformed input rather than crashing.
/// Same `tr` fallback as [monthAbbreviation] when there is no
/// `EasyLocalization` ancestor (widget tests).
String monthYearLabel(BuildContext context, String monthKey) {
  final parts = monthKey.split('-');
  final year = parts.isNotEmpty ? int.tryParse(parts.first) : null;
  final month = parts.length > 1 ? int.tryParse(parts[1]) : null;
  if (year == null || month == null || month < 1 || month > 12) {
    return monthKey;
  }
  final locale = EasyLocalization.of(context)?.locale.toString() ?? 'tr';
  return DateFormat.yMMM(locale).format(DateTime(year, month));
}

/// Returns true when a numeric series has at least one meaningful value.
bool hasPositiveValues(Iterable<num> values) =>
    values.any((value) => value > 0);

/// Calculates a clean Y-axis interval based on the maximum data value.
///
/// Returns an interval that produces 3-6 tick marks on the axis,
/// keeping the chart readable regardless of data magnitude.
double calcChartInterval(double maxValue) {
  if (maxValue <= 5) return 1;
  if (maxValue <= 10) return 2;
  if (maxValue <= 25) return 5;
  if (maxValue <= 50) return 10;
  if (maxValue <= 100) return 25;
  return (maxValue / 5).ceilToDouble();
}

/// Calculates a clean maxY ceiling aligned to the interval.
double calcChartMaxY(double maxValue, double interval) {
  return (maxValue / interval).ceil() * interval + interval;
}

/// Builds light horizontal grid lines at the given interval.
FlGridData chartGridData(BuildContext context, {required double interval}) {
  final color = Theme.of(context).colorScheme.outlineVariant;
  return FlGridData(
    show: true,
    horizontalInterval: interval,
    drawVerticalLine: false,
    getDrawingHorizontalLine: (value) =>
        FlLine(color: color.withValues(alpha: 0.3), strokeWidth: 1),
  );
}
