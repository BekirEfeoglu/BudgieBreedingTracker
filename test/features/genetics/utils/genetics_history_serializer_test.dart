import 'dart:convert';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/genetics_history_serializer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseHistoryResults', () {
    test('returns empty list for invalid JSON', () {
      expect(parseHistoryResults('not-json'), isEmpty);
    });

    test('returns empty list for non-list JSON', () {
      expect(parseHistoryResults('{"key":"value"}'), isEmpty);
    });

    test('returns empty list for empty array', () {
      expect(parseHistoryResults('[]'), isEmpty);
    });

    test('parses minimal offspring result', () {
      final json = jsonEncode([
        {
          'phenotype': 'Light Green',
          'probability': 0.25,
          'sex': 'both',
        },
      ]);

      final results = parseHistoryResults(json);

      expect(results, hasLength(1));
      expect(results.first.phenotype, 'Light Green');
      expect(results.first.probability, 0.25);
      expect(results.first.sex, OffspringSex.both);
      expect(results.first.isCarrier, isFalse);
    });

    test('parses offspring with all fields populated', () {
      final json = jsonEncode([
        {
          'phenotype': 'Cobalt Opaline',
          'probability': 0.125,
          'genotype': 'bl/bl op/op D+/D',
          'sex': 'female',
          'isCarrier': true,
          'compoundPhenotype': 'Cobalt Opaline',
          'visualMutations': ['blue', 'opaline', 'dark_factor'],
          'carriedMutations': ['violet'],
          'maskedMutations': [],
          'lethalCombinationIds': ['ino_x_ino'],
          'doubleFactorIds': ['blue'],
        },
      ]);

      final results = parseHistoryResults(json);

      expect(results, hasLength(1));
      final r = results.first;
      expect(r.phenotype, 'Cobalt Opaline');
      expect(r.probability, 0.125);
      expect(r.genotype, 'bl/bl op/op D+/D');
      expect(r.sex, OffspringSex.female);
      expect(r.isCarrier, isTrue);
      expect(r.compoundPhenotype, 'Cobalt Opaline');
      expect(r.visualMutations, ['blue', 'opaline', 'dark_factor']);
      expect(r.carriedMutations, ['violet']);
      expect(r.maskedMutations, isEmpty);
      expect(r.lethalCombinationIds, ['ino_x_ino']);
      expect(r.doubleFactorIds, {'blue'});
    });

    test('parses male sex correctly', () {
      final json = jsonEncode([
        {'phenotype': 'Ino', 'probability': 0.5, 'sex': 'male'},
      ]);

      final results = parseHistoryResults(json);
      expect(results.first.sex, OffspringSex.male);
    });

    test('defaults to both for unknown sex value', () {
      final json = jsonEncode([
        {'phenotype': 'Normal', 'probability': 1.0, 'sex': 'unknown'},
      ]);

      final results = parseHistoryResults(json);
      expect(results.first.sex, OffspringSex.both);
    });

    test('handles legacy carrier suffix in phenotype', () {
      final json = jsonEncode([
        {'phenotype': 'Light Green (carrier)', 'probability': 0.5},
      ]);

      final results = parseHistoryResults(json);
      expect(results.first.isCarrier, isTrue);
    });

    test('skips non-map entries in array', () {
      final json = jsonEncode([
        'invalid',
        {'phenotype': 'Blue', 'probability': 0.5},
        42,
      ]);

      final results = parseHistoryResults(json);
      expect(results, hasLength(1));
      expect(results.first.phenotype, 'Blue');
    });

    test('handles missing optional fields gracefully', () {
      final json = jsonEncode([
        {'phenotype': 'Normal'},
      ]);

      final results = parseHistoryResults(json);
      expect(results, hasLength(1));
      expect(results.first.probability, 0.0);
      expect(results.first.genotype, isNull);
      expect(results.first.visualMutations, isEmpty);
      expect(results.first.carriedMutations, isEmpty);
    });
  });

  group('parseStoredGenotype', () {
    test('parses visual state', () {
      final genotype = parseStoredGenotype(
        {'blue': 'visual'},
        BirdGender.male,
      );

      expect(genotype.mutations['blue'], AlleleState.visual);
      expect(genotype.gender, BirdGender.male);
    });

    test('parses carrier state', () {
      final genotype = parseStoredGenotype(
        {'blue': 'carrier'},
        BirdGender.female,
      );

      expect(genotype.mutations['blue'], AlleleState.carrier);
    });

    test('parses split state', () {
      final genotype = parseStoredGenotype(
        {'opaline': 'split'},
        BirdGender.male,
      );

      expect(genotype.mutations['opaline'], AlleleState.split);
    });

    test('defaults unknown state to visual', () {
      final genotype = parseStoredGenotype(
        {'blue': 'gibberish'},
        BirdGender.male,
      );

      expect(genotype.mutations['blue'], AlleleState.visual);
    });

    test('resolves legacy mutation IDs', () {
      final genotype = parseStoredGenotype(
        {'lutino': 'visual'},
        BirdGender.female,
      );

      // lutino should be resolved to ino
      expect(genotype.mutations.containsKey('ino'), isTrue);
      expect(genotype.mutations['ino'], AlleleState.visual);
    });

    test('resolves legacy albino to ino', () {
      final genotype = parseStoredGenotype(
        {'albino': 'visual'},
        BirdGender.male,
      );

      expect(genotype.mutations.containsKey('ino'), isTrue);
    });

    test('handles empty stored map', () {
      final genotype = parseStoredGenotype({}, BirdGender.male);

      expect(genotype.mutations, isEmpty);
      expect(genotype.gender, BirdGender.male);
    });

    test('handles multiple mutations', () {
      final genotype = parseStoredGenotype(
        {
          'blue': 'visual',
          'opaline': 'carrier',
          'dark_factor': 'visual',
        },
        BirdGender.male,
      );

      expect(genotype.mutations, hasLength(3));
      expect(genotype.mutations['blue'], AlleleState.visual);
      expect(genotype.mutations['opaline'], AlleleState.carrier);
      expect(genotype.mutations['dark_factor'], AlleleState.visual);
    });
  });
}
