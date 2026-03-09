import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/reverse_calculator.dart';

void main() {
  const calculator = ReverseCalculator();

  group('ReverseCalculator', () {
    test('returns empty when target mutation set is empty', () {
      final results = calculator.calculateParents(const {});
      expect(results, isEmpty);
    });

    test('keeps probabilityAny aligned with male/female probabilities', () {
      final results = calculator.calculateParents({'blue', 'opaline'});

      expect(results, isNotEmpty);
      for (final result in results) {
        final expectedAny =
            (result.probabilityMale + result.probabilityFemale) / 2;
        expect(result.probabilityAny, closeTo(expectedAny, 1e-12));
      }
    });

    test('returns sorted and capped combinations', () {
      final results = calculator.calculateParents({'blue', 'ino'});

      expect(results.length, lessThanOrEqualTo(25));
      for (var i = 1; i < results.length; i++) {
        expect(
          results[i - 1].maxProbability,
          greaterThanOrEqualTo(results[i].maxProbability),
        );
      }
    });
  });
}
