import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

/// Guards the v9 fix: the multi-locus combiner must not collapse genotypically
/// different offspring states that share a post-masking compound phenotype
/// name.
///
/// Before v9 the grouping key was `label|sex[|doubleFactorSet]`. Ino erases all
/// melanin, so a heterozygous dominant Blackface and the plain wild-type both
/// resolve to the same compound name under a visual-ino cross, with an empty
/// double-factor set and no carried mutations — an identical key. The merge
/// branch then assigned `visualMutations` / `maskedMutations` from whichever
/// state iterated last, so the persisted hidden-gene readout was wrong for part
/// of the merged group. Probabilities and the phenotype name were always right,
/// which is why the rest of the suite stayed green.
void main() {
  const calculator = MendelianCalculator();

  group('multi-locus ino + dominant pattern masking', () {
    test('does not merge states whose masked mutation sets differ', () {
      // Father: visual ino + heterozygous (split) dominant Blackface.
      // Mother: visual ino, no Blackface.
      // Blackface segregates 50/50, but ino masks it either way, so both
      // branches produce the same compound phenotype name.
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: const {
          'ino': AlleleState.visual,
          'blackface': AlleleState.split,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: const {'ino': AlleleState.visual},
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      expect(results, isNotEmpty);

      // Every reported group must be internally consistent: a group that
      // claims to mask blackface must not be the same group as one that
      // does not. Collapsing them is exactly the v9 defect.
      final maskingBlackface = results
          .where((r) => r.maskedMutations.contains('Blackface'))
          .toList();
      final notMaskingBlackface = results
          .where((r) => !r.maskedMutations.contains('Blackface'))
          .toList();

      // Both hidden-gene states must survive as distinct results rather than
      // one overwriting the other.
      expect(
        maskingBlackface,
        isNotEmpty,
        reason:
            'the blackface-carrying branch was dropped or overwritten during '
            'multi-locus merging',
      );
      expect(
        notMaskingBlackface,
        isNotEmpty,
        reason:
            'the wild-type branch was dropped or overwritten during '
            'multi-locus merging',
      );

      // Probabilities must still sum to ~1 — the fix splits groups, it does
      // not invent or lose probability mass.
      final total = results.fold<double>(0, (sum, r) => sum + r.probability);
      expect(total, closeTo(1.0, 0.01));
    });

    test('merged groups union rather than overwrite their mutation lists', () {
      // A cross wide enough that several states share a compound name and the
      // merge branch is genuinely exercised.
      final father = ParentGenotype(
        gender: BirdGender.male,
        mutations: const {
          'ino': AlleleState.visual,
          'blackface': AlleleState.split,
          'blue': AlleleState.carrier,
        },
      );
      final mother = ParentGenotype(
        gender: BirdGender.female,
        mutations: const {
          'ino': AlleleState.visual,
          'blue': AlleleState.carrier,
        },
      );

      final results = calculator.calculateFromGenotypes(
        father: father,
        mother: mother,
      );

      for (final result in results) {
        // A mutation can be reported as visible or as masked, never both:
        // that overlap is the signature of an overwrite leaking one state's
        // list into another's.
        final overlap = result.visualMutations.toSet().intersection(
          result.maskedMutations.toSet(),
        );
        expect(
          overlap,
          isEmpty,
          reason:
              'result "${result.phenotype}" reports ${overlap.toList()} as '
              'both visible and masked',
        );
      }

      final total = results.fold<double>(0, (sum, r) => sum + r.probability);
      expect(total, closeTo(1.0, 0.01));
    });
  });
}
