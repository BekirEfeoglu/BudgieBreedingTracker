import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/genetics/utils/budgie_color_resolver.dart';

void main() {
  group('BudgieColorResolver edge cases', () {
    test('handles empty mutations and empty phenotype gracefully', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: const [],
        phenotype: '',
      );

      expect(appearance.bodyColor, BudgiePhenotypePalette.lightGreen);
      expect(appearance.maskColor, BudgiePhenotypePalette.maskYellow);
      expect(appearance.showCarrierAccent, isFalse);
      expect(appearance.showPiedPatch, isFalse);
    });

    test('handles unknown mutation IDs without crashing', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: const ['nonexistent_mutation', 'another_fake'],
        phenotype: 'Normal',
      );

      // Should fall back to default green series
      expect(appearance.bodyColor, BudgiePhenotypePalette.lightGreen);
      expect(appearance.maskColor, BudgiePhenotypePalette.maskYellow);
    });

    test('handles phenotype with only whitespace', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: const ['blue'],
        phenotype: '   ',
      );

      // Should resolve based on mutation IDs alone
      expect(appearance.bodyColor, BudgiePhenotypePalette.skyBlue);
      expect(appearance.maskColor, BudgiePhenotypePalette.maskWhite);
    });

    test('handles case-insensitive mutation IDs', () {
      final upper = BudgieColorResolver.resolve(
        visualMutations: const ['BLUE', 'OPALINE'],
        phenotype: 'Skyblue Opaline',
      );
      final lower = BudgieColorResolver.resolve(
        visualMutations: const ['blue', 'opaline'],
        phenotype: 'Skyblue Opaline',
      );

      expect(upper.bodyColor, lower.bodyColor);
      expect(upper.maskColor, lower.maskColor);
      expect(upper.showMantleHighlight, lower.showMantleHighlight);
    });

    test('handles duplicate mutation IDs', () {
      final single = BudgieColorResolver.resolve(
        visualMutations: const ['blue'],
        phenotype: 'Skyblue',
      );
      final duplicate = BudgieColorResolver.resolve(
        visualMutations: const ['blue', 'blue', 'blue'],
        phenotype: 'Skyblue',
      );

      expect(single.bodyColor, duplicate.bodyColor);
      expect(single.maskColor, duplicate.maskColor);
    });

    test(
      'resolves complex multi-mutation combination: cinnamon + spangle + blue',
      () {
        final appearance = BudgieColorResolver.resolve(
          visualMutations: const ['blue', 'cinnamon', 'spangle'],
          phenotype: 'Skyblue Cinnamon Spangle',
        );

        // Cinnamon should affect body color
        expect(appearance.bodyColor, isNot(BudgiePhenotypePalette.skyBlue));
        // Spangle should create wing fill
        expect(appearance.wingFillColor, isNot(Colors.transparent));
        expect(appearance.maskColor, BudgiePhenotypePalette.maskWhite);
      },
    );

    test('resolves 4+ mutation combination without error', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: const [
          'blue',
          'opaline',
          'cinnamon',
          'spangle',
          'violet',
        ],
        phenotype: 'Visual Violet Opaline Cinnamon Spangle',
      );

      expect(appearance.showMantleHighlight, isTrue);
      expect(appearance.wingFillColor, isNot(Colors.transparent));
      expect(appearance.maskColor, BudgiePhenotypePalette.maskWhite);
    });

    test('carrier accent resolves correctly for multiple carried mutations', () {
      // First carried mutation wins (priority order: anthracite > slate > violet > ...)
      final appearance = BudgieColorResolver.resolve(
        visualMutations: const [],
        carriedMutations: const ['violet', 'blue'],
        phenotype: 'Normal',
      );

      expect(appearance.showCarrierAccent, isTrue);
      expect(appearance.carrierAccentColor, BudgiePhenotypePalette.violet);
    });

    test('carrier mutations do not affect body or mask color', () {
      final withoutCarrier = BudgieColorResolver.resolve(
        visualMutations: const [],
        phenotype: 'Normal',
      );
      final withCarrier = BudgieColorResolver.resolve(
        visualMutations: const [],
        carriedMutations: const ['blue', 'ino', 'cinnamon'],
        phenotype: 'Normal',
      );

      expect(withCarrier.bodyColor, withoutCarrier.bodyColor);
      expect(withCarrier.maskColor, withoutCarrier.maskColor);
      expect(withCarrier.wingMarkingColor, withoutCarrier.wingMarkingColor);
    });

    test('unknown carrier mutation IDs result in fallback accent', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: const [],
        carriedMutations: const ['totally_unknown_mutation'],
        phenotype: 'Normal',
      );

      expect(appearance.showCarrierAccent, isTrue);
      // Unknown mutations get normalized then fallback to cheekBlue
      expect(appearance.carrierAccentColor, BudgiePhenotypePalette.cheekBlue);
    });

    test('lacewing produces visible wing markings (not hidden)', () {
      final lacewing = BudgieColorResolver.resolve(
        visualMutations: const ['ino', 'cinnamon'],
        phenotype: 'Lacewing',
      );

      expect(lacewing.hideWingMarkings, isFalse);
      expect(lacewing.wingMarkingColor, BudgiePhenotypePalette.cinnamon);
    });

    test('dark-eyed clear hides wing markings and disables mantle', () {
      final dec = BudgieColorResolver.resolve(
        visualMutations: const ['recessive_pied', 'clearflight_pied'],
        phenotype: 'Dark-Eyed Clear Light Green',
      );

      expect(dec.hideWingMarkings, isTrue);
      expect(dec.showMantleHighlight, isFalse);
      expect(dec.wingMarkingColor, Colors.transparent);
      expect(dec.bodyColor, BudgiePhenotypePalette.maskYellow);
    });

    test('english fallow uses taupe wing markings', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: const ['fallow_english'],
        phenotype: 'Light Green English Fallow',
      );

      expect(appearance.wingMarkingColor, BudgiePhenotypePalette.fallowTaupe);
      // Body should be lightened towards warm ivory
      expect(appearance.bodyColor, isNot(BudgiePhenotypePalette.lightGreen));
    });

    test('saddleback enables mantle highlight', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: const ['saddleback'],
        phenotype: 'Light Green Saddleback',
      );

      expect(appearance.showMantleHighlight, isTrue);
    });

    test('clearflight pied adds wing fill overlay', () {
      final appearance = BudgieColorResolver.resolve(
        visualMutations: const ['clearflight_pied'],
        phenotype: 'Clearflight Pied Light Green',
      );

      expect(appearance.showPiedPatch, isTrue);
      expect(appearance.wingFillColor, isNot(Colors.transparent));
    });

    test('dilute produces softer wing markings and lighter body', () {
      final normal = BudgieColorResolver.resolve(
        visualMutations: const ['blue'],
        phenotype: 'Skyblue',
      );
      final dilute = BudgieColorResolver.resolve(
        visualMutations: const ['blue', 'dilute'],
        phenotype: 'Skyblue Dilute',
      );

      expect(dilute.wingMarkingColor, BudgiePhenotypePalette.wingSoftGrey);
      expect(
        dilute.bodyColor.computeLuminance(),
        greaterThan(normal.bodyColor.computeLuminance()),
      );
    });
  });
}
