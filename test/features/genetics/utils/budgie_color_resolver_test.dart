import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/genetics/utils/budgie_color_resolver.dart';

void main() {
  group('BudgieColorResolver', () {
    test('matches WBO base swatches for the primary exhibition colors', () {
      expect(BudgiePhenotypePalette.lightGreen, const Color(0xFF8CD600));
      expect(BudgiePhenotypePalette.darkGreen, const Color(0xFF56AA1C));
      expect(BudgiePhenotypePalette.olive, const Color(0xFF566B21));
      expect(BudgiePhenotypePalette.greyGreen, const Color(0xFFAFA80A));
      expect(BudgiePhenotypePalette.skyBlue, const Color(0xFF72D1DD));
      expect(BudgiePhenotypePalette.cobalt, const Color(0xFF60AFDD));
      expect(BudgiePhenotypePalette.mauve, const Color(0xFF9BA3B7));
      expect(BudgiePhenotypePalette.grey, const Color(0xFF8A9098));
    });

    test('keeps wild-type and carrier-only birds in the green series', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: const [],
        phenotype: 'Normal',
      );

      expect(appearance.bodyColor, BudgiePhenotypePalette.lightGreen);
      expect(appearance.maskColor, BudgiePhenotypePalette.maskYellow);
      expect(appearance.wingMarkingColor, BudgiePhenotypePalette.wingBlack);
      expect(appearance.showCarrierAccent, isFalse);
    });

    test('resolves visual blue birds with white mask', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: const ['blue'],
        phenotype: 'Skyblue',
      );

      expect(appearance.bodyColor, BudgiePhenotypePalette.skyBlue);
      expect(appearance.maskColor, BudgiePhenotypePalette.maskWhite);
    });

    test('keeps cobalt and mauve distinct from skyblue', () {
      final cobalt = BudgieColorResolver.resolve(
        visualMutations: const ['blue', 'dark_factor'],
        phenotype: 'Cobalt',
      );
      final mauve = BudgieColorResolver.resolve(
        visualMutations: const ['blue', 'dark_factor'],
        phenotype: 'Mauve',
      );

      expect(cobalt.bodyColor, BudgiePhenotypePalette.cobalt);
      expect(mauve.bodyColor, BudgiePhenotypePalette.mauve);
      expect(cobalt.bodyColor, isNot(mauve.bodyColor));
    });

    test('adds yellow mask and suffusion for yellowface variants', () {
      final yellowfaceOne = BudgieColorResolver.resolve(
        visualMutations: const ['blue', 'yellowface_type1'],
        phenotype: 'Yellowface Type I Skyblue',
      );
      final goldenface = BudgieColorResolver.resolve(
        visualMutations: const ['blue', 'goldenface'],
        phenotype: 'Goldenface Skyblue',
      );

      expect(yellowfaceOne.maskColor, BudgiePhenotypePalette.maskYellow);
      expect(goldenface.maskColor, BudgiePhenotypePalette.maskYellow);
      expect(yellowfaceOne.bodyColor, isNot(BudgiePhenotypePalette.lightGreen));
      expect(goldenface.bodyColor, isNot(yellowfaceOne.bodyColor));
    });

    test('resolves ino-based phenotypes to clear-bodied birds', () {
      final albino = BudgieColorResolver.resolve(
        visualMutations: const ['ino', 'blue'],
        phenotype: 'Albino',
      );
      final lutino = BudgieColorResolver.resolve(
        visualMutations: const ['ino'],
        phenotype: 'Lutino',
      );
      final creamino = BudgieColorResolver.resolve(
        visualMutations: const ['ino', 'blue', 'goldenface'],
        phenotype: 'Creamino',
      );

      expect(albino.bodyColor, BudgiePhenotypePalette.maskWhite);
      expect(lutino.bodyColor, BudgiePhenotypePalette.lutino);
      expect(creamino.bodyColor, BudgiePhenotypePalette.cream);
      expect(albino.cheekPatchColor, BudgiePhenotypePalette.maskWhite);
      expect(lutino.cheekPatchColor, BudgiePhenotypePalette.maskWhite);
      expect(albino.hideWingMarkings, isTrue);
      expect(lutino.hideWingMarkings, isTrue);
    });

    test('uses cinnamon and greywing markings instead of black wings', () {
      final cinnamon = BudgieColorResolver.resolve(
        visualMutations: const ['cinnamon'],
        phenotype: 'Light Green Cinnamon',
      );
      final greywing = BudgieColorResolver.resolve(
        visualMutations: const ['blue', 'greywing'],
        phenotype: 'Skyblue Greywing',
      );

      expect(cinnamon.wingMarkingColor, BudgiePhenotypePalette.cinnamon);
      expect(cinnamon.bodyColor, isNot(BudgiePhenotypePalette.lightGreen));
      expect(greywing.wingMarkingColor, BudgiePhenotypePalette.wingGrey);
      expect(greywing.bodyColor, isNot(BudgiePhenotypePalette.skyBlue));
      expect(greywing.cheekPatchColor, BudgiePhenotypePalette.cheekPaleViolet);
    });

    test(
      'clears double factor spangle while keeping normal spangle patterned',
      () {
        final sfSpangle = BudgieColorResolver.resolve(
          visualMutations: const ['blue', 'spangle'],
          phenotype: 'Skyblue Spangle',
        );
        final dfSpangle = BudgieColorResolver.resolve(
          visualMutations: const ['blue', 'spangle'],
          phenotype: 'Double Factor Spangle',
        );

        expect(sfSpangle.hideWingMarkings, isFalse);
        expect(dfSpangle.hideWingMarkings, isTrue);
        expect(dfSpangle.bodyColor, BudgiePhenotypePalette.maskWhite);
      },
    );

    test('distinguishes grey, slate, and anthracite bodies', () {
      final grey = BudgieColorResolver.resolve(
        visualMutations: const ['blue', 'grey'],
        phenotype: 'Grey',
      );
      final slate = BudgieColorResolver.resolve(
        visualMutations: const ['slate'],
        phenotype: 'Slate',
      );
      final anthracite = BudgieColorResolver.resolve(
        visualMutations: const ['anthracite'],
        phenotype: 'Double Factor Anthracite',
      );

      expect(grey.bodyColor, BudgiePhenotypePalette.grey);
      expect(grey.cheekPatchColor, BudgiePhenotypePalette.grey);
      expect(slate.bodyColor, BudgiePhenotypePalette.slate);
      expect(anthracite.bodyColor, BudgiePhenotypePalette.anthraciteDouble);
      expect(
        anthracite.cheekPatchColor,
        BudgiePhenotypePalette.anthraciteDouble,
      );
    });

    test('keeps green-series slate and anthracite green-toned', () {
      final lightGreenSlate = BudgieColorResolver.resolve(
        visualMutations: const ['slate'],
        phenotype: 'Light Green Slate',
      );
      final lightGreenAnthracite = BudgieColorResolver.resolve(
        visualMutations: const ['anthracite'],
        phenotype: 'Light Green Single Factor Anthracite',
      );

      expect(
        lightGreenSlate.bodyColor,
        Color.lerp(
          BudgiePhenotypePalette.lightGreen,
          BudgiePhenotypePalette.greyGreen,
          0.42,
        ),
      );
      expect(
        lightGreenAnthracite.bodyColor,
        BudgiePhenotypePalette.anthraciteGreenSingle,
      );
      expect(lightGreenSlate.bodyColor, isNot(BudgiePhenotypePalette.slate));
      expect(
        lightGreenAnthracite.bodyColor,
        isNot(BudgiePhenotypePalette.anthraciteSingle),
      );
      expect(
        lightGreenAnthracite.cheekPatchColor,
        isNot(BudgiePhenotypePalette.anthraciteGreenSingle),
      );
      expect(lightGreenSlate.maskColor, BudgiePhenotypePalette.maskYellow);
      expect(lightGreenAnthracite.maskColor, BudgiePhenotypePalette.maskYellow);
    });

    test('shows pied patches and clearbody separation', () {
      final pied = BudgieColorResolver.resolve(
        visualMutations: const ['dominant_pied'],
        phenotype: 'Dominant Pied Light Green',
      );
      final dominantClearbody = BudgieColorResolver.resolve(
        visualMutations: const ['blue', 'dominant_clearbody'],
        phenotype: 'Dominant Clearbody Skyblue',
      );
      final texasClearbody = BudgieColorResolver.resolve(
        visualMutations: const ['blue', 'texas_clearbody'],
        phenotype: 'Skyblue Texas Clearbody',
      );

      expect(pied.showPiedPatch, isTrue);
      expect(dominantClearbody.bodyColor, isNot(texasClearbody.bodyColor));
      expect(
        dominantClearbody.bodyColor.computeLuminance(),
        lessThan(texasClearbody.bodyColor.computeLuminance()),
      );
      expect(
        dominantClearbody.cheekPatchColor,
        BudgiePhenotypePalette.cheekSmokeGrey,
      );
      expect(
        dominantClearbody.wingMarkingColor,
        BudgiePhenotypePalette.wingBlack,
      );
      expect(texasClearbody.hideWingMarkings, isFalse);
      expect(texasClearbody.bodyColor, isNot(BudgiePhenotypePalette.skyBlue));
      expect(
        texasClearbody.wingMarkingColor,
        BudgiePhenotypePalette.wingBlack,
      );
      expect(
        texasClearbody.cheekPatchColor,
        BudgiePhenotypePalette.cheekViolet,
      );
    });

    test('uses smoky grey cheek patches for dominant clearbody', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: const ['blue', 'dominant_clearbody'],
        phenotype: 'Dominant Clearbody Skyblue',
      );

      expect(appearance.cheekPatchColor, BudgiePhenotypePalette.cheekSmokeGrey);
      expect(appearance.wingMarkingColor, BudgiePhenotypePalette.wingBlack);
    });

    test('blackface darkens the mask area', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: const ['blackface'],
        phenotype: 'Blackface Light Green',
      );

      expect(appearance.maskColor, BudgiePhenotypePalette.wingBlack);
    });

    test(
      'uses carrier accent for split birds without changing phenotype body',
      () {
        final appearance = BudgieColorResolver.resolve(
          visualMutations: const [],
          carriedMutations: const ['blue'],
          phenotype: 'Normal',
        );

        expect(appearance.bodyColor, BudgiePhenotypePalette.lightGreen);
        expect(appearance.showCarrierAccent, isTrue);
        expect(appearance.carrierAccentColor, BudgiePhenotypePalette.skyBlue);
      },
    );
  });
}
