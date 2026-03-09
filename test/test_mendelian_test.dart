import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';

void main() {
  test('Mendelian test', () {
    const calc = MendelianCalculator();
    final parentA = ParentGenotype(
      gender: BirdGender.male,
      mutations: {'blue': AlleleState.visual},
    );
    final parentB = ParentGenotype(
      gender: BirdGender.female,
      mutations: {'blue': AlleleState.visual},
    );

    final offspring = calc.calculateFromGenotypes(
      father: parentA,
      mother: parentB,
    );

    expect(offspring, hasLength(1));
    expect(offspring.single.phenotype, 'Blue');
    expect(offspring.single.visualMutations, ['blue']);
    expect(offspring.single.isCarrier, isFalse);
    expect(offspring.single.carriedMutations, isEmpty);
  });
}
