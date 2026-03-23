import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/budgie_color_resolver.dart';

void main() {
  group('anatomy detail resolution', () {
    test('normal green has black eyes with white ring', () {
      final result = BudgieColorResolver.resolve(
        visualMutations: [],
        phenotype: 'Light Green',
      );
      expect(result.eyeColor, equals(const Color(0xFF1A1A1A)));
      expect(result.eyeRingColor, equals(const Color(0xFFF0F0F0)));
      expect(result.showEyeRing, isTrue);
    });

    test('ino has red eyes with pink ring', () {
      final result = BudgieColorResolver.resolve(
        visualMutations: ['ino'],
        phenotype: 'Lutino',
      );
      expect(result.eyeColor, equals(const Color(0xFFCC2233)));
      expect(result.showEyeRing, isTrue);
    });

    test('albino has red eyes', () {
      final result = BudgieColorResolver.resolve(
        visualMutations: ['ino', 'blue'],
        phenotype: 'Albino',
      );
      expect(result.eyeColor, equals(const Color(0xFFCC2233)));
    });

    test('english fallow has bright red eyes and no iris ring', () {
      final result = BudgieColorResolver.resolve(
        visualMutations: ['fallow_english'],
        phenotype: 'English Fallow Light Green',
      );
      expect(result.eyeColor, equals(const Color(0xFFCC2838)));
      expect(result.showEyeRing, isFalse);
    });

    test('recessive pied has no eye ring', () {
      final result = BudgieColorResolver.resolve(
        visualMutations: ['recessive_pied'],
        phenotype: 'Recessive Pied Light Green',
      );
      expect(result.showEyeRing, isFalse);
    });

    test('normal has throat spots', () {
      final result = BudgieColorResolver.resolve(
        visualMutations: [],
        phenotype: 'Light Green',
      );
      expect(result.showThroatSpots, isTrue);
      expect(result.throatSpotCount, equals(6));
    });

    test('ino has no throat spots', () {
      final result = BudgieColorResolver.resolve(
        visualMutations: ['ino'],
        phenotype: 'Lutino',
      );
      expect(result.showThroatSpots, isFalse);
    });

    test('opaline has reduced throat spots', () {
      final result = BudgieColorResolver.resolve(
        visualMutations: ['opaline'],
        phenotype: 'Opaline Light Green',
      );
      expect(result.showThroatSpots, isTrue);
      expect(result.throatSpotCount, equals(4));
    });

    test('cinnamon has brown throat spots', () {
      final result = BudgieColorResolver.resolve(
        visualMutations: ['cinnamon'],
        phenotype: 'Cinnamon Light Green',
      );
      expect(
        result.throatSpotColor,
        equals(BudgiePhenotypePalette.cinnamon),
      );
    });

    test('blue series has dark blue tail', () {
      final result = BudgieColorResolver.resolve(
        visualMutations: ['blue'],
        phenotype: 'Skyblue',
      );
      expect(result.tailColor, equals(const Color(0xFF2B3F6F)));
    });

    test('green series has dark blue-green tail', () {
      final result = BudgieColorResolver.resolve(
        visualMutations: [],
        phenotype: 'Light Green',
      );
      expect(result.tailColor, equals(const Color(0xFF2B4F6F)));
    });

    test('cinnamon has brown tail', () {
      final result = BudgieColorResolver.resolve(
        visualMutations: ['cinnamon'],
        phenotype: 'Cinnamon Light Green',
      );
      expect(result.tailColor, equals(const Color(0xFF6B5040)));
    });

    test('normal back color defaults to body', () {
      final result = BudgieColorResolver.resolve(
        visualMutations: [],
        phenotype: 'Light Green',
      );
      expect(result.backColor, isNull);
      expect(result.effectiveBackColor, equals(result.bodyColor));
    });

    test('opaline back color matches body', () {
      final result = BudgieColorResolver.resolve(
        visualMutations: ['opaline'],
        phenotype: 'Opaline Light Green',
      );
      expect(result.effectiveBackColor, equals(result.bodyColor));
    });

    test('german fallow has dark ruby eye with iris ring', () {
      final result = BudgieColorResolver.resolve(
        visualMutations: ['fallow_german'],
        phenotype: 'German Fallow Light Green',
      );
      expect(result.eyeColor, equals(const Color(0xFFA82030)));
      expect(result.showEyeRing, isTrue);
    });

    test('dark-eyed clear has no eye ring', () {
      final result = BudgieColorResolver.resolve(
        visualMutations: ['recessive_pied', 'clearflight_pied'],
        phenotype: 'Dark-Eyed Clear Light Green',
      );
      expect(result.showEyeRing, isFalse);
    });

    test('texas clearbody back color is a lightened body color', () {
      final result = BudgieColorResolver.resolve(
        visualMutations: ['texas_clearbody'],
        phenotype: 'Texas Clearbody Light Green',
      );
      expect(result.backColor, isNotNull);
    });

    test('fallow beak color is warm orange', () {
      final result = BudgieColorResolver.resolve(
        visualMutations: ['fallow_english'],
        phenotype: 'English Fallow Light Green',
      );
      expect(result.beakColor, equals(const Color(0xFFE89830)));
    });

    test('lutino tail uses yellow mask tint', () {
      final result = BudgieColorResolver.resolve(
        visualMutations: ['ino'],
        phenotype: 'Lutino',
      );
      expect(result.tailColor.a, closeTo(0.20, 0.02));
    });
  });
}
