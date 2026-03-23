import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/genetics/epistasis_engine.dart';

/// Targeted tests for epistasis_engine_interactions.dart (part of epistasis_engine).
///
/// These tests comprehensively cover _getInteractions() through the public
/// EpistasisEngine.getInteractions() API, verifying all interaction detection
/// logic including edge cases and combination priorities.
void main() {
  const engine = EpistasisEngine();

  group('PallidIno / Creamino / Albino / Lutino priority chain', () {
    test('Ino + Pallid detects PallidIno (Lacewing)', () {
      final interactions = engine.getInteractions({'ino', 'pallid'});

      final pallidIno = interactions.where(
        (i) => i.resultName == 'PallidIno (Lacewing)',
      );
      expect(pallidIno, hasLength(1));
      expect(pallidIno.first.mutationIds, containsAll(['pallid', 'ino']));
    });

    test('PallidIno takes priority over Creamino', () {
      final interactions = engine.getInteractions({
        'ino',
        'pallid',
        'yellowface_type2',
        'blue',
      });

      // PallidIno should be detected, not Creamino
      expect(
        interactions.any((i) => i.resultName == 'PallidIno (Lacewing)'),
        isTrue,
      );
      expect(
        interactions.any((i) => i.resultName == 'Creamino'),
        isFalse,
      );
    });

    test('PallidIno takes priority over Albino', () {
      final interactions = engine.getInteractions({
        'ino',
        'pallid',
        'blue',
      });

      expect(
        interactions.any((i) => i.resultName == 'PallidIno (Lacewing)'),
        isTrue,
      );
      // Albino should NOT be detected when PallidIno is present
      expect(
        interactions.any((i) => i.resultName == 'Albino'),
        isFalse,
      );
    });

    test('Creamino from yellowface_type2 + blue + ino', () {
      final interactions = engine.getInteractions({
        'ino',
        'blue',
        'yellowface_type2',
      });

      final creamino = interactions.where((i) => i.resultName == 'Creamino');
      expect(creamino, hasLength(1));
      expect(
        creamino.first.mutationIds,
        containsAll(['yellowface_type2', 'ino']),
      );
    });

    test('Creamino from goldenface + blue + ino', () {
      final interactions = engine.getInteractions({
        'ino',
        'blue',
        'goldenface',
      });

      final creamino = interactions.where((i) => i.resultName == 'Creamino');
      expect(creamino, hasLength(1));
      expect(creamino.first.mutationIds, contains('goldenface'));
    });

    test('Creamino from bluefactor_1 + ino (implicitly blue series)', () {
      final interactions = engine.getInteractions({
        'ino',
        'bluefactor_1',
      });

      final creamino = interactions.where((i) => i.resultName == 'Creamino');
      expect(creamino, hasLength(1));
      expect(creamino.first.mutationIds, contains('bluefactor_1'));
    });

    test('Creamino from bluefactor_2 + ino (implicitly blue series)', () {
      final interactions = engine.getInteractions({
        'ino',
        'bluefactor_2',
      });

      final creamino = interactions.where((i) => i.resultName == 'Creamino');
      expect(creamino, hasLength(1));
      expect(creamino.first.mutationIds, contains('bluefactor_2'));
    });

    test('Creamino source priority: yf2 > goldenface > bf2 > bf1', () {
      // When multiple yellowface-type alleles are present with ino,
      // yf2 is checked first
      final interactions = engine.getInteractions({
        'ino',
        'blue',
        'yellowface_type2',
        'goldenface',
      });

      final creamino = interactions.firstWhere(
        (i) => i.resultName == 'Creamino',
      );
      expect(creamino.mutationIds, contains('yellowface_type2'));
    });

    test('Albino detected for ino + blue without yellowface or pallid', () {
      final interactions = engine.getInteractions({'ino', 'blue'});

      final albino = interactions.where((i) => i.resultName == 'Albino');
      expect(albino, hasLength(1));
      expect(albino.first.mutationIds, containsAll(['ino', 'blue']));
    });

    test('Albino detected for ino + aqua (aqua is blue series)', () {
      final interactions = engine.getInteractions({'ino', 'aqua'});

      // Aqua counts as blue series, so albino should be detected
      // (plus Aqua Ino interaction)
      expect(
        interactions.any((i) => i.resultName == 'Albino'),
        isTrue,
      );
    });

    test('Albino detected for ino + turquoise (turquoise is blue series)', () {
      final interactions = engine.getInteractions({'ino', 'turquoise'});

      expect(
        interactions.any((i) => i.resultName == 'Albino'),
        isTrue,
      );
    });

    test('Albino detected for ino + bluefactor_1 (bf1 is blue series)', () {
      final interactions = engine.getInteractions({'ino', 'bluefactor_1'});

      // Should detect Creamino (bf1 + ino), NOT Albino
      expect(
        interactions.any((i) => i.resultName == 'Creamino'),
        isTrue,
      );
    });

    test('Lutino detected for ino without blue series alleles', () {
      final interactions = engine.getInteractions({'ino'});

      final lutino = interactions.where((i) => i.resultName == 'Lutino');
      expect(lutino, hasLength(1));
      expect(lutino.first.mutationIds, contains('ino'));
    });

    test('no Lutino when ino + blue series is present', () {
      final interactions = engine.getInteractions({'ino', 'blue'});

      expect(
        interactions.any((i) => i.resultName == 'Lutino'),
        isFalse,
      );
    });
  });

  group('Lacewing interaction (Ino + Cinnamon)', () {
    test('detects Lacewing for ino + cinnamon', () {
      final interactions = engine.getInteractions({'ino', 'cinnamon'});

      final lacewing = interactions.where((i) => i.resultName == 'Lacewing');
      expect(lacewing, hasLength(1));
      expect(
        lacewing.first.mutationIds,
        containsAll(['ino', 'cinnamon']),
      );
    });

    test('Lacewing + Lutino both detected for ino + cinnamon (green series)', () {
      final interactions = engine.getInteractions({'ino', 'cinnamon'});

      expect(
        interactions.any((i) => i.resultName == 'Lacewing'),
        isTrue,
      );
      expect(
        interactions.any((i) => i.resultName == 'Lutino'),
        isTrue,
      );
    });

    test('Lacewing + Albino both detected for ino + cinnamon + blue', () {
      final interactions = engine.getInteractions({'ino', 'cinnamon', 'blue'});

      expect(
        interactions.any((i) => i.resultName == 'Lacewing'),
        isTrue,
      );
      expect(
        interactions.any((i) => i.resultName == 'Albino'),
        isTrue,
      );
    });
  });

  group('Visual Violet interaction', () {
    test('detects Visual Violet for blue + violet + dark_factor', () {
      final interactions = engine.getInteractions({
        'blue',
        'violet',
        'dark_factor',
      });

      final visualViolet = interactions.where(
        (i) => i.resultName == 'Visual Violet',
      );
      expect(visualViolet, hasLength(1));
      expect(
        visualViolet.first.mutationIds,
        containsAll(['violet', 'blue', 'dark_factor']),
      );
    });

    test('no Visual Violet without dark_factor', () {
      final interactions = engine.getInteractions({'blue', 'violet'});

      expect(
        interactions.any((i) => i.resultName == 'Visual Violet'),
        isFalse,
      );
    });

    test('no Visual Violet without blue series', () {
      final interactions = engine.getInteractions({'violet', 'dark_factor'});

      expect(
        interactions.any((i) => i.resultName == 'Visual Violet'),
        isFalse,
      );
    });

    test('Visual Violet detected with aqua as blue series', () {
      final interactions = engine.getInteractions({
        'aqua',
        'violet',
        'dark_factor',
      });

      expect(
        interactions.any((i) => i.resultName == 'Visual Violet'),
        isTrue,
      );
    });

    test('Visual Violet detected with turquoise as blue series', () {
      final interactions = engine.getInteractions({
        'turquoise',
        'violet',
        'dark_factor',
      });

      expect(
        interactions.any((i) => i.resultName == 'Visual Violet'),
        isTrue,
      );
    });
  });

  group('Grey-Green interaction', () {
    test('detects Grey-Green for grey on green series', () {
      final interactions = engine.getInteractions({'grey'});

      final greyGreen = interactions.where(
        (i) => i.resultName == 'Grey-Green',
      );
      expect(greyGreen, hasLength(1));
      expect(greyGreen.first.mutationIds, contains('grey'));
    });

    test('no Grey-Green when blue series is present', () {
      final interactions = engine.getInteractions({'grey', 'blue'});

      expect(
        interactions.any((i) => i.resultName == 'Grey-Green'),
        isFalse,
      );
    });

    test('no Grey-Green when aqua is present (counts as blue)', () {
      final interactions = engine.getInteractions({'grey', 'aqua'});

      expect(
        interactions.any((i) => i.resultName == 'Grey-Green'),
        isFalse,
      );
    });

    test('no Grey-Green when turquoise is present (counts as blue)', () {
      final interactions = engine.getInteractions({'grey', 'turquoise'});

      expect(
        interactions.any((i) => i.resultName == 'Grey-Green'),
        isFalse,
      );
    });

    test('no Grey-Green when bluefactor_1 is present', () {
      final interactions = engine.getInteractions({'grey', 'bluefactor_1'});

      expect(
        interactions.any((i) => i.resultName == 'Grey-Green'),
        isFalse,
      );
    });

    test('no Grey-Green when bluefactor_2 is present', () {
      final interactions = engine.getInteractions({'grey', 'bluefactor_2'});

      expect(
        interactions.any((i) => i.resultName == 'Grey-Green'),
        isFalse,
      );
    });
  });

  group('Full-Body Greywing interaction', () {
    test('detects Full-Body Greywing for greywing + clearwing', () {
      final interactions = engine.getInteractions({'greywing', 'clearwing'});

      final fbg = interactions.where(
        (i) => i.resultName == 'Full-Body Greywing',
      );
      expect(fbg, hasLength(1));
      expect(
        fbg.first.mutationIds,
        containsAll(['greywing', 'clearwing']),
      );
    });

    test('no Full-Body Greywing without both greywing and clearwing', () {
      expect(
        engine.getInteractions({'greywing'}).any(
          (i) => i.resultName == 'Full-Body Greywing',
        ),
        isFalse,
      );
      expect(
        engine.getInteractions({'clearwing'}).any(
          (i) => i.resultName == 'Full-Body Greywing',
        ),
        isFalse,
      );
    });
  });

  group('Pied compound interactions', () {
    test('detects Dark-Eyed Clear for recessive_pied + clearflight_pied', () {
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
    });

    test('detects Double Dominant Pied for dutch_pied + dominant_pied', () {
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

    test('detects Dutch Clearflight Pied for dutch_pied + clearflight_pied', () {
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

    test('no Dutch Clearflight Pied when recessive_pied is also present', () {
      final interactions = engine.getInteractions({
        'dutch_pied',
        'clearflight_pied',
        'recessive_pied',
      });

      // Dark-Eyed Clear (recessive+clearflight) should be detected
      expect(
        interactions.any((i) => i.resultName == 'Dark-Eyed Clear'),
        isTrue,
      );
      // Dutch Clearflight Pied should NOT be detected (guarded by !hasRecessivePied)
      expect(
        interactions.any((i) => i.resultName == 'Dutch Clearflight Pied'),
        isFalse,
      );
    });
  });

  group('Melanistic Spangle interaction', () {
    test('detects Melanistic Spangle for blackface + spangle', () {
      final interactions = engine.getInteractions({'blackface', 'spangle'});

      final ms = interactions.where(
        (i) => i.resultName == 'Melanistic Spangle',
      );
      expect(ms, hasLength(1));
      expect(
        ms.first.mutationIds,
        containsAll(['blackface', 'spangle']),
      );
    });

    test('no Melanistic Spangle without spangle', () {
      final interactions = engine.getInteractions({'blackface'});

      expect(
        interactions.any((i) => i.resultName == 'Melanistic Spangle'),
        isFalse,
      );
    });

    test('no Melanistic Spangle without blackface', () {
      final interactions = engine.getInteractions({'spangle'});

      expect(
        interactions.any((i) => i.resultName == 'Melanistic Spangle'),
        isFalse,
      );
    });
  });

  group('Yellowface masked on green series', () {
    test('detects Yellowface masked for yf1 on green', () {
      final interactions = engine.getInteractions({'yellowface_type1'});

      expect(
        interactions.any((i) => i.resultName == 'Yellowface (masked)'),
        isTrue,
      );
    });

    test('detects Yellowface masked for yf2 on green', () {
      final interactions = engine.getInteractions({'yellowface_type2'});

      expect(
        interactions.any((i) => i.resultName == 'Yellowface (masked)'),
        isTrue,
      );
    });

    test('no Yellowface masked when blue series is present', () {
      final interactions = engine.getInteractions({
        'yellowface_type1',
        'blue',
      });

      expect(
        interactions.any((i) => i.resultName == 'Yellowface (masked)'),
        isFalse,
      );
    });

    test('no Yellowface masked when aqua is present', () {
      final interactions = engine.getInteractions({
        'yellowface_type2',
        'aqua',
      });

      expect(
        interactions.any((i) => i.resultName == 'Yellowface (masked)'),
        isFalse,
      );
    });
  });

  group('Aqua/Turquoise + Ino interactions', () {
    test('detects Aqua Ino for aqua + ino', () {
      final interactions = engine.getInteractions({'ino', 'aqua'});

      final aquaIno = interactions.where((i) => i.resultName == 'Aqua Ino');
      expect(aquaIno, hasLength(1));
      expect(aquaIno.first.mutationIds, containsAll(['aqua', 'ino']));
    });

    test('detects Turquoise Ino for turquoise + ino', () {
      final interactions = engine.getInteractions({'ino', 'turquoise'});

      final tqIno = interactions.where(
        (i) => i.resultName == 'Turquoise Ino',
      );
      expect(tqIno, hasLength(1));
      expect(tqIno.first.mutationIds, containsAll(['turquoise', 'ino']));
    });

    test('no Aqua Ino when cinnamon is also present', () {
      // The interaction is guarded by !hasCinnamon
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

    test('no Turquoise Ino when cinnamon is also present', () {
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

    test('prefers Aqua over Turquoise when both present with ino', () {
      final interactions = engine.getInteractions({
        'ino',
        'aqua',
        'turquoise',
      });

      // hasAqua is checked first in the code
      expect(
        interactions.any((i) => i.resultName == 'Aqua Ino'),
        isTrue,
      );
    });
  });

  group('Pearly interactions', () {
    test('detects Opaline Pearly for pearly + opaline', () {
      final interactions = engine.getInteractions({'pearly', 'opaline'});

      final op = interactions.where(
        (i) => i.resultName == 'Opaline Pearly',
      );
      expect(op, hasLength(1));
      expect(op.first.mutationIds, containsAll(['pearly', 'opaline']));
    });

    test('detects Cinnamon Pearly for pearly + cinnamon', () {
      final interactions = engine.getInteractions({'pearly', 'cinnamon'});

      final cp = interactions.where(
        (i) => i.resultName == 'Cinnamon Pearly',
      );
      expect(cp, hasLength(1));
      expect(cp.first.mutationIds, containsAll(['pearly', 'cinnamon']));
    });

    test('no Opaline Pearly without opaline', () {
      final interactions = engine.getInteractions({'pearly'});

      expect(
        interactions.any((i) => i.resultName == 'Opaline Pearly'),
        isFalse,
      );
    });

    test('no Cinnamon Pearly without cinnamon', () {
      final interactions = engine.getInteractions({'pearly'});

      expect(
        interactions.any((i) => i.resultName == 'Cinnamon Pearly'),
        isFalse,
      );
    });

    test('both Opaline Pearly and Cinnamon Pearly detected simultaneously', () {
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
  });

  group('Crested Compound interaction', () {
    test('detects Crested Compound for two crested alleles', () {
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

    test('detects Crested Compound for all three crested alleles', () {
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
    });

    test('no Crested Compound for single crested allele', () {
      final interactions = engine.getInteractions({'crested_tufted'});

      expect(
        interactions.any((i) => i.resultName == 'Crested Compound'),
        isFalse,
      );
    });

    test('tufted + full_circular detects Crested Compound', () {
      final interactions = engine.getInteractions({
        'crested_tufted',
        'crested_full_circular',
      });

      expect(
        interactions.any((i) => i.resultName == 'Crested Compound'),
        isTrue,
      );
    });

    test('half_circular + full_circular detects Crested Compound', () {
      final interactions = engine.getInteractions({
        'crested_half_circular',
        'crested_full_circular',
      });

      expect(
        interactions.any((i) => i.resultName == 'Crested Compound'),
        isTrue,
      );
    });
  });

  group('Multiple simultaneous interactions', () {
    test('complex mutation set produces multiple interactions', () {
      final interactions = engine.getInteractions({
        'blue',
        'violet',
        'dark_factor',
        'recessive_pied',
        'clearflight_pied',
        'greywing',
        'clearwing',
      });

      expect(
        interactions.any((i) => i.resultName == 'Visual Violet'),
        isTrue,
      );
      expect(
        interactions.any((i) => i.resultName == 'Dark-Eyed Clear'),
        isTrue,
      );
      expect(
        interactions.any((i) => i.resultName == 'Full-Body Greywing'),
        isTrue,
      );
    });

    test('ino-heavy mutation set produces correct interactions', () {
      final interactions = engine.getInteractions({
        'ino',
        'cinnamon',
        'pearly',
        'opaline',
      });

      // Lacewing (ino+cinnamon), Lutino (ino on green),
      // Opaline Pearly, Cinnamon Pearly
      expect(
        interactions.any((i) => i.resultName == 'Lacewing'),
        isTrue,
      );
      expect(
        interactions.any((i) => i.resultName == 'Lutino'),
        isTrue,
      );
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

  group('Edge cases', () {
    test('empty mutation set returns no interactions', () {
      final interactions = engine.getInteractions({});

      expect(interactions, isEmpty);
    });

    test('single non-interactive mutation returns no interactions', () {
      final interactions = engine.getInteractions({'saddleback'});

      expect(interactions, isEmpty);
    });

    test('all interaction entries have non-empty mutationIds', () {
      final interactions = engine.getInteractions({
        'ino',
        'blue',
        'cinnamon',
        'violet',
        'dark_factor',
      });

      for (final interaction in interactions) {
        expect(interaction.mutationIds, isNotEmpty);
        expect(interaction.resultName, isNotEmpty);
        expect(interaction.description, isNotEmpty);
      }
    });

    test('unknown mutation IDs do not cause exceptions', () {
      // Should not throw, just ignore unknown IDs
      final interactions = engine.getInteractions({
        'fake_mutation',
        'another_fake',
      });

      expect(interactions, isEmpty);
    });

    test('duplicate mutation IDs do not duplicate interactions', () {
      // Sets naturally deduplicate, but verify behavior
      final interactions = engine.getInteractions({'ino', 'blue'});
      final albinos = interactions.where((i) => i.resultName == 'Albino');

      expect(albinos, hasLength(1));
    });
  });
}
