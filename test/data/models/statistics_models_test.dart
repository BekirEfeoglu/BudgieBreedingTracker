import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';

void main() {
  group('statistics models', () {
    test('DashboardStats fromJson/toJson round-trip', () {
      const stats = DashboardStats(
        totalBirds: 10,
        totalEggs: 20,
        totalChicks: 5,
        activeBreedings: 3,
        incubatingEggs: 7,
        recentHatches: 2,
      );

      final restored = DashboardStats.fromJson(stats.toJson());
      expect(restored, stats);
    });

    test('BirdStatistics fromJson/toJson round-trip', () {
      const stats = BirdStatistics(
        total: 10,
        male: 4,
        female: 5,
        unknown: 1,
        alive: 9,
        dead: 1,
        sold: 0,
        breedingPairs: 3,
      );

      final restored = BirdStatistics.fromJson(stats.toJson());
      expect(restored, stats);
    });

    test('EggStatistics fromJson/toJson round-trip', () {
      const stats = EggStatistics(
        total: 50,
        incubating: 12,
        hatched: 20,
        fertile: 25,
        infertile: 5,
        hatchRate: 0.8,
        fertilityRate: 0.83,
      );

      final restored = EggStatistics.fromJson(stats.toJson());
      expect(restored, stats);
    });

    test('ChickStatistics fromJson/toJson round-trip', () {
      const stats = ChickStatistics(
        total: 15,
        thisMonth: 6,
        averageHatchWeight: 3.4,
        survivalRate: 0.9,
      );

      final restored = ChickStatistics.fromJson(stats.toJson());
      expect(restored, stats);
    });

    test('BreedingStatistics fromJson/toJson round-trip', () {
      const stats = BreedingStatistics(
        active: 2,
        completed: 8,
        successRate: 0.75,
        averageCycleLength: 42.0,
      );

      final restored = BreedingStatistics.fromJson(stats.toJson());
      expect(restored, stats);
    });

    test('SummaryStats fromJson/toJson round-trip', () {
      const stats = SummaryStats(
        totalBirds: 100,
        activeBreedings: 7,
        incubatingEggs: 10,
        fertilityRate: 0.81,
        chickSurvivalRate: 0.92,
        totalHealthRecords: 14,
      );

      final restored = SummaryStats.fromJson(stats.toJson());
      expect(restored, stats);
    });

    test('IncubationDurationData fromJson/toJson round-trip', () {
      const data = IncubationDurationData(
        id: 'inc-1',
        actualDays: 19,
        expectedDays: 18,
      );

      final restored = IncubationDurationData.fromJson(data.toJson());
      expect(restored, data);
    });

    test('ChickSurvivalData fromJson/toJson round-trip', () {
      const data = ChickSurvivalData(
        healthy: 20,
        sick: 2,
        deceased: 1,
        survivalRate: 0.91,
      );

      final restored = ChickSurvivalData.fromJson(data.toJson());
      expect(restored, data);
    });

    test('defaults are applied when json is empty', () {
      final dashboard = DashboardStats.fromJson({});
      final birdStats = BirdStatistics.fromJson({});
      final eggStats = EggStatistics.fromJson({});
      final chickStats = ChickStatistics.fromJson({});
      final breedingStats = BreedingStatistics.fromJson({});
      final summaryStats = SummaryStats.fromJson({});
      final chickSurvival = ChickSurvivalData.fromJson({});

      expect(dashboard.totalBirds, 0);
      expect(birdStats.total, 0);
      expect(eggStats.hatchRate, 0.0);
      expect(chickStats.averageHatchWeight, 0.0);
      expect(breedingStats.successRate, 0.0);
      expect(summaryStats.totalHealthRecords, 0);
      expect(chickSurvival.survivalRate, 0.0);
    });
  });

  group('non-freezed statistics helpers', () {
    test('TrendStats has zero defaults', () {
      const trend = TrendStats();

      expect(trend.birdsTrend, 0);
      expect(trend.breedingsTrend, 0);
      expect(trend.eggsTrend, 0);
      expect(trend.fertilityTrend, 0);
      expect(trend.survivalTrend, 0);
    });

    test('QuickInsight stores text and sentiment', () {
      const insight = QuickInsight(
        text: 'Hatch rate increased',
        sentiment: InsightSentiment.positive,
      );

      expect(insight.text, 'Hatch rate increased');
      expect(insight.sentiment, InsightSentiment.positive);
    });
  });
}
