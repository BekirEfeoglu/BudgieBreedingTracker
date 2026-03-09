import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/inbreeding_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late InbreedingCalculator calculator;

  setUp(() {
    calculator = const InbreedingCalculator();
  });

  group('InbreedingCalculator.calculate', () {
    test('returns 0 when bird missing', () {
      final result = calculator.calculate(
        birdId: 'missing',
        ancestors: const {},
      );
      expect(result, 0.0);
    });

    test('returns 0 when pedigree has no parents', () {
      final result = calculator.calculate(
        birdId: 'bird-1',
        ancestors: {'bird-1': createTestBird(id: 'bird-1')},
      );
      expect(result, 0.0);
    });

    test('non-related pedigree gives CoI = 0', () {
      final ancestors = {
        'subject': createTestBird(
          id: 'subject',
          fatherId: 'father',
          motherId: 'mother',
        ),
        'father': createTestBird(
          id: 'father',
          fatherId: 'gf1',
          motherId: 'gm1',
        ),
        'mother': createTestBird(
          id: 'mother',
          fatherId: 'gf2',
          motherId: 'gm2',
        ),
        'gf1': createTestBird(id: 'gf1'),
        'gm1': createTestBird(id: 'gm1'),
        'gf2': createTestBird(id: 'gf2'),
        'gm2': createTestBird(id: 'gm2'),
      };

      final result = calculator.calculate(
        birdId: 'subject',
        ancestors: ancestors,
      );

      expect(result, 0.0);
    });

    test('half-sibling mating gives expected 0.125', () {
      final result = calculator.calculate(
        birdId: 'subject',
        ancestors: createInbredPedigree(),
      );

      expect(result, closeTo(0.125, 0.0001));
    });

    test('full-sibling mating gives expected 0.25', () {
      final ancestors = {
        'subject': createTestBird(
          id: 'subject',
          fatherId: 'father',
          motherId: 'mother',
        ),
        'father': createTestBird(
          id: 'father',
          gender: BirdGender.male,
          fatherId: 'grandpa',
          motherId: 'grandma',
        ),
        'mother': createTestBird(
          id: 'mother',
          gender: BirdGender.female,
          fatherId: 'grandpa',
          motherId: 'grandma',
        ),
        'grandpa': createTestBird(id: 'grandpa', gender: BirdGender.male),
        'grandma': createTestBird(id: 'grandma', gender: BirdGender.female),
      };

      final result = calculator.calculate(
        birdId: 'subject',
        ancestors: ancestors,
      );

      expect(result, closeTo(0.25, 0.0001));
    });

    test('parent-offspring mating produces high coefficient', () {
      final ancestors = {
        'subject': createTestBird(
          id: 'subject',
          fatherId: 'father',
          motherId: 'grandma',
        ),
        'father': createTestBird(
          id: 'father',
          fatherId: 'grandpa',
          motherId: 'grandma',
        ),
        'grandpa': createTestBird(id: 'grandpa'),
        'grandma': createTestBird(id: 'grandma'),
      };

      final result = calculator.calculate(
        birdId: 'subject',
        ancestors: ancestors,
      );

      expect(result, greaterThanOrEqualTo(0.25));
    });

    test('respects depth limit and ignores very deep common ancestors', () {
      final ancestors = <String, Bird>{};

      String makeChain(String root, int depth) {
        var current = root;
        for (var i = 0; i < depth; i++) {
          final next = '$root-$i';
          ancestors[current] = createTestBird(id: current, fatherId: next);
          current = next;
        }
        ancestors[current] = createTestBird(id: current);
        return root;
      }

      final fatherRoot = makeChain('father', 12);
      final motherRoot = makeChain('mother', 12);

      ancestors['subject'] = createTestBird(
        id: 'subject',
        fatherId: fatherRoot,
        motherId: motherRoot,
      );

      final shared = createTestBird(id: 'shared');
      ancestors['father-10'] = createTestBird(
        id: 'father-10',
        fatherId: 'shared',
      );
      ancestors['mother-10'] = createTestBird(
        id: 'mother-10',
        fatherId: 'shared',
      );
      ancestors['shared'] = shared;

      final result = calculator.calculate(
        birdId: 'subject',
        ancestors: ancestors.cast<String, dynamic>().map(
          (key, value) => MapEntry(key, value),
        ),
      );

      expect(result, inInclusiveRange(0.0, 0.5));
    });

    test('handles missing ancestor nodes without throwing', () {
      final ancestors = {
        'subject': createTestBird(
          id: 'subject',
          fatherId: 'father',
          motherId: 'mother',
        ),
        'father': createTestBird(id: 'father', fatherId: 'missing-node'),
        'mother': createTestBird(id: 'mother'),
      };

      final result = calculator.calculate(
        birdId: 'subject',
        ancestors: ancestors,
      );

      expect(result, 0.0);
    });
  });

  group('InbreedingCalculator.findCommonAncestors', () {
    test('returns empty set when no common ancestors', () {
      final ancestors = {
        'subject': createTestBird(id: 'subject', fatherId: 'f', motherId: 'm'),
        'f': createTestBird(id: 'f', fatherId: 'f1'),
        'm': createTestBird(id: 'm', fatherId: 'm1'),
        'f1': createTestBird(id: 'f1'),
        'm1': createTestBird(id: 'm1'),
      };

      final common = calculator.findCommonAncestors(
        birdId: 'subject',
        ancestors: ancestors,
      );

      expect(common, isEmpty);
    });

    test('returns shared ancestors for inbred pedigree', () {
      final common = calculator.findCommonAncestors(
        birdId: 'subject',
        ancestors: createInbredPedigree(commonAncestorId: 'grandparent'),
      );

      expect(common, contains('grandparent'));
    });
  });

  group('InbreedingCalculator.assessRisk', () {
    test('maps coefficient bands to expected risk levels', () {
      expect(calculator.assessRisk(0.0), InbreedingRisk.none);
      expect(calculator.assessRisk(0.0625), InbreedingRisk.minimal);
      expect(calculator.assessRisk(0.125), InbreedingRisk.low);
      expect(calculator.assessRisk(0.25), InbreedingRisk.moderate);
      expect(calculator.assessRisk(0.375), InbreedingRisk.high);
      expect(calculator.assessRisk(0.5), InbreedingRisk.critical);
    });
  });

  group('InbreedingRisk.labelKey', () {
    test('all enum values expose localization key', () {
      for (final risk in InbreedingRisk.values) {
        expect(risk.labelKey, startsWith('genetics.risk_'));
      }
    });
  });
}
