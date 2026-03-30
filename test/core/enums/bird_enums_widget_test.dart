import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';

void main() {
  group('speciesIconWidget', () {
    test('returns AppIcon with correct asset for each Species value', () {
      final expected = {
        Species.budgie: AppIcons.budgie,
        Species.canary: AppIcons.canary,
        Species.cockatiel: AppIcons.cockatiel,
        Species.finch: AppIcons.finch,
        Species.other: AppIcons.birdOther,
        Species.unknown: AppIcons.birdOther,
      };

      for (final entry in expected.entries) {
        final widget = speciesIconWidget(entry.key);
        expect(widget, isA<AppIcon>());
        final appIcon = widget as AppIcon;
        expect(
          appIcon.asset,
          entry.value,
          reason: '${entry.key} should map to ${entry.value}',
        );
      }
    });

    test('passes size parameter correctly', () {
      final widget = speciesIconWidget(Species.budgie, size: 32);
      expect(widget, isA<AppIcon>());
      expect((widget as AppIcon).size, 32);
    });

    test('passes color parameter correctly', () {
      const testColor = Colors.red;
      final widget = speciesIconWidget(Species.canary, color: testColor);
      expect(widget, isA<AppIcon>());
      expect((widget as AppIcon).color, testColor);
    });

    test('returns null size and color when not provided', () {
      final widget = speciesIconWidget(Species.finch);
      expect(widget, isA<AppIcon>());
      final appIcon = widget as AppIcon;
      expect(appIcon.size, isNull);
      expect(appIcon.color, isNull);
    });

    test('covers all Species values', () {
      for (final species in Species.values) {
        final widget = speciesIconWidget(species);
        expect(
          widget,
          isA<AppIcon>(),
          reason: '$species should return AppIcon',
        );
      }
    });
  });
}
