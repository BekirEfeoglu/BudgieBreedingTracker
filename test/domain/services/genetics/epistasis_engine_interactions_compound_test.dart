import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/epistasis_engine.dart';

void main() {
  const engine = EpistasisEngine();

  group('_addPiedInteractions', () {
    group('Dark-Eyed Clear (recessive_pied + clearflight_pied)', () {
      test('detected when both recessive and clearflight pied present', () {
        final interactions = engine.getInteractions({
          'recessive_pied',
          'clearflight_pied',
        });

        final dec = interactions.where(
          (i) => i.resultName == 'Dark-Eyed Clear',
        );
        expect(dec, hasLength(1));
        expect(
          dec.first.mutationIds,
          containsAll(['recessive_pied', 'clearflight_pied']),
        );
        expect(dec.first.description, contains('Dark-Eyed Clear'));
      });

      test('not detected with recessive_pied alone', () {
        final interactions = engine.getInteractions({'recessive_pied'});

        expect(
          interactions.any((i) => i.resultName == 'Dark-Eyed Clear'),
          isFalse,
        );
      });

      test('not detected with clearflight_pied alone', () {
        final interactions = engine.getInteractions({'clearflight_pied'});

        expect(
          interactions.any((i) => i.resultName == 'Dark-Eyed Clear'),
          isFalse,
        );
      });

      test('detected alongside other mutations', () {
        final interactions = engine.getInteractions({
          'recessive_pied',
          'clearflight_pied',
          'blue',
          'opaline',
        });

        expect(
          interactions.any((i) => i.resultName == 'Dark-Eyed Clear'),
          isTrue,
        );
      });
    });

    group('Double Dominant Pied (dutch_pied + dominant_pied)', () {
      test('detected when both dutch and dominant pied present', () {
        final interactions = engine.getInteractions({
          'dutch_pied',
          'dominant_pied',
        });

        final ddp = interactions.where(
          (i) => i.resultName == 'Double Dominant Pied',
        );
        expect(ddp, hasLength(1));
        expect(
          ddp.first.mutationIds,
          containsAll(['dutch_pied', 'dominant_pied']),
        );
      });

      test('not detected with dutch_pied alone', () {
        final interactions = engine.getInteractions({'dutch_pied'});

        expect(
          interactions.any((i) => i.resultName == 'Double Dominant Pied'),
          isFalse,
        );
      });

      test('not detected with dominant_pied alone', () {
        final interactions = engine.getInteractions({'dominant_pied'});

        expect(
          interactions.any((i) => i.resultName == 'Double Dominant Pied'),
          isFalse,
        );
      });
    });

    group('Dutch Clearflight Pied (dutch_pied + clearflight_pied)', () {
      test('detected when both dutch and clearflight pied present', () {
        final interactions = engine.getInteractions({
          'dutch_pied',
          'clearflight_pied',
        });

        final dcp = interactions.where(
          (i) => i.resultName == 'Dutch Clearflight Pied',
        );
        expect(dcp, hasLength(1));
        expect(
          dcp.first.mutationIds,
          containsAll(['dutch_pied', 'clearflight_pied']),
        );
      });

      test('suppressed when recessive_pied is also present', () {
        final interactions = engine.getInteractions({
          'dutch_pied',
          'clearflight_pied',
          'recessive_pied',
        });

        expect(
          interactions.any((i) => i.resultName == 'Dutch Clearflight Pied'),
          isFalse,
        );
      });

      test('Dark-Eyed Clear takes priority over Dutch Clearflight Pied', () {
        final interactions = engine.getInteractions({
          'dutch_pied',
          'clearflight_pied',
          'recessive_pied',
        });

        expect(
          interactions.any((i) => i.resultName == 'Dark-Eyed Clear'),
          isTrue,
        );
        expect(
          interactions.any((i) => i.resultName == 'Dutch Clearflight Pied'),
          isFalse,
        );
      });

      test('not detected with dutch_pied alone', () {
        final interactions = engine.getInteractions({'dutch_pied'});

        expect(
          interactions.any((i) => i.resultName == 'Dutch Clearflight Pied'),
          isFalse,
        );
      });
    });

    group('multiple pied interactions simultaneously', () {
      test('Dark-Eyed Clear and Double Dominant Pied coexist', () {
        final interactions = engine.getInteractions({
          'recessive_pied',
          'clearflight_pied',
          'dutch_pied',
          'dominant_pied',
        });

        expect(
          interactions.any((i) => i.resultName == 'Dark-Eyed Clear'),
          isTrue,
        );
        expect(
          interactions.any((i) => i.resultName == 'Double Dominant Pied'),
          isTrue,
        );
        // Dutch Clearflight Pied suppressed because recessive_pied is present
        expect(
          interactions.any((i) => i.resultName == 'Dutch Clearflight Pied'),
          isFalse,
        );
      });

      test('Dutch Clearflight Pied and Double Dominant Pied coexist', () {
        final interactions = engine.getInteractions({
          'dutch_pied',
          'clearflight_pied',
          'dominant_pied',
        });

        expect(
          interactions.any((i) => i.resultName == 'Dutch Clearflight Pied'),
          isTrue,
        );
        expect(
          interactions.any((i) => i.resultName == 'Double Dominant Pied'),
          isTrue,
        );
      });
    });
  });

  group('_addBlackfaceSpangleInteractions', () {
    test('detected when both blackface and spangle present', () {
      final interactions = engine.getInteractions({'blackface', 'spangle'});

      final ms = interactions.where(
        (i) => i.resultName == 'Melanistic Spangle',
      );
      expect(ms, hasLength(1));
      expect(ms.first.mutationIds, containsAll(['blackface', 'spangle']));
      expect(ms.first.description, contains('melanin'));
    });

    test('not detected with blackface alone', () {
      final interactions = engine.getInteractions({'blackface'});

      expect(
        interactions.any((i) => i.resultName == 'Melanistic Spangle'),
        isFalse,
      );
    });

    test('not detected with spangle alone', () {
      final interactions = engine.getInteractions({'spangle'});

      expect(
        interactions.any((i) => i.resultName == 'Melanistic Spangle'),
        isFalse,
      );
    });

    test('detected alongside other mutations', () {
      final interactions = engine.getInteractions({
        'blackface',
        'spangle',
        'blue',
        'dark_factor',
      });

      expect(
        interactions.any((i) => i.resultName == 'Melanistic Spangle'),
        isTrue,
      );
    });
  });

  group('_addYellowfaceMaskedInteractions', () {
    test('detected for yellowface_type1 on green series', () {
      final interactions = engine.getInteractions({'yellowface_type1'});

      expect(
        interactions.any((i) => i.resultName == 'Yellowface (masked)'),
        isTrue,
      );
    });

    test('detected for yellowface_type2 on green series', () {
      final interactions = engine.getInteractions({'yellowface_type2'});

      expect(
        interactions.any((i) => i.resultName == 'Yellowface (masked)'),
        isTrue,
      );
    });

    test('not detected when blue is present (yf1)', () {
      final interactions = engine.getInteractions({
        'yellowface_type1',
        'blue',
      });

      expect(
        interactions.any((i) => i.resultName == 'Yellowface (masked)'),
        isFalse,
      );
    });

    test('not detected when blue is present (yf2)', () {
      final interactions = engine.getInteractions({
        'yellowface_type2',
        'blue',
      });

      expect(
        interactions.any((i) => i.resultName == 'Yellowface (masked)'),
        isFalse,
      );
    });

    test('not detected when aqua is present (aqua counts as blue series)', () {
      final interactions = engine.getInteractions({
        'yellowface_type1',
        'aqua',
      });

      expect(
        interactions.any((i) => i.resultName == 'Yellowface (masked)'),
        isFalse,
      );
    });

    test('not detected when turquoise is present', () {
      final interactions = engine.getInteractions({
        'yellowface_type2',
        'turquoise',
      });

      expect(
        interactions.any((i) => i.resultName == 'Yellowface (masked)'),
        isFalse,
      );
    });

    test('not detected when bluefactor_1 is present', () {
      final interactions = engine.getInteractions({
        'yellowface_type1',
        'bluefactor_1',
      });

      expect(
        interactions.any((i) => i.resultName == 'Yellowface (masked)'),
        isFalse,
      );
    });

    test('not detected when bluefactor_2 is present', () {
      final interactions = engine.getInteractions({
        'yellowface_type2',
        'bluefactor_2',
      });

      expect(
        interactions.any((i) => i.resultName == 'Yellowface (masked)'),
        isFalse,
      );
    });

    test('not detected for goldenface (not yf1 or yf2)', () {
      final interactions = engine.getInteractions({'goldenface'});

      expect(
        interactions.any((i) => i.resultName == 'Yellowface (masked)'),
        isFalse,
      );
    });

    test('description mentions green series', () {
      final interactions = engine.getInteractions({'yellowface_type1'});

      final masked = interactions.firstWhere(
        (i) => i.resultName == 'Yellowface (masked)',
      );
      expect(masked.description, contains('green series'));
    });
  });

  group('_addParblueInoInteractions', () {
    group('Aqua Ino', () {
      test('detected for ino + aqua without cinnamon', () {
        final interactions = engine.getInteractions({'ino', 'aqua'});

        final aquaIno = interactions.where(
          (i) => i.resultName == 'Aqua Ino',
        );
        expect(aquaIno, hasLength(1));
        expect(aquaIno.first.mutationIds, containsAll(['aqua', 'ino']));
      });

      test('suppressed when cinnamon is present', () {
        final interactions = engine.getInteractions({
          'ino',
          'aqua',
          'cinnamon',
        });

        expect(
          interactions.any((i) => i.resultName == 'Aqua Ino'),
          isFalse,
        );
      });

      test('not detected without ino', () {
        final interactions = engine.getInteractions({'aqua'});

        expect(
          interactions.any((i) => i.resultName == 'Aqua Ino'),
          isFalse,
        );
      });
    });

    group('Turquoise Ino', () {
      test('detected for ino + turquoise without cinnamon', () {
        final interactions = engine.getInteractions({'ino', 'turquoise'});

        final tqIno = interactions.where(
          (i) => i.resultName == 'Turquoise Ino',
        );
        expect(tqIno, hasLength(1));
        expect(tqIno.first.mutationIds, containsAll(['turquoise', 'ino']));
      });

      test('suppressed when cinnamon is present', () {
        final interactions = engine.getInteractions({
          'ino',
          'turquoise',
          'cinnamon',
        });

        expect(
          interactions.any((i) => i.resultName == 'Turquoise Ino'),
          isFalse,
        );
      });

      test('not detected without ino', () {
        final interactions = engine.getInteractions({'turquoise'});

        expect(
          interactions.any((i) => i.resultName == 'Turquoise Ino'),
          isFalse,
        );
      });
    });

    group('Aqua vs Turquoise priority', () {
      test('Aqua Ino preferred when both aqua and turquoise present', () {
        final interactions = engine.getInteractions({
          'ino',
          'aqua',
          'turquoise',
        });

        expect(
          interactions.any((i) => i.resultName == 'Aqua Ino'),
          isTrue,
        );
      });

      test('no parblue ino when neither aqua nor turquoise present', () {
        final interactions = engine.getInteractions({'ino', 'blue'});

        expect(
          interactions.any((i) => i.resultName == 'Aqua Ino'),
          isFalse,
        );
        expect(
          interactions.any((i) => i.resultName == 'Turquoise Ino'),
          isFalse,
        );
      });
    });

    test('description mentions parblue', () {
      final interactions = engine.getInteractions({'ino', 'aqua'});

      final aquaIno = interactions.firstWhere(
        (i) => i.resultName == 'Aqua Ino',
      );
      expect(aquaIno.description, contains('parblue'));
    });
  });

  group('_addPearlyInteractions', () {
    group('Opaline Pearly', () {
      test('detected for pearly + opaline', () {
        final interactions = engine.getInteractions({'pearly', 'opaline'});

        final op = interactions.where(
          (i) => i.resultName == 'Opaline Pearly',
        );
        expect(op, hasLength(1));
        expect(op.first.mutationIds, containsAll(['pearly', 'opaline']));
      });

      test('not detected with pearly alone', () {
        final interactions = engine.getInteractions({'pearly'});

        expect(
          interactions.any((i) => i.resultName == 'Opaline Pearly'),
          isFalse,
        );
      });

      test('not detected with opaline alone', () {
        final interactions = engine.getInteractions({'opaline'});

        expect(
          interactions.any((i) => i.resultName == 'Opaline Pearly'),
          isFalse,
        );
      });

      test('description mentions sex-linked', () {
        final interactions = engine.getInteractions({'pearly', 'opaline'});

        final op = interactions.firstWhere(
          (i) => i.resultName == 'Opaline Pearly',
        );
        expect(op.description, contains('sex-linked'));
      });
    });

    group('Cinnamon Pearly', () {
      test('detected for pearly + cinnamon', () {
        final interactions = engine.getInteractions({'pearly', 'cinnamon'});

        final cp = interactions.where(
          (i) => i.resultName == 'Cinnamon Pearly',
        );
        expect(cp, hasLength(1));
        expect(cp.first.mutationIds, containsAll(['pearly', 'cinnamon']));
      });

      test('not detected with pearly alone', () {
        final interactions = engine.getInteractions({'pearly'});

        expect(
          interactions.any((i) => i.resultName == 'Cinnamon Pearly'),
          isFalse,
        );
      });

      test('not detected with cinnamon alone', () {
        final interactions = engine.getInteractions({'cinnamon'});

        expect(
          interactions.any((i) => i.resultName == 'Cinnamon Pearly'),
          isFalse,
        );
      });

      test('description mentions brown tones', () {
        final interactions = engine.getInteractions({'pearly', 'cinnamon'});

        final cp = interactions.firstWhere(
          (i) => i.resultName == 'Cinnamon Pearly',
        );
        expect(cp.description, contains('brown'));
      });
    });

    group('both pearly interactions simultaneously', () {
      test('Opaline Pearly and Cinnamon Pearly coexist', () {
        final interactions = engine.getInteractions({
          'pearly',
          'opaline',
          'cinnamon',
        });

        expect(
          interactions.any((i) => i.resultName == 'Opaline Pearly'),
          isTrue,
        );
        expect(
          interactions.any((i) => i.resultName == 'Cinnamon Pearly'),
          isTrue,
        );
      });

      test('pearly interactions detected alongside other mutations', () {
        final interactions = engine.getInteractions({
          'pearly',
          'opaline',
          'cinnamon',
          'blue',
          'dark_factor',
        });

        expect(
          interactions.any((i) => i.resultName == 'Opaline Pearly'),
          isTrue,
        );
        expect(
          interactions.any((i) => i.resultName == 'Cinnamon Pearly'),
          isTrue,
        );
      });
    });
  });

  group('_addCrestedCompoundInteractions', () {
    test('detected for tufted + half_circular', () {
      final interactions = engine.getInteractions({
        'crested_tufted',
        'crested_half_circular',
      });

      final cc = interactions.where(
        (i) => i.resultName == 'Crested Compound',
      );
      expect(cc, hasLength(1));
      expect(
        cc.first.mutationIds,
        containsAll(['crested_tufted', 'crested_half_circular']),
      );
    });

    test('detected for tufted + full_circular', () {
      final interactions = engine.getInteractions({
        'crested_tufted',
        'crested_full_circular',
      });

      final cc = interactions.where(
        (i) => i.resultName == 'Crested Compound',
      );
      expect(cc, hasLength(1));
      expect(
        cc.first.mutationIds,
        containsAll(['crested_tufted', 'crested_full_circular']),
      );
    });

    test('detected for half_circular + full_circular', () {
      final interactions = engine.getInteractions({
        'crested_half_circular',
        'crested_full_circular',
      });

      final cc = interactions.where(
        (i) => i.resultName == 'Crested Compound',
      );
      expect(cc, hasLength(1));
      expect(
        cc.first.mutationIds,
        containsAll(['crested_half_circular', 'crested_full_circular']),
      );
    });

    test('detected for all three crested alleles with 3 mutation IDs', () {
      final interactions = engine.getInteractions({
        'crested_tufted',
        'crested_half_circular',
        'crested_full_circular',
      });

      final cc = interactions.where(
        (i) => i.resultName == 'Crested Compound',
      );
      expect(cc, hasLength(1));
      expect(cc.first.mutationIds, hasLength(3));
      expect(
        cc.first.mutationIds,
        containsAll([
          'crested_tufted',
          'crested_half_circular',
          'crested_full_circular',
        ]),
      );
    });

    test('not detected for single crested allele (tufted)', () {
      final interactions = engine.getInteractions({'crested_tufted'});

      expect(
        interactions.any((i) => i.resultName == 'Crested Compound'),
        isFalse,
      );
    });

    test('not detected for single crested allele (half_circular)', () {
      final interactions = engine.getInteractions({'crested_half_circular'});

      expect(
        interactions.any((i) => i.resultName == 'Crested Compound'),
        isFalse,
      );
    });

    test('not detected for single crested allele (full_circular)', () {
      final interactions = engine.getInteractions({'crested_full_circular'});

      expect(
        interactions.any((i) => i.resultName == 'Crested Compound'),
        isFalse,
      );
    });

    test('not detected when no crested alleles present', () {
      final interactions = engine.getInteractions({'blue', 'opaline'});

      expect(
        interactions.any((i) => i.resultName == 'Crested Compound'),
        isFalse,
      );
    });

    test('description mentions intermediate characteristics', () {
      final interactions = engine.getInteractions({
        'crested_tufted',
        'crested_half_circular',
      });

      final cc = interactions.firstWhere(
        (i) => i.resultName == 'Crested Compound',
      );
      expect(cc.description, contains('intermediate'));
    });
  });

  group('cross-function interaction combinations', () {
    test('pied + blackface spangle + pearly interactions all detected', () {
      final interactions = engine.getInteractions({
        'recessive_pied',
        'clearflight_pied',
        'blackface',
        'spangle',
        'pearly',
        'opaline',
      });

      expect(
        interactions.any((i) => i.resultName == 'Dark-Eyed Clear'),
        isTrue,
      );
      expect(
        interactions.any((i) => i.resultName == 'Melanistic Spangle'),
        isTrue,
      );
      expect(
        interactions.any((i) => i.resultName == 'Opaline Pearly'),
        isTrue,
      );
    });

    test('crested compound + yellowface masked coexist', () {
      final interactions = engine.getInteractions({
        'crested_tufted',
        'crested_full_circular',
        'yellowface_type1',
      });

      expect(
        interactions.any((i) => i.resultName == 'Crested Compound'),
        isTrue,
      );
      expect(
        interactions.any((i) => i.resultName == 'Yellowface (masked)'),
        isTrue,
      );
    });

    test('parblue ino + pearly interactions coexist', () {
      final interactions = engine.getInteractions({
        'ino',
        'aqua',
        'pearly',
        'opaline',
      });

      expect(
        interactions.any((i) => i.resultName == 'Aqua Ino'),
        isTrue,
      );
      expect(
        interactions.any((i) => i.resultName == 'Opaline Pearly'),
        isTrue,
      );
    });
  });

  group('edge cases', () {
    test('empty mutation set produces no compound interactions', () {
      final interactions = engine.getInteractions({});

      expect(
        interactions.any((i) =>
            i.resultName == 'Dark-Eyed Clear' ||
            i.resultName == 'Double Dominant Pied' ||
            i.resultName == 'Dutch Clearflight Pied' ||
            i.resultName == 'Melanistic Spangle' ||
            i.resultName == 'Yellowface (masked)' ||
            i.resultName == 'Aqua Ino' ||
            i.resultName == 'Turquoise Ino' ||
            i.resultName == 'Opaline Pearly' ||
            i.resultName == 'Cinnamon Pearly' ||
            i.resultName == 'Crested Compound'),
        isFalse,
      );
    });

    test('unrelated mutations produce no compound interactions', () {
      final interactions = engine.getInteractions({'blue', 'dark_factor'});

      expect(
        interactions.any((i) =>
            i.resultName == 'Dark-Eyed Clear' ||
            i.resultName == 'Double Dominant Pied' ||
            i.resultName == 'Melanistic Spangle' ||
            i.resultName == 'Yellowface (masked)' ||
            i.resultName == 'Opaline Pearly' ||
            i.resultName == 'Cinnamon Pearly' ||
            i.resultName == 'Crested Compound'),
        isFalse,
      );
    });

    test('all compound interactions have non-empty fields', () {
      final interactions = engine.getInteractions({
        'recessive_pied',
        'clearflight_pied',
        'blackface',
        'spangle',
        'yellowface_type1',
        'pearly',
        'opaline',
        'crested_tufted',
        'crested_half_circular',
      });

      final compoundNames = {
        'Dark-Eyed Clear',
        'Melanistic Spangle',
        'Yellowface (masked)',
        'Opaline Pearly',
        'Crested Compound',
      };

      for (final interaction in interactions) {
        if (compoundNames.contains(interaction.resultName)) {
          expect(interaction.mutationIds, isNotEmpty);
          expect(interaction.resultName, isNotEmpty);
          expect(interaction.description, isNotEmpty);
        }
      }
    });

    test('unknown mutation IDs do not trigger compound interactions', () {
      final interactions = engine.getInteractions({
        'unknown_pied',
        'fake_crested',
      });

      expect(interactions, isEmpty);
    });
  });
}
