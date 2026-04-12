import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/reverse_calculator.dart';

void main() {
  group('ReverseCalculationResult', () {
    test('has correct fields', () {
      final r = ReverseCalculationResult(
        father: ParentGenotype(gender: BirdGender.male, mutations: {'blue': AlleleState.visual}),
        mother: ParentGenotype(gender: BirdGender.female, mutations: {'blue': AlleleState.carrier}),
        probabilityMale: 0.5, probabilityFemale: 0.5,
      );
      expect(r.father.gender, BirdGender.male);
      expect(r.mother.gender, BirdGender.female);
      expect(r.probabilityMale, 0.5);
      expect(r.probabilityFemale, 0.5);
    });

    test('probability is stored and computed correctly', () {
      const r = ReverseCalculationResult(
        father: ParentGenotype.empty(gender: BirdGender.male),
        mother: ParentGenotype.empty(gender: BirdGender.female),
        probabilityMale: 0.8, probabilityFemale: 0.4,
      );
      expect(r.probabilityAny, closeTo(0.6, 1e-12));
      expect(r.maxProbability, 0.8);
    });

    test('father and mother genotypes are accessible', () {
      final r = ReverseCalculationResult(
        father: ParentGenotype(gender: BirdGender.male, mutations: {'ino': AlleleState.carrier, 'blue': AlleleState.visual}),
        mother: ParentGenotype(gender: BirdGender.female, mutations: {'ino': AlleleState.visual}),
        probabilityMale: 0.25, probabilityFemale: 0.5,
      );
      expect(r.father.mutations, hasLength(2));
      expect(r.mother.hasVisual('ino'), isTrue);
      expect(r.father.hasCarrier('ino'), isTrue);
    });

    test('maxProbability returns highest of any, male, female', () {
      const r = ReverseCalculationResult(
        father: ParentGenotype.empty(gender: BirdGender.male),
        mother: ParentGenotype.empty(gender: BirdGender.female),
        probabilityMale: 0.0, probabilityFemale: 1.0,
      );
      expect(r.maxProbability, 1.0);
    });

    test('empty genotype handling', () {
      const r = ReverseCalculationResult(
        father: ParentGenotype.empty(gender: BirdGender.male),
        mother: ParentGenotype.empty(gender: BirdGender.female),
        probabilityMale: 0.0, probabilityFemale: 0.0,
      );
      expect(r.father.isEmpty, isTrue);
      expect(r.mother.isEmpty, isTrue);
      expect(r.probabilityAny, 0.0);
      expect(r.maxProbability, 0.0);
    });
  });

  group('LocusPairResult', () {
    test('stores locus-level parent genotypes and probabilities', () {
      const lpr = LocusPairResult(
        fatherGenotype: {'blue': AlleleState.visual},
        motherGenotype: {'blue': AlleleState.carrier},
        probabilityMale: 0.5, probabilityFemale: 0.5,
      );
      expect(lpr.fatherGenotype['blue'], AlleleState.visual);
      expect(lpr.motherGenotype['blue'], AlleleState.carrier);
      expect(lpr.probabilityMale, 0.5);
    });
  });
}
