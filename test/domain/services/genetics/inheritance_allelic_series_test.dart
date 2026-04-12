import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

void main() {
  const calculator = MendelianCalculator();

  group('Allelic series inheritance', () {
    test(
      'carrier greywing x carrier clearwing yields 25% Full-Body Greywing',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'greywing': AlleleState.carrier},
        );
        final mother = ParentGenotype(
          gender: BirdGender.female,
          mutations: {'clearwing': AlleleState.carrier},
        );

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        final fullBody = results.firstWhere(
          (r) => r.phenotype == 'Full-Body Greywing',
        );
        final total = results.fold<double>(0, (sum, r) => sum + r.probability);

        expect(fullBody.probability, closeTo(0.25, 0.0001));
        expect(total, closeTo(1.0, 0.0001));
      },
    );

    test(
      'ino locus (texas clearbody carrier father x ino visual mother) returns both sexes',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'texas_clearbody': AlleleState.carrier},
        );
        final mother = ParentGenotype(
          gender: BirdGender.female,
          mutations: {'ino': AlleleState.visual},
        );

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        expect(
          results.any(
            (r) =>
                r.sex == OffspringSex.male &&
                r.phenotype.contains('Texas Clearbody'),
          ),
          isTrue,
        );
        expect(
          results.any(
            (r) =>
                r.sex == OffspringSex.female &&
                r.phenotype.contains('Texas Clearbody'),
          ),
          isTrue,
        );
      },
    );

    test(
      'ino locus pallid/ino male outcome resolves as PallidIno (Lacewing)',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'pallid': AlleleState.carrier},
        );
        final mother = ParentGenotype(
          gender: BirdGender.female,
          mutations: {'ino': AlleleState.visual},
        );

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        expect(
          results.any(
            (r) =>
                r.sex == OffspringSex.male &&
                r.phenotype.contains('PallidIno (Lacewing)'),
          ),
          isTrue,
        );
      },
    );

    test('blue locus goldenface/blue compound resolves as Goldenface Blue', () {
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: {'goldenface': AlleleState.carrier},
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: {'blue': AlleleState.visual},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expect(
        results.any((r) => r.phenotype.contains('Goldenface Blue')),
        isTrue,
      );
    });

    test(
      'blue locus bluefactor_2/blue compound resolves as Blue Factor II Blue',
      () {
        final father = ParentGenotype(
          gender: BirdGender.male,
          mutations: {'bluefactor_2': AlleleState.carrier},
        );
        final mother = ParentGenotype(
          gender: BirdGender.female,
          mutations: {'blue': AlleleState.visual},
        );

        final results = calculator.calculateFromGenotypes(
          father: father,
          mother: mother,
        );

        expect(
          results.any((r) => r.phenotype.contains('Blue Factor II Blue')),
          isTrue,
        );
      },
    );
  });
}
