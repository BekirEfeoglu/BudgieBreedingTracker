import 'package:freezed_annotation/freezed_annotation.dart';

part 'statistics_models.freezed.dart';
part 'statistics_models.g.dart';

@freezed
abstract class DashboardStats with _$DashboardStats {
  const DashboardStats._(); // ignore: unused_element
  const factory DashboardStats({
    @Default(0) int totalBirds,
    @Default(0) int totalEggs,
    @Default(0) int totalChicks,
    @Default(0) int activeBreedings,
    @Default(0) int incubatingEggs,
    @Default(0) int recentHatches,
  }) = _DashboardStats;

  factory DashboardStats.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsFromJson(json);
}

@freezed
abstract class BirdStatistics with _$BirdStatistics {
  const BirdStatistics._(); // ignore: unused_element
  const factory BirdStatistics({
    @Default(0) int total,
    @Default(0) int male,
    @Default(0) int female,
    @Default(0) int unknown,
    @Default(0) int alive,
    @Default(0) int dead,
    @Default(0) int sold,
    @Default(0) int breedingPairs,
  }) = _BirdStatistics;

  factory BirdStatistics.fromJson(Map<String, dynamic> json) =>
      _$BirdStatisticsFromJson(json);
}

@freezed
abstract class SummaryStats with _$SummaryStats {
  const SummaryStats._();
  const factory SummaryStats({
    @Default(0) int totalBirds,
    @Default(0) int activeBreedings,
    @Default(0) int incubatingEggs,
    @Default(0.0) double fertilityRate,
    @Default(0.0) double chickSurvivalRate,
    @Default(0) int totalHealthRecords,
  }) = _SummaryStats;

  factory SummaryStats.fromJson(Map<String, dynamic> json) =>
      _$SummaryStatsFromJson(json);
}

@freezed
abstract class IncubationDurationData with _$IncubationDurationData {
  const IncubationDurationData._();
  const factory IncubationDurationData({
    required String id,
    required int actualDays,
    @Default(18) int expectedDays,
  }) = _IncubationDurationData;

  factory IncubationDurationData.fromJson(Map<String, dynamic> json) =>
      _$IncubationDurationDataFromJson(json);
}

@freezed
abstract class ChickSurvivalData with _$ChickSurvivalData {
  const ChickSurvivalData._();
  const factory ChickSurvivalData({
    @Default(0) int healthy,
    @Default(0) int sick,
    @Default(0) int deceased,
    @Default(0.0) double survivalRate,
  }) = _ChickSurvivalData;

  factory ChickSurvivalData.fromJson(Map<String, dynamic> json) =>
      _$ChickSurvivalDataFromJson(json);
}

/// Trend comparison data: current period vs previous period.
class TrendStats {
  const TrendStats({
    this.birdsTrend = 0,
    this.breedingsTrend = 0,
    this.eggsTrend = 0,
    this.fertilityTrend = 0,
    this.survivalTrend = 0,
  });

  /// Percent change in total birds vs previous period.
  final double birdsTrend;

  /// Percent change in active breedings.
  final double breedingsTrend;

  /// Percent change in egg production.
  final double eggsTrend;

  /// Percent point change in fertility rate.
  final double fertilityTrend;

  /// Percent point change in survival rate.
  final double survivalTrend;
}

/// Sentiment type for quick insight items.
enum InsightSentiment { positive, negative, neutral }

/// A single quick insight text with icon and sentiment.
class QuickInsight {
  const QuickInsight({required this.text, required this.sentiment});

  final String text;
  final InsightSentiment sentiment;
}
