import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/reverse_calculator.dart';

void main() {
  const calculator = ReverseCalculator();

  group('ReverseCalculator - helpers integration', () {
    test('single autosomal recessive target produces parent pairs', () {
      final results = calculator.calculateParents({'blue'});
      expect(results, isNotEmpty);
      for (final r in results) {
        expect(r.father.gender, BirdGender.male);
        expect(r.mother.gender, BirdGender.female);
      }
    });

    test('single sex-linked target produces sex-specific results', () {
      final results = calculator.calculateParents({'ino'});
      expect(results, isNotEmpty);
      expect(results.any((r) => (r.probabilityMale - r.probabilityFemale).abs() > 0.001), isTrue);
    });

    test('empty target set returns empty results', () {
      expect(calculator.calculateParents(const {}), isEmpty);
    });

    test('invalid mutation ID returns empty results', () {
      expect(calculator.calculateParents({'nonexistent_xyz_999'}), isEmpty);
    });

    test('multiple targets at same locus', () {
      final results = calculator.calculateParents({'greywing', 'clearwing'});
      for (final r in results) {
        expect(r.probabilityMale, greaterThanOrEqualTo(0.0));
      }
    });

    test('multiple targets at different loci', () {
      final results = calculator.calculateParents({'blue', 'cinnamon'});
      expect(results, isNotEmpty);
      for (final r in results) {
        expect(r.probabilityAny, inInclusiveRange(0.0, 1.0));
      }
    });

    test('results contain valid ParentGenotype objects', () {
      final results = calculator.calculateParents({'blue'});
      expect(results, isNotEmpty);
      for (final r in results) {
        expect(r.father, isA<ParentGenotype>());
        expect(r.mother, isA<ParentGenotype>());
      }
    });

    test('results probability is between 0 and 1', () {
      final results = calculator.calculateParents({'blue', 'opaline'});
      expect(results, isNotEmpty);
      for (final r in results) {
        expect(r.probabilityMale, inInclusiveRange(0.0, 1.0));
        expect(r.probabilityFemale, inInclusiveRange(0.0, 1.0));
      }
    });

    test('deduplication: no identical father+mother pairs', () {
      final results = calculator.calculateParents({'blue'});
      expect(results, isNotEmpty);
      final sigs = <String>{};
      for (final r in results) {
        final s = _sig(r);
        expect(sigs.add(s), isTrue, reason: 'Duplicate: $s');
      }
    });

    test('result count does not exceed max limit', () {
      expect(calculator.calculateParents({'blue', 'ino'}).length, lessThanOrEqualTo(25));
    });
  });

  group('ReverseCalculatorHelpers.canPossiblyProduceTargets', () {
    test('returns true when parent has target', () {
      expect(
        ReverseCalculatorHelpers.canPossiblyProduceTargets(
          {'blue': AlleleState.carrier}, {'blue': AlleleState.visual}, ['blue'],
        ),
        isTrue,
      );
    });

    test('returns false when neither parent has target', () {
      expect(
        ReverseCalculatorHelpers.canPossiblyProduceTargets(
          {'opaline': AlleleState.visual}, {'cinnamon': AlleleState.visual}, ['blue'],
        ),
        isFalse,
      );
    });
  });

  group('ReverseCalculatorHelpers.dedupeAndTrim', () {
    test('trims to limit', () {
      final items = List.generate(10, (i) => ReverseCalculationResult(
        father: ParentGenotype(gender: BirdGender.male, mutations: {'m$i': AlleleState.visual}),
        mother: const ParentGenotype.empty(gender: BirdGender.female),
        probabilityMale: (10 - i) / 10, probabilityFemale: (10 - i) / 10,
      ));
      expect(ReverseCalculatorHelpers.dedupeAndTrim(items, limit: 3).length, 3);
    });

    test('returns empty for empty input', () {
      expect(ReverseCalculatorHelpers.dedupeAndTrim([], limit: 10), isEmpty);
    });
  });
}

String _sig(ReverseCalculationResult r) {
  String e(Map<String, AlleleState> m) {
    final l = m.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return l.map((x) => '${x.key}:${x.value.name}').join('|');
  }
  return '${e(r.father.mutations)}#${e(r.mother.mutations)}';
}
