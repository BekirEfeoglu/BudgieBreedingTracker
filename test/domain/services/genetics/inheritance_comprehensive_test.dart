import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

const _calc = MendelianCalculator();

ParentGenotype _geno(BirdGender g, Map<String, AlleleState> m) =>
    ParentGenotype(gender: g, mutations: m);

List<OffspringResult> _cross(
  Map<String, AlleleState> fatherMuts,
  Map<String, AlleleState> motherMuts,
) =>
    _calc.calculateFromGenotypes(
      father: _geno(BirdGender.male, fatherMuts),
      mother: _geno(BirdGender.female, motherMuts),
    );

void main() {
  // -----------------------------------------------------------------------
  // InheritanceGenotype
  // -----------------------------------------------------------------------
  group('InheritanceGenotype', () {
    test('autosomal recessive: carrier x carrier -> 25/50/25', () {
      final r = _cross(
        {'recessive_pied': AlleleState.carrier},
        {'recessive_pied': AlleleState.carrier},
      );
      final visual = r.firstWhere((x) => x.phenotype == 'Recessive Pied');
      final carrier = r.firstWhere((x) => x.phenotype.contains('carrier'));
      final normal = r.firstWhere((x) => x.phenotype == 'Normal');
      expect(visual.probability, closeTo(0.25, 0.0001));
      expect(carrier.probability, closeTo(0.50, 0.0001));
      expect(normal.probability, closeTo(0.25, 0.0001));
    });

    test('autosomal recessive: visual x carrier -> 50/50', () {
      final r = _cross(
        {'recessive_pied': AlleleState.visual},
        {'recessive_pied': AlleleState.carrier},
      );
      final visual = r.firstWhere((x) => x.phenotype == 'Recessive Pied');
      final carrier = r.firstWhere((x) => x.phenotype.contains('carrier'));
      expect(visual.probability, closeTo(0.50, 0.0001));
      expect(carrier.probability, closeTo(0.50, 0.0001));
      expect(r.where((x) => x.phenotype == 'Normal'), isEmpty);
    });

    test('autosomal recessive: visual x visual -> 100% visual', () {
      final r = _cross(
        {'blue': AlleleState.visual},
        {'blue': AlleleState.visual},
      );
      expect(r.length, 1);
      expect(r.first.phenotype, 'Blue');
      expect(r.first.probability, closeTo(1.0, 0.0001));
    });

    test('autosomal dominant: heterozygous x heterozygous -> 75/25', () {
      final r = _cross(
        {'grey': AlleleState.carrier},
        {'grey': AlleleState.carrier},
      );
      final totalVisual = r
          .where((x) => x.phenotype.contains('Grey'))
          .fold<double>(0, (s, x) => s + x.probability);
      final normal = r.firstWhere((x) => x.phenotype == 'Normal');
      expect(totalVisual, closeTo(0.75, 0.0001));
      expect(normal.probability, closeTo(0.25, 0.0001));
    });

    test('incomplete dominant: hetero x hetero -> 25 DF / 50 SF / 25 normal',
        () {
      final r = _cross(
        {'dark_factor': AlleleState.carrier},
        {'dark_factor': AlleleState.carrier},
      );
      final df = r.firstWhere((x) => x.phenotype.contains('double'));
      final sf = r.firstWhere((x) => x.phenotype.contains('single'));
      final normal = r.firstWhere((x) => x.phenotype == 'Normal');
      expect(df.probability, closeTo(0.25, 0.0001));
      expect(sf.probability, closeTo(0.50, 0.0001));
      expect(normal.probability, closeTo(0.25, 0.0001));
    });

    test('sex-linked: carrier male x normal female -> carriers + visuals', () {
      final r = _calc.calculateFromGenotypes(
        father: _geno(BirdGender.male, {'opaline': AlleleState.carrier}),
        mother: const ParentGenotype.empty(gender: BirdGender.female),
      );
      final carrierM = r.where(
        (x) => x.sex == OffspringSex.male && x.isCarrier,
      );
      final normalM = r.where(
        (x) => x.sex == OffspringSex.male && !x.isCarrier,
      );
      final visualF = r.where(
        (x) => x.sex == OffspringSex.female && x.phenotype.contains('Opaline'),
      );
      final normalF = r.where(
        (x) => x.sex == OffspringSex.female && x.phenotype == 'Normal',
      );
      expect(carrierM.length, 1);
      expect(carrierM.first.probability, closeTo(0.25, 0.0001));
      expect(normalM.length, 1);
      expect(normalM.first.probability, closeTo(0.25, 0.0001));
      expect(visualF.length, 1);
      expect(visualF.first.probability, closeTo(0.25, 0.0001));
      expect(normalF.length, 1);
      expect(normalF.first.probability, closeTo(0.25, 0.0001));
    });

    test('sex-linked: visual male x normal female -> carrier males, '
        'visual females', () {
      final r = _calc.calculateFromGenotypes(
        father: _geno(BirdGender.male, {'cinnamon': AlleleState.visual}),
        mother: const ParentGenotype.empty(gender: BirdGender.female),
      );
      final males = r.where((x) => x.sex == OffspringSex.male);
      final females = r.where((x) => x.sex == OffspringSex.female);
      expect(males.length, 1);
      expect(males.first.isCarrier, isTrue);
      expect(males.first.probability, closeTo(0.50, 0.0001));
      expect(females.length, 1);
      expect(females.first.phenotype, contains('Cinnamon'));
      expect(females.first.probability, closeTo(0.50, 0.0001));
    });

    test('normal x normal (no mutations) -> empty results', () {
      final r = _calc.calculateFromGenotypes(
        father: const ParentGenotype.empty(gender: BirdGender.male),
        mother: const ParentGenotype.empty(gender: BirdGender.female),
      );
      expect(r, isEmpty);
    });

    test('both parents visual recessive -> 100% visual', () {
      final r = _cross(
        {'recessive_pied': AlleleState.visual},
        {'recessive_pied': AlleleState.visual},
      );
      expect(r.length, 1);
      expect(r.first.phenotype, 'Recessive Pied');
      expect(r.first.probability, closeTo(1.0, 0.0001));
    });
  });

  // -----------------------------------------------------------------------
  // InheritanceCombiner
  // -----------------------------------------------------------------------
  group('InheritanceCombiner', () {
    test('single locus results pass through correctly', () {
      final r = _cross(
        {'blue': AlleleState.visual},
        {'blue': AlleleState.visual},
      );
      expect(r, isNotEmpty);
      expect(r.first.phenotype, 'Blue');
      expect(r.first.probability, closeTo(1.0, 0.0001));
    });

    test('two independent loci multiply probabilities correctly', () {
      final r = _cross(
        {'blue': AlleleState.carrier, 'recessive_pied': AlleleState.carrier},
        {'blue': AlleleState.carrier, 'recessive_pied': AlleleState.carrier},
      );
      expect(r, isNotEmpty);
      // Both visual: 0.25 * 0.25 = 0.0625
      final bothVisual = r.where(
        (x) =>
            x.visualMutations.contains('blue') &&
            x.visualMutations.contains('recessive_pied'),
      );
      expect(bothVisual, isNotEmpty);
      expect(bothVisual.first.probability, closeTo(0.0625, 0.0001));
    });

    test('phenotype grouping: no duplicate phenotype+sex keys', () {
      final r = _cross(
        {'blue': AlleleState.carrier},
        {'blue': AlleleState.carrier},
      );
      final keys = r.map((x) => '${x.phenotype}|${x.sex.name}').toSet();
      expect(keys.length, r.length);
    });

    test('probability normalization sums to ~1.0', () {
      final r = _cross(
        {'blue': AlleleState.visual, 'dominant_pied': AlleleState.visual},
        {'blue': AlleleState.carrier, 'dominant_pied': AlleleState.carrier},
      );
      final total = r.fold<double>(0, (s, x) => s + x.probability);
      expect(total, closeTo(1.0, 0.0001));
    });

    test('results sorted by probability descending', () {
      final r = _cross(
        {'dark_factor': AlleleState.carrier},
        {'dark_factor': AlleleState.carrier},
      );
      for (var i = 0; i < r.length - 1; i++) {
        expect(r[i].probability, greaterThanOrEqualTo(r[i + 1].probability));
      }
    });

    test('carrier mutations collected from raw results', () {
      final r = _cross(
        {'blue': AlleleState.carrier},
        {'blue': AlleleState.carrier},
      );
      final carrierResult = r.firstWhere((x) => x.isCarrier);
      expect(carrierResult.carriedMutations, isNotEmpty);
    });

    test('double factor detection from phenotype with "(double)"', () {
      final r = _cross(
        {'spangle': AlleleState.carrier},
        {'spangle': AlleleState.carrier},
      );
      final df = r.firstWhere((x) => x.phenotype.contains('double'));
      expect(df.doubleFactorIds, isNotEmpty);
    });

    test('empty parents returns empty list', () {
      final r = _calc.calculateFromGenotypes(
        father: const ParentGenotype.empty(gender: BirdGender.male),
        mother: const ParentGenotype.empty(gender: BirdGender.female),
      );
      expect(r, isEmpty);
    });

    test('sex-compatible result merging (male + female + both)', () {
      final r = _calc.calculateFromGenotypes(
        father: _geno(BirdGender.male, {'opaline': AlleleState.carrier}),
        mother: const ParentGenotype.empty(gender: BirdGender.female),
      );
      final males = r.where((x) => x.sex == OffspringSex.male);
      final females = r.where((x) => x.sex == OffspringSex.female);
      expect(males, isNotEmpty);
      expect(females, isNotEmpty);
      final maleT = males.fold<double>(0, (s, x) => s + x.probability);
      final femaleT = females.fold<double>(0, (s, x) => s + x.probability);
      expect(maleT + femaleT, closeTo(1.0, 0.0001));
    });

    test('multi-locus with 3+ loci does not explode (perf guard)', () {
      final r = _cross(
        {
          'blue': AlleleState.carrier,
          'dark_factor': AlleleState.carrier,
          'spangle': AlleleState.carrier,
        },
        {
          'blue': AlleleState.carrier,
          'dark_factor': AlleleState.carrier,
          'spangle': AlleleState.carrier,
        },
      );
      expect(r, isNotEmpty);
      expect(r.length, lessThanOrEqualTo(27));
      final total = r.fold<double>(0, (s, x) => s + x.probability);
      expect(total, closeTo(1.0, 0.0001));
    });
  });
}
