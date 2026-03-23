import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/genetics/utils/budgie_color_resolver.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/budgie_painter.dart';

void main() {
  const defaultAppearance = BudgieColorAppearance(
    bodyColor: Color(0xFF8CD600),
    maskColor: Color(0xFFF3DF63),
    wingMarkingColor: Color(0xFF2F3138),
    wingFillColor: Colors.transparent,
    cheekPatchColor: Color(0xFF3D76C3),
    piedPatchColor: Color(0xFFF3DF63),
    carrierAccentColor: Colors.transparent,
    showPiedPatch: false,
    showMantleHighlight: false,
    showCarrierAccent: false,
    hideWingMarkings: false,
  );

  group('BudgiePainter', () {
    test('shouldRepaint returns false for equal appearances', () {
      const p1 = BudgiePainter(appearance: defaultAppearance);
      const p2 = BudgiePainter(appearance: defaultAppearance);
      expect(p1.shouldRepaint(p2), isFalse);
    });

    test('shouldRepaint returns true for different appearances', () {
      const p1 = BudgiePainter(appearance: defaultAppearance);
      const p2 = BudgiePainter(
        appearance: BudgieColorAppearance(
          bodyColor: Color(0xFF72D1DD),
          maskColor: Color(0xFFF4F7FA),
          wingMarkingColor: Color(0xFF2F3138),
          wingFillColor: Colors.transparent,
          cheekPatchColor: Color(0xFF7A78C7),
          piedPatchColor: Color(0xFFF4F7FA),
          carrierAccentColor: Colors.transparent,
          showPiedPatch: false,
          showMantleHighlight: false,
          showCarrierAccent: false,
          hideWingMarkings: false,
        ),
      );
      expect(p1.shouldRepaint(p2), isTrue);
    });

    test('paint does not throw for default appearance', () {
      const painter = BudgiePainter(appearance: defaultAppearance);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(
        () => painter.paint(canvas, const Size(60, 80)),
        returnsNormally,
      );
    });

    test('paint does not throw with all optional features enabled', () {
      const painter = BudgiePainter(
        appearance: BudgieColorAppearance(
          bodyColor: Color(0xFF8CD600),
          maskColor: Color(0xFFF3DF63),
          wingMarkingColor: Color(0xFF2F3138),
          wingFillColor: Color(0xFF5C6168),
          cheekPatchColor: Color(0xFF3D76C3),
          piedPatchColor: Color(0xFFF3DF63),
          carrierAccentColor: Color(0xFF72D1DD),
          showPiedPatch: true,
          showMantleHighlight: true,
          showCarrierAccent: true,
          hideWingMarkings: false,
          showThroatSpots: true,
          throatSpotCount: 6,
          showEyeRing: true,
        ),
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(
        () => painter.paint(canvas, const Size(60, 80)),
        returnsNormally,
      );
    });

    test('paint does not throw for ino (hidden elements)', () {
      const painter = BudgiePainter(
        appearance: BudgieColorAppearance(
          bodyColor: Color(0xFFF4DF57),
          maskColor: Color(0xFFF3DF63),
          wingMarkingColor: Colors.transparent,
          wingFillColor: Colors.transparent,
          cheekPatchColor: Color(0xFFF4F7FA),
          piedPatchColor: Color(0xFFF3DF63),
          carrierAccentColor: Colors.transparent,
          showPiedPatch: false,
          showMantleHighlight: false,
          showCarrierAccent: false,
          hideWingMarkings: true,
          showThroatSpots: false,
          throatSpotCount: 0,
          eyeColor: Color(0xFFCC2233),
          showEyeRing: false,
        ),
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(
        () => painter.paint(canvas, const Size(60, 80)),
        returnsNormally,
      );
    });

    test('paint does not throw at minimum size', () {
      const painter = BudgiePainter(appearance: defaultAppearance);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(
        () => painter.paint(canvas, const Size(36, 48)),
        returnsNormally,
      );
    });

    test('paint does not throw at large size', () {
      const painter = BudgiePainter(appearance: defaultAppearance);
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(
        () => painter.paint(canvas, const Size(300, 400)),
        returnsNormally,
      );
    });

    test('shouldRepaint detects showPiedPatch change', () {
      const p1 = BudgiePainter(appearance: defaultAppearance);
      final p2 = BudgiePainter(
        appearance: BudgieColorAppearance(
          bodyColor: defaultAppearance.bodyColor,
          maskColor: defaultAppearance.maskColor,
          wingMarkingColor: defaultAppearance.wingMarkingColor,
          wingFillColor: defaultAppearance.wingFillColor,
          cheekPatchColor: defaultAppearance.cheekPatchColor,
          piedPatchColor: defaultAppearance.piedPatchColor,
          carrierAccentColor: defaultAppearance.carrierAccentColor,
          showPiedPatch: true,
          showMantleHighlight: false,
          showCarrierAccent: false,
          hideWingMarkings: false,
        ),
      );
      expect(p1.shouldRepaint(p2), isTrue);
    });

    test('shouldRepaint detects throatSpotCount change', () {
      const p1 = BudgiePainter(appearance: defaultAppearance);
      final p2 = BudgiePainter(
        appearance: BudgieColorAppearance(
          bodyColor: defaultAppearance.bodyColor,
          maskColor: defaultAppearance.maskColor,
          wingMarkingColor: defaultAppearance.wingMarkingColor,
          wingFillColor: defaultAppearance.wingFillColor,
          cheekPatchColor: defaultAppearance.cheekPatchColor,
          piedPatchColor: defaultAppearance.piedPatchColor,
          carrierAccentColor: defaultAppearance.carrierAccentColor,
          showPiedPatch: false,
          showMantleHighlight: false,
          showCarrierAccent: false,
          hideWingMarkings: false,
          throatSpotCount: 4,
        ),
      );
      expect(p1.shouldRepaint(p2), isTrue);
    });

    test('paint handles zero throat spot count gracefully', () {
      const painter = BudgiePainter(
        appearance: BudgieColorAppearance(
          bodyColor: Color(0xFF8CD600),
          maskColor: Color(0xFFF3DF63),
          wingMarkingColor: Color(0xFF2F3138),
          wingFillColor: Colors.transparent,
          cheekPatchColor: Color(0xFF3D76C3),
          piedPatchColor: Color(0xFFF3DF63),
          carrierAccentColor: Colors.transparent,
          showPiedPatch: false,
          showMantleHighlight: false,
          showCarrierAccent: false,
          hideWingMarkings: false,
          showThroatSpots: true,
          throatSpotCount: 0,
        ),
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(
        () => painter.paint(canvas, const Size(60, 80)),
        returnsNormally,
      );
    });
  });
}
