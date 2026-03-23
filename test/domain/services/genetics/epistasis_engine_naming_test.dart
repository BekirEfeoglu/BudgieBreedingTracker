import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/epistasis_engine.dart';

/// Targeted tests for epistasis_engine_naming.dart (part of epistasis_engine).
///
/// Covers: _addPiedNaming, _addCrestedNaming, _resolveBaseColorName.
void main() {
  const engine = EpistasisEngine();

  group('_addPiedNaming — single pied mutations', () {
    test('Recessive Pied alone shows Recessive Pied', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutRecessivePied,
      });

      expect(result, contains('Recessive Pied'));
    });

    test('Clearflight Pied alone shows Clearflight Pied', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutClearflightPied,
      });

      expect(result, contains('Clearflight Pied'));
    });

    test('Dominant Pied alone shows Dominant Pied', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutDominantPied,
      });

      expect(result, contains('Dominant Pied'));
    });

    test('Dutch Pied alone shows Dutch Pied', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutDutchPied,
      });

      expect(result, contains('Dutch Pied'));
    });
  });

  group('_addPiedNaming — Dark-Eyed Clear detection', () {
    test('Recessive Pied + Clearflight Pied = Dark-Eyed Clear', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutRecessivePied,
        GeneticsConstants.mutClearflightPied,
      });

      expect(result, contains('Dark-Eyed Clear'));
      expect(result, isNot(contains('Recessive Pied')));
      expect(result, isNot(contains('Clearflight Pied')));
    });

    test('Dark-Eyed Clear with blue base shows Skyblue context', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutRecessivePied,
        GeneticsConstants.mutClearflightPied,
        GeneticsConstants.mutBlue,
      });

      expect(result, contains('Dark-Eyed Clear'));
      expect(result, contains('Skyblue'));
    });
  });

  group('_addPiedNaming — compound pied combinations', () {
    test('Dominant Pied + Dutch Pied = Double Dominant Pied', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutDominantPied,
        GeneticsConstants.mutDutchPied,
      });

      expect(result, contains('Double Dominant Pied'));
      expect(result, isNot(contains('Dutch Pied ')));
    });

    test('Clearflight Pied + Dutch Pied = Dutch Clearflight Pied', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutClearflightPied,
        GeneticsConstants.mutDutchPied,
      });

      expect(result, contains('Dutch Clearflight Pied'));
    });

    test(
      'Recessive Pied + Dominant Pied shows both independently',
      () {
        final result = engine.resolveCompoundPhenotype({
          GeneticsConstants.mutRecessivePied,
          GeneticsConstants.mutDominantPied,
        });

        expect(result, contains('Recessive Pied'));
        expect(result, contains('Dominant Pied'));
      },
    );
  });

  group('_addCrestedNaming — single crested alleles', () {
    test('Tufted shows Tufted', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutCrestedTufted,
      });

      expect(result, contains('Tufted'));
    });

    test('Half-Circular shows Half-Circular Crest', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutCrestedHalfCircular,
      });

      expect(result, contains('Half-Circular Crest'));
    });

    test('Full-Circular shows Full-Circular Crest', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutCrestedFullCircular,
      });

      expect(result, contains('Full-Circular Crest'));
    });
  });

  group('_addCrestedNaming — compound heterozygote detection', () {
    test('Tufted + Half-Circular = compound crest', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutCrestedTufted,
        GeneticsConstants.mutCrestedHalfCircular,
      });

      expect(result, contains('Compound Crest'));
      expect(result, contains('Tufted'));
      expect(result, contains('Half-Circular'));
    });

    test('Tufted + Full-Circular = compound crest', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutCrestedTufted,
        GeneticsConstants.mutCrestedFullCircular,
      });

      expect(result, contains('Compound Crest'));
      expect(result, contains('Tufted'));
      expect(result, contains('Full-Circular'));
    });

    test('Half-Circular + Full-Circular = compound crest', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutCrestedHalfCircular,
        GeneticsConstants.mutCrestedFullCircular,
      });

      expect(result, contains('Compound Crest'));
      expect(result, contains('Half-Circular'));
      expect(result, contains('Full-Circular'));
    });

    test('all three crested alleles produces compound crest', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutCrestedTufted,
        GeneticsConstants.mutCrestedHalfCircular,
        GeneticsConstants.mutCrestedFullCircular,
      });

      expect(result, contains('Compound Crest'));
    });
  });

  group('_resolveBaseColorName — green series', () {
    test('green + 0 dark factor = Light Green', () {
      final result = engine.resolveCompoundPhenotype({});

      expect(result, 'Normal');
    });

    test('green + 1 dark factor = Dark Green', () {
      final result = engine.resolveCompoundPhenotype({'dark_factor'});

      expect(result, contains('Dark Green'));
    });

    test('green + 2 dark factor = Olive', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {'dark_factor'},
        doubleFactorIds: {'dark_factor'},
      );

      expect(result.name, contains('Olive'));
    });
  });

  group('_resolveBaseColorName — blue series', () {
    test('blue + 0 dark factor = Skyblue', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutBlue,
      });

      expect(result, 'Skyblue');
    });

    test('blue + 1 dark factor = Cobalt', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutBlue,
        'dark_factor',
      });

      expect(result, contains('Cobalt'));
    });

    test('blue + 2 dark factor = Mauve', () {
      final result = engine.resolveCompoundPhenotypeDetailed(
        {GeneticsConstants.mutBlue, 'dark_factor'},
        doubleFactorIds: {'dark_factor'},
      );

      expect(result.name, contains('Mauve'));
    });
  });

  group('edge cases', () {
    test('empty mutations set returns Normal', () {
      final result = engine.resolveCompoundPhenotype({});

      expect(result, 'Normal');
    });

    test('empty mutations detailed returns Normal with no masked', () {
      final detailed = engine.resolveCompoundPhenotypeDetailed({});

      expect(detailed.name, 'Normal');
      expect(detailed.maskedMutations, isEmpty);
    });

    test('pied with blue and dark factor combines correctly', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutBlue,
        'dark_factor',
        GeneticsConstants.mutRecessivePied,
      });

      expect(result, contains('Cobalt'));
      expect(result, contains('Recessive Pied'));
    });

    test('crested with color mutations combines correctly', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutBlue,
        GeneticsConstants.mutCrestedTufted,
      });

      expect(result, contains('Skyblue'));
      expect(result, contains('Tufted'));
    });

    test('pied + crested + base color all combine', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutBlue,
        GeneticsConstants.mutRecessivePied,
        GeneticsConstants.mutCrestedHalfCircular,
      });

      expect(result, contains('Skyblue'));
      expect(result, contains('Recessive Pied'));
      expect(result, contains('Half-Circular Crest'));
    });
  });

  group('name ordering and priority', () {
    test('base color appears before pied in name', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutBlue,
        GeneticsConstants.mutDominantPied,
      });

      final skyblueIdx = result.indexOf('Skyblue');
      final piedIdx = result.indexOf('Dominant Pied');
      expect(skyblueIdx, lessThan(piedIdx));
    });

    test('pied appears before crested in name', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutDominantPied,
        GeneticsConstants.mutCrestedTufted,
      });

      final piedIdx = result.indexOf('Dominant Pied');
      final crestedIdx = result.indexOf('Tufted');
      expect(piedIdx, lessThan(crestedIdx));
    });

    test('Dark-Eyed Clear replaces individual pied names', () {
      final result = engine.resolveCompoundPhenotype({
        GeneticsConstants.mutRecessivePied,
        GeneticsConstants.mutClearflightPied,
      });

      // Should NOT show individual pied names separately
      final recessiveCount =
          'Recessive Pied'.allMatches(result).length;
      expect(recessiveCount, 0);
    });
  });
}
