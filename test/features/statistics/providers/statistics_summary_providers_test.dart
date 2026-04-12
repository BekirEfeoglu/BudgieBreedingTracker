import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';

void main() {
  group('SummaryStats', () {
    test('default values are zero', () {
      const stats = SummaryStats();
      expect(stats.totalBirds, 0);
      expect(stats.activeBreedings, 0);
      expect(stats.incubatingEggs, 0);
      expect(stats.fertilityRate, 0.0);
      expect(stats.chickSurvivalRate, 0.0);
      expect(stats.totalHealthRecords, 0);
    });

    test('copyWith updates fields', () {
      const stats = SummaryStats();
      final updated = stats.copyWith(
        totalBirds: 10,
        activeBreedings: 3,
        fertilityRate: 0.75,
        chickSurvivalRate: 0.9,
      );
      expect(updated.totalBirds, 10);
      expect(updated.activeBreedings, 3);
      expect(updated.fertilityRate, 0.75);
      expect(updated.chickSurvivalRate, 0.9);
      expect(updated.incubatingEggs, 0);
    });

    test('fromJson creates instance correctly', () {
      final json = {
        'total_birds': 5,
        'active_breedings': 2,
        'incubating_eggs': 3,
        'fertility_rate': 0.8,
        'chick_survival_rate': 0.95,
        'total_health_records': 10,
      };
      final stats = SummaryStats.fromJson(json);
      expect(stats.totalBirds, 5);
      expect(stats.activeBreedings, 2);
      expect(stats.incubatingEggs, 3);
      expect(stats.fertilityRate, 0.8);
      expect(stats.chickSurvivalRate, 0.95);
      expect(stats.totalHealthRecords, 10);
    });

    test('toJson produces snake_case keys', () {
      const stats = SummaryStats(totalBirds: 7, fertilityRate: 0.5);
      final json = stats.toJson();
      expect(json['total_birds'], 7);
      expect(json['fertility_rate'], 0.5);
    });
  });

  group('DashboardStats', () {
    test('default values', () {
      const stats = DashboardStats();
      expect(stats.totalBirds, 0);
      expect(stats.totalEggs, 0);
      expect(stats.totalChicks, 0);
      expect(stats.activeBreedings, 0);
      expect(stats.incubatingEggs, 0);
      expect(stats.recentHatches, 0);
    });

    test('fromJson/toJson roundtrip', () {
      const stats = DashboardStats(totalBirds: 15, activeBreedings: 4);
      final json = stats.toJson();
      final restored = DashboardStats.fromJson(json);
      expect(restored.totalBirds, 15);
      expect(restored.activeBreedings, 4);
    });
  });

  group('BirdStatistics', () {
    test('default values', () {
      const stats = BirdStatistics();
      expect(stats.total, 0);
      expect(stats.male, 0);
      expect(stats.female, 0);
      expect(stats.alive, 0);
    });

    test('copyWith updates fields', () {
      const stats = BirdStatistics();
      final updated = stats.copyWith(total: 20, male: 10, female: 10);
      expect(updated.total, 20);
      expect(updated.male, 10);
      expect(updated.female, 10);
    });
  });

}
