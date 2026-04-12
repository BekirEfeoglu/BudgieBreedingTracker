import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';

void main() {
  group('ChickSurvivalData', () {
    test('default values are zero', () {
      const data = ChickSurvivalData();
      expect(data.healthy, 0);
      expect(data.sick, 0);
      expect(data.deceased, 0);
      expect(data.survivalRate, 0.0);
    });

    test('accepts custom values', () {
      const data = ChickSurvivalData(
        healthy: 8,
        sick: 1,
        deceased: 1,
        survivalRate: 0.9,
      );
      expect(data.healthy, 8);
      expect(data.sick, 1);
      expect(data.deceased, 1);
      expect(data.survivalRate, 0.9);
    });

    test('copyWith updates fields', () {
      const data = ChickSurvivalData(healthy: 5);
      final updated = data.copyWith(sick: 2, survivalRate: 0.7);
      expect(updated.healthy, 5);
      expect(updated.sick, 2);
      expect(updated.survivalRate, 0.7);
    });

    test('fromJson creates instance', () {
      final json = {
        'healthy': 10,
        'sick': 2,
        'deceased': 1,
        'survival_rate': 0.92,
      };
      final data = ChickSurvivalData.fromJson(json);
      expect(data.healthy, 10);
      expect(data.sick, 2);
      expect(data.deceased, 1);
      expect(data.survivalRate, 0.92);
    });

    test('toJson produces snake_case keys', () {
      const data = ChickSurvivalData(healthy: 5, survivalRate: 0.8);
      final json = data.toJson();
      expect(json['healthy'], 5);
      expect(json['survival_rate'], 0.8);
    });
  });

  group('IncubationDurationData', () {
    test('construction with required fields', () {
      const data = IncubationDurationData(id: 'inc1', actualDays: 19);
      expect(data.id, 'inc1');
      expect(data.actualDays, 19);
      expect(data.expectedDays, 18);
    });

    test('default expectedDays is 18', () {
      const data = IncubationDurationData(id: 'inc1', actualDays: 17);
      expect(data.expectedDays, 18);
    });

    test('custom expectedDays', () {
      const data = IncubationDurationData(
        id: 'inc1',
        actualDays: 20,
        expectedDays: 21,
      );
      expect(data.expectedDays, 21);
    });

    test('fromJson/toJson roundtrip', () {
      const data = IncubationDurationData(id: 'x', actualDays: 18);
      final json = data.toJson();
      final restored = IncubationDurationData.fromJson(json);
      expect(restored.id, 'x');
      expect(restored.actualDays, 18);
      expect(restored.expectedDays, 18);
    });
  });
}
