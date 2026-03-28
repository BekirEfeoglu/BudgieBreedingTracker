import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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
FlGridData chartGridData(
  BuildContext context, {
  required double interval,
}) {
  final color = Theme.of(context).colorScheme.outlineVariant;
  return FlGridData(
    show: true,
    horizontalInterval: interval,
    drawVerticalLine: false,
    getDrawingHorizontalLine: (value) => FlLine(
      color: color.withValues(alpha: 0.3),
      strokeWidth: 1,
    ),
  );
}
