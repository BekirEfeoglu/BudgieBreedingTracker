import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

ParentGenotype _toGenotype(Set<String> ids, BirdGender gender) {
  return ParentGenotype(
    mutations: {for (final id in ids) id: AlleleState.visual},
    gender: gender,
  );
}

void main() {
  const calculator = MendelianCalculator();

  group('Simple inheritance flow (genotype API)', () {
    test('ignores unknown mutation ids and returns empty output', () {
      final results = calculator.calculateFromGenotypes(
        father: _toGenotype({'unknown_mutation'}, BirdGender.male),
        mother: _toGenotype({'another_unknown'}, BirdGender.female),
      );

      expect(results, isEmpty);
    });

    test(
      'incomplete dominant single-parent case yields 50 single, 50 normal',
      () {
        final results = calculator.calculateFromGenotypes(
          father: ParentGenotype(
            gender: BirdGender.male,
            mutations: {'dark_factor': AlleleState.carrier},
          ),
          mother: _toGenotype({}, BirdGender.female),
        );

        final single = results.firstWhere(
          (r) => r.phenotype == 'Dark Factor (single)',
        );
        final normal = results.firstWhere((r) => r.phenotype == 'Normal');

        expect(single.probability, closeTo(0.5, 0.0001));
        expect(normal.probability, closeTo(0.5, 0.0001));
      },
    );

    test(
      'sex-linked father-only case yields carrier males and visual females',
      () {
        final results = calculator.calculateFromGenotypes(
          father: _toGenotype({'opaline'}, BirdGender.male),
          mother: _toGenotype({}, BirdGender.female),
        );

        final maleCarrier = results.firstWhere(
          (r) => r.sex == OffspringSex.male && r.isCarrier,
        );
        final femaleVisual = results.firstWhere(
          (r) => r.sex == OffspringSex.female && r.phenotype == 'Opaline',
        );

        expect(maleCarrier.phenotype, 'Opaline (carrier)');
        expect(maleCarrier.probability, closeTo(0.5, 0.0001));
        expect(femaleVisual.probability, closeTo(0.5, 0.0001));
      },
    );
  });
}
