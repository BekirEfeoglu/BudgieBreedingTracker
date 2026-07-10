import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/reverse_calculator.dart';

void main() {
  group('ReverseCalculationResult', () {
    test('has correct fields', () {
      final r = ReverseCalculationResult(
        father: ParentGenotype(
          gender: BirdGender.male,
          mutations: {'blue': AlleleState.visual},
        ),
        mother: ParentGenotype(
          gender: BirdGender.female,
          mutations: {'blue': AlleleState.carrier},
        ),
        probabilityMale: 0.5,
        probabilityFemale: 0.5,
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
        probabilityMale: 0.8,
        probabilityFemale: 0.4,
      );
      expect(r.probabilityAny, closeTo(0.6, 1e-12));
      expect(r.maxProbability, 0.8);
    });

    test('father and mother genotypes are accessible', () {
      final r = ReverseCalculationResult(
        father: ParentGenotype(
          gender: BirdGender.male,
          mutations: {'ino': AlleleState.carrier, 'blue': AlleleState.visual},
        ),
        mother: ParentGenotype(
          gender: BirdGender.female,
          mutations: {'ino': AlleleState.visual},
        ),
        probabilityMale: 0.25,
        probabilityFemale: 0.5,
      );
      expect(r.father.mutations, hasLength(2));
      expect(r.mother.hasVisual('ino'), isTrue);
      expect(r.father.hasCarrier('ino'), isTrue);
    });

    test('maxProbability returns highest of any, male, female', () {
      const r = ReverseCalculationResult(
        father: ParentGenotype.empty(gender: BirdGender.male),
        mother: ParentGenotype.empty(gender: BirdGender.female),
        probabilityMale: 0.0,
        probabilityFemale: 1.0,
      );
      expect(r.maxProbability, 1.0);
    });

    test('empty genotype handling', () {
      const r = ReverseCalculationResult(
        father: ParentGenotype.empty(gender: BirdGender.male),
        mother: ParentGenotype.empty(gender: BirdGender.female),
        probabilityMale: 0.0,
        probabilityFemale: 0.0,
      );
      expect(r.father.isEmpty, isTrue);
      expect(r.mother.isEmpty, isTrue);
      expect(r.probabilityAny, 0.0);
      expect(r.maxProbability, 0.0);
    });

    test('maxProbability prefers sex-specific peak over averaged any', () {
      // probabilityAny = (0.25 + 0.75)/2 = 0.5, but the female-only peak of
      // 0.75 is the better signal for a breeder planning a sex-targeted
      // outcome. maxProbability should surface that peak.
      const r = ReverseCalculationResult(
        father: ParentGenotype.empty(gender: BirdGender.male),
        mother: ParentGenotype.empty(gender: BirdGender.female),
        probabilityMale: 0.25,
        probabilityFemale: 0.75,
      );
      expect(r.probabilityAny, closeTo(0.5, 1e-12));
      expect(r.maxProbability, 0.75);
    });

    test('maxProbability when male and female are equal', () {
      const r = ReverseCalculationResult(
        father: ParentGenotype.empty(gender: BirdGender.male),
        mother: ParentGenotype.empty(gender: BirdGender.female),
        probabilityMale: 0.4,
        probabilityFemale: 0.4,
      );
      expect(r.maxProbability, 0.4);
      expect(r.probabilityAny, 0.4);
    });
  });

  group('ReverseCalculationResult.compare (Q3 deterministic tie-break)', () {
    ReverseCalculationResult res({
      Map<String, AlleleState> father = const {},
      Map<String, AlleleState> mother = const {},
      double male = 0,
      double female = 0,
    }) =>
        ReverseCalculationResult(
          father: ParentGenotype(gender: BirdGender.male, mutations: father),
          mother: ParentGenotype(gender: BirdGender.female, mutations: mother),
          probabilityMale: male,
          probabilityFemale: female,
        );

    test('1. maxProbability descending is the primary key', () {
      final high = res(male: 0.5, female: 0.5);
      final low = res(male: 0.25, female: 0.25);
      expect(ReverseCalculationResult.compare(high, low), lessThan(0));
      final sorted = [low, high]..sort(ReverseCalculationResult.compare);
      expect(sorted.first.maxProbability, 0.5);
    });

    test('2. on maxProbability tie, higher probabilityAny wins', () {
      final a = res(male: 0.5, female: 0.5); // max .5, any .5
      final b = res(male: 0.5, female: 0.1); // max .5, any .3
      expect(ReverseCalculationResult.compare(a, b), lessThan(0));
    });

    test('3. on prob tie, fewer non-wildtype parent states wins (simpler)', () {
      final simple = res(
        father: const {'blue': AlleleState.visual},
        male: 0.5,
        female: 0.5,
      );
      final complex = res(
        father: const {'blue': AlleleState.visual},
        mother: const {'grey': AlleleState.visual},
        male: 0.5,
        female: 0.5,
      );
      expect(simple.nonWildtypeStateCount, 1);
      expect(complex.nonWildtypeStateCount, 2);
      expect(ReverseCalculationResult.compare(simple, complex), lessThan(0));
    });

    test('4. on state-count tie, fewer visual requirements wins', () {
      final carrier = res(
        father: const {'blue': AlleleState.carrier},
        male: 0.5,
        female: 0.5,
      );
      final visual = res(
        father: const {'blue': AlleleState.visual},
        male: 0.5,
        female: 0.5,
      );
      expect(carrier.visualRequirementCount, 0);
      expect(visual.visualRequirementCount, 1);
      expect(ReverseCalculationResult.compare(carrier, visual), lessThan(0));
    });

    test('5. canonical signature is the final alphabetical tie-break', () {
      final a = res(
        father: const {'blue': AlleleState.visual},
        male: 0.5,
        female: 0.5,
      );
      final b = res(
        father: const {'grey': AlleleState.visual},
        male: 0.5,
        female: 0.5,
      );
      // Everything ties except the signature: 'blue' < 'grey'.
      expect(a.nonWildtypeStateCount, b.nonWildtypeStateCount);
      expect(a.visualRequirementCount, b.visualRequirementCount);
      expect(ReverseCalculationResult.compare(a, b), lessThan(0));
      expect(a.canonicalSignature.compareTo(b.canonicalSignature), lessThan(0));
    });

    test('primary key dominates: higher maxProbability wins even if complex', () {
      final complexButBetter = res(
        father: const {
          'blue': AlleleState.visual,
          'grey': AlleleState.visual,
        },
        male: 0.9,
        female: 0.9,
      );
      final simpleButWorse = res(
        father: const {'blue': AlleleState.visual},
        male: 0.5,
        female: 0.5,
      );
      // Simpler pairing must NOT jump ahead of a strictly better probability.
      expect(
        ReverseCalculationResult.compare(complexButBetter, simpleButWorse),
        lessThan(0),
      );
    });

    test('sort is order-independent (same result from any input order)', () {
      final x = res(father: const {'blue': AlleleState.visual}, male: 0.5, female: 0.5);
      final y = res(father: const {'grey': AlleleState.visual}, male: 0.5, female: 0.5);
      final z = res(male: 0.9, female: 0.9);
      final a = [x, y, z]..sort(ReverseCalculationResult.compare);
      final b = [z, y, x]..sort(ReverseCalculationResult.compare);
      expect(
        a.map((r) => r.canonicalSignature).toList(),
        b.map((r) => r.canonicalSignature).toList(),
      );
      expect(a.first.maxProbability, 0.9); // best prob first
    });

    test('calculateParents is deterministic: same input -> same ordered results',
        () {
      const calc = ReverseCalculator();
      final first = calc.calculateParents({'cinnamon', 'ino'});
      final second = calc.calculateParents({'cinnamon', 'ino'});
      expect(first, isNotEmpty);
      expect(
        first.map((r) => r.canonicalSignature).toList(),
        second.map((r) => r.canonicalSignature).toList(),
      );
    });
  });

  group('LocusPairResult', () {
    test('stores locus-level parent genotypes and probabilities', () {
      const lpr = LocusPairResult(
        fatherGenotype: {'blue': AlleleState.visual},
        motherGenotype: {'blue': AlleleState.carrier},
        probabilityMale: 0.5,
        probabilityFemale: 0.5,
      );
      expect(lpr.fatherGenotype['blue'], AlleleState.visual);
      expect(lpr.motherGenotype['blue'], AlleleState.carrier);
      expect(lpr.probabilityMale, 0.5);
    });
  });
}
