import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';

void main() {
  group('GeneticsConstants', () {
    group('inbreeding thresholds', () {
      test('thresholds are in ascending order', () {
        expect(GeneticsConstants.inbreedingMinimal,
            lessThan(GeneticsConstants.inbreedingLow));
        expect(GeneticsConstants.inbreedingLow,
            lessThan(GeneticsConstants.inbreedingModerate));
        expect(GeneticsConstants.inbreedingModerate,
            lessThan(GeneticsConstants.inbreedingHigh));
        expect(GeneticsConstants.inbreedingHigh,
            lessThan(GeneticsConstants.inbreedingCritical));
      });

      test('thresholds are in valid range 0.0 to 1.0', () {
        final thresholds = [
          GeneticsConstants.inbreedingMinimal,
          GeneticsConstants.inbreedingLow,
          GeneticsConstants.inbreedingModerate,
          GeneticsConstants.inbreedingHigh,
          GeneticsConstants.inbreedingCritical,
        ];

        for (final threshold in thresholds) {
          expect(threshold, greaterThanOrEqualTo(0.0),
              reason: 'Threshold $threshold must be >= 0.0');
          expect(threshold, lessThanOrEqualTo(1.0),
              reason: 'Threshold $threshold must be <= 1.0');
        }
      });

      test('expected specific values', () {
        expect(GeneticsConstants.inbreedingMinimal, 0.0625);
        expect(GeneticsConstants.inbreedingLow, 0.125);
        expect(GeneticsConstants.inbreedingModerate, 0.25);
        expect(GeneticsConstants.inbreedingHigh, 0.375);
        expect(GeneticsConstants.inbreedingCritical, 0.5);
      });
    });

    group('recombination rates', () {
      test('all recombination rates are in valid range 0.0 to 1.0', () {
        final rates = [
          GeneticsConstants.cinnamonInoRecombination,
          GeneticsConstants.opalineCinnamonRecombination,
          GeneticsConstants.opalineInoRecombination,
          GeneticsConstants.cinnamonSlateRecombination,
          GeneticsConstants.opalineSlateRecombination,
          GeneticsConstants.inoSlateRecombination,
        ];

        for (final rate in rates) {
          expect(rate, greaterThan(0.0),
              reason: 'Recombination rate $rate must be > 0.0');
          expect(rate, lessThan(1.0),
              reason: 'Recombination rate $rate must be < 1.0');
        }
      });

      test('expected specific values', () {
        expect(GeneticsConstants.cinnamonInoRecombination, 0.03);
        expect(GeneticsConstants.opalineCinnamonRecombination, 0.34);
        expect(GeneticsConstants.opalineInoRecombination, 0.30);
        expect(GeneticsConstants.cinnamonSlateRecombination, 0.05);
        expect(GeneticsConstants.opalineSlateRecombination, 0.40);
        expect(GeneticsConstants.inoSlateRecombination, 0.02);
      });

      test(
          'cinnamon-ino is smaller than opaline-cinnamon '
          '(closely linked loci)', () {
        expect(
          GeneticsConstants.cinnamonInoRecombination,
          lessThan(GeneticsConstants.opalineCinnamonRecombination),
        );
      });

      test('ino-slate is the smallest recombination rate', () {
        final rates = [
          GeneticsConstants.cinnamonInoRecombination,
          GeneticsConstants.opalineCinnamonRecombination,
          GeneticsConstants.opalineInoRecombination,
          GeneticsConstants.cinnamonSlateRecombination,
          GeneticsConstants.opalineSlateRecombination,
          GeneticsConstants.inoSlateRecombination,
        ];

        final minRate = rates.reduce(
          (a, b) => a < b ? a : b,
        );

        expect(minRate, GeneticsConstants.inoSlateRecombination);
      });

      test(
          'opaline-slate is the largest recombination rate '
          '(farthest apart on Z)', () {
        final rates = [
          GeneticsConstants.cinnamonInoRecombination,
          GeneticsConstants.opalineCinnamonRecombination,
          GeneticsConstants.opalineInoRecombination,
          GeneticsConstants.cinnamonSlateRecombination,
          GeneticsConstants.opalineSlateRecombination,
          GeneticsConstants.inoSlateRecombination,
        ];

        final maxRate = rates.reduce(
          (a, b) => a > b ? a : b,
        );

        expect(maxRate, GeneticsConstants.opalineSlateRecombination);
      });
    });

    group('allelic series locus IDs', () {
      test('locus IDs are non-empty strings', () {
        final loci = [
          GeneticsConstants.locusDilution,
          GeneticsConstants.locusBlueSeries,
          GeneticsConstants.locusIno,
          GeneticsConstants.locusCrested,
        ];

        for (final locus in loci) {
          expect(locus, isNotEmpty,
              reason: 'Locus ID must not be empty');
        }
      });

      test('expected locus ID values', () {
        expect(GeneticsConstants.locusDilution, 'dilution');
        expect(GeneticsConstants.locusBlueSeries, 'blue_series');
        expect(GeneticsConstants.locusIno, 'ino_locus');
        expect(GeneticsConstants.locusCrested, 'crested');
      });

      test('locus IDs are unique', () {
        final loci = [
          GeneticsConstants.locusDilution,
          GeneticsConstants.locusBlueSeries,
          GeneticsConstants.locusIno,
          GeneticsConstants.locusCrested,
        ];

        expect(loci.toSet().length, loci.length,
            reason: 'All locus IDs must be unique');
      });
    });

    group('crested allele IDs', () {
      test('contains expected alleles', () {
        expect(
          GeneticsConstants.crestedAlleleIds,
          containsAll([
            'crested_tufted',
            'crested_half_circular',
            'crested_full_circular',
          ]),
        );
      });

      test('has exactly 3 alleles', () {
        expect(GeneticsConstants.crestedAlleleIds, hasLength(3));
      });

      test('all allele IDs are non-empty', () {
        for (final allele in GeneticsConstants.crestedAlleleIds) {
          expect(allele, isNotEmpty);
        }
      });

      test('all allele IDs start with crested_ prefix', () {
        for (final allele in GeneticsConstants.crestedAlleleIds) {
          expect(allele.startsWith('crested_'), isTrue,
              reason: '"$allele" should start with crested_');
        }
      });
    });
  });
}
