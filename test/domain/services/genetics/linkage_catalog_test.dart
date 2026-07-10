import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/genetics_constants.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/linkage_catalog.dart';

void main() {
  group('LinkageCatalog — single source of truth', () {
    // The engine reads exactly these six constants; the catalog must return the
    // identical value so display and calculation can never drift apart.
    final expectedRates = <(String, String), double>{
      ('cinnamon', 'ino'): GeneticsConstants.cinnamonInoRecombination,
      ('ino', 'slate'): GeneticsConstants.inoSlateRecombination,
      ('cinnamon', 'slate'): GeneticsConstants.cinnamonSlateRecombination,
      ('opaline', 'ino'): GeneticsConstants.opalineInoRecombination,
      ('opaline', 'cinnamon'): GeneticsConstants.opalineCinnamonRecombination,
      ('opaline', 'slate'): GeneticsConstants.opalineSlateRecombination,
    };

    test('engine rate == catalog rate for all six pairs', () {
      for (final entry in expectedRates.entries) {
        final (a, b) = entry.key;
        expect(
          LinkageCatalog.recombinationRateFor(a, b),
          entry.value,
          reason: 'catalog rate for $a-$b must equal the engine constant',
        );
      }
    });

    test('lookup is symmetric: (a,b) returns the same record as (b,a)', () {
      for (final entry in expectedRates.entries) {
        final (a, b) = entry.key;
        final ab = LinkageCatalog.lookup(a, b);
        final ba = LinkageCatalog.lookup(b, a);
        expect(ab, isNotNull);
        expect(identical(ab, ba), isTrue,
            reason: '$a-$b and $b-$a must resolve to the same catalog record');
      }
    });

    test('catalog holds exactly six canonical pairs', () {
      expect(LinkageCatalog.allPairs.length, 6);
    });
  });

  group('LinkageCatalog — UI drift fixed', () {
    test('Opaline-Cinnamon displays 32 cM (was drifted to 34)', () {
      final info = LinkageCatalog.lookup('opaline', 'cinnamon')!;
      expect(info.displayCentiMorgansLabel, '32');
      expect(info.recombinationRate, 0.32);
    });

    test('Opaline-Slate: rate 0.405, displays 40.5 cM (was drifted to 40)', () {
      final info = LinkageCatalog.lookup('opaline', 'slate')!;
      expect(info.recombinationRate, 0.405);
      expect(info.displayCentiMorgans, 40.5);
      expect(info.displayCentiMorgansLabel, '40.5');
    });

    test('remaining distances display correctly', () {
      expect(
        LinkageCatalog.lookup('opaline', 'ino')!.displayCentiMorgansLabel,
        '30',
      );
      expect(
        LinkageCatalog.lookup('cinnamon', 'ino')!.displayCentiMorgansLabel,
        '3',
      );
      expect(
        LinkageCatalog.lookup('cinnamon', 'slate')!.displayCentiMorgansLabel,
        '5',
      );
      expect(
        LinkageCatalog.lookup('ino', 'slate')!.displayCentiMorgansLabel,
        '2',
      );
    });
  });

  group('LinkageCatalog — evidence provenance', () {
    test('measured pairs are flagged measured', () {
      for (final p in [
        ['cinnamon', 'ino'],
        ['cinnamon', 'slate'],
        ['opaline', 'cinnamon'],
        ['opaline', 'slate'],
      ]) {
        expect(
          LinkageCatalog.lookup(p[0], p[1])!.evidence,
          LinkageEvidence.measured,
          reason: '${p[0]}-${p[1]} should be measured',
        );
      }
    });

    test('Opaline-Ino is derived, not presented as measured', () {
      final info = LinkageCatalog.lookup('opaline', 'ino')!;
      expect(info.evidence, LinkageEvidence.derived);
      expect(info.sourceNote, isNotEmpty);
    });

    test('Ino-Slate is estimated, not presented as measured', () {
      final info = LinkageCatalog.lookup('ino', 'slate')!;
      expect(info.evidence, LinkageEvidence.estimated);
      expect(info.sourceNote, isNotEmpty);
    });

    test('every pair carries a non-empty source note', () {
      for (final info in LinkageCatalog.allPairs) {
        expect(info.sourceNote, isNotEmpty);
      }
    });
  });

  group('LinkageCatalog — ino-locus allele generalisation', () {
    test('pallid/pearly/texas_clearbody inherit ino distances', () {
      for (final allele in ['pallid', 'pearly', 'texas_clearbody']) {
        expect(
          LinkageCatalog.recombinationRateFor(allele, 'cinnamon'),
          GeneticsConstants.cinnamonInoRecombination,
        );
        expect(
          LinkageCatalog.recombinationRateFor(allele, 'slate'),
          GeneticsConstants.inoSlateRecombination,
        );
        expect(
          LinkageCatalog.recombinationRateFor(allele, 'opaline'),
          GeneticsConstants.opalineInoRecombination,
        );
      }
    });

    test('two alleles at the same ino position are not linked to each other', () {
      expect(LinkageCatalog.lookup('pearly', 'texas_clearbody'), isNull);
      expect(LinkageCatalog.lookup('ino', 'pallid'), isNull);
    });

    test('non-linkage mutations return null / empty', () {
      expect(LinkageCatalog.normalizeToken('blue'), isNull);
      expect(LinkageCatalog.recombinationRateFor('blue', 'opaline'), isNull);
      expect(LinkageCatalog.linkagesFor('blue'), isEmpty);
    });
  });

  group('LinkageCatalog — linkagesFor', () {
    test('returns three partners for opaline, tightest first', () {
      final links = LinkageCatalog.linkagesFor('opaline');
      expect(links.map((l) => l.partnerLocus), ['ino', 'cinnamon', 'slate']);
      // ascending recombination: ino(0.30) < cinnamon(0.32) < slate(0.405)
      final rates = links.map((l) => l.info.recombinationRate).toList();
      expect(rates[0] <= rates[1], isTrue);
      expect(rates[1] <= rates[2], isTrue);
    });

    test('pearly (ino locus) lists cinnamon/slate/opaline, not ino', () {
      final partners =
          LinkageCatalog.linkagesFor('pearly').map((l) => l.partnerLocus);
      expect(partners, containsAll(['cinnamon', 'slate', 'opaline']));
      expect(partners.contains('ino'), isFalse);
    });
  });
}
