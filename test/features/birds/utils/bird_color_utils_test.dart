import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/features/birds/utils/bird_color_utils.dart';

void main() {
  group('birdColorLabel', () {
    test('returns non-empty label for all BirdColor values', () {
      for (final color in BirdColor.values) {
        expect(birdColorLabel(color), isNotEmpty);
      }
    });
  });

  group('birdColorToColor', () {
    test('maps selected colors to expected values', () {
      expect(birdColorToColor(BirdColor.green), const Color(0xFF4CAF50));
      expect(birdColorToColor(BirdColor.blue), const Color(0xFF2196F3));
      expect(birdColorToColor(BirdColor.albino), const Color(0xFFFFFFFF));
      expect(birdColorToColor(BirdColor.other), const Color(0xFFFF9800));
    });
  });
}
