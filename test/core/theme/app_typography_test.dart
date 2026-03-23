import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/theme/app_typography.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';

void main() {
  group('AppTypography.textTheme — light mode', () {
    late TextTheme textTheme;

    setUp(() {
      textTheme = AppTypography.textTheme(Brightness.light);
    });

    test('returns a TextTheme', () {
      expect(textTheme, isA<TextTheme>());
    });

    group('display styles', () {
      test('displayLarge has fontSize 32', () {
        expect(textTheme.displayLarge?.fontSize, 32);
      });

      test('displayLarge has bold fontWeight', () {
        expect(textTheme.displayLarge?.fontWeight, FontWeight.bold);
      });

      test('displayMedium has fontSize 28', () {
        expect(textTheme.displayMedium?.fontSize, 28);
      });

      test('displayMedium has bold fontWeight', () {
        expect(textTheme.displayMedium?.fontWeight, FontWeight.bold);
      });
    });

    group('headline styles', () {
      test('headlineLarge has fontSize 24', () {
        expect(textTheme.headlineLarge?.fontSize, 24);
      });

      test('headlineLarge has w600 fontWeight', () {
        expect(textTheme.headlineLarge?.fontWeight, FontWeight.w600);
      });

      test('headlineMedium has fontSize 20', () {
        expect(textTheme.headlineMedium?.fontSize, 20);
      });

      test('headlineMedium has w600 fontWeight', () {
        expect(textTheme.headlineMedium?.fontWeight, FontWeight.w600);
      });
    });

    group('title styles', () {
      test('titleLarge has fontSize 18', () {
        expect(textTheme.titleLarge?.fontSize, 18);
      });

      test('titleLarge has w600 fontWeight', () {
        expect(textTheme.titleLarge?.fontWeight, FontWeight.w600);
      });

      test('titleMedium has fontSize 16', () {
        expect(textTheme.titleMedium?.fontSize, 16);
      });

      test('titleMedium has w500 fontWeight', () {
        expect(textTheme.titleMedium?.fontWeight, FontWeight.w500);
      });
    });

    group('body styles', () {
      test('bodyLarge has fontSize 16', () {
        expect(textTheme.bodyLarge?.fontSize, 16);
      });

      test('bodyMedium has fontSize 14', () {
        expect(textTheme.bodyMedium?.fontSize, 14);
      });

      test('bodySmall has fontSize 12', () {
        expect(textTheme.bodySmall?.fontSize, 12);
      });
    });

    group('label styles', () {
      test('labelLarge has fontSize 14', () {
        expect(textTheme.labelLarge?.fontSize, 14);
      });

      test('labelLarge has w500 fontWeight', () {
        expect(textTheme.labelLarge?.fontWeight, FontWeight.w500);
      });
    });

    group('light mode colors', () {
      test('displayLarge uses neutral900 color', () {
        expect(textTheme.displayLarge?.color, AppColors.neutral900);
      });

      test('bodyMedium uses neutral900 color', () {
        expect(textTheme.bodyMedium?.color, AppColors.neutral900);
      });

      test('bodySmall has reduced alpha for subdued appearance', () {
        final bodySmallColor = textTheme.bodySmall?.color;
        expect(bodySmallColor, isNotNull);
        // bodySmall uses withValues(alpha: 0.7) of neutral900
        expect(bodySmallColor!.a, closeTo(0.7, 0.01));
      });
    });
  });

  group('AppTypography.textTheme — dark mode', () {
    late TextTheme textTheme;

    setUp(() {
      textTheme = AppTypography.textTheme(Brightness.dark);
    });

    test('returns a TextTheme', () {
      expect(textTheme, isA<TextTheme>());
    });

    group('dark mode colors', () {
      test('displayLarge uses neutral50 color', () {
        expect(textTheme.displayLarge?.color, AppColors.neutral50);
      });

      test('bodyMedium uses neutral50 color', () {
        expect(textTheme.bodyMedium?.color, AppColors.neutral50);
      });

      test('bodySmall has reduced alpha for subdued appearance', () {
        final bodySmallColor = textTheme.bodySmall?.color;
        expect(bodySmallColor, isNotNull);
        expect(bodySmallColor!.a, closeTo(0.7, 0.01));
      });
    });

    group('font sizes match light mode', () {
      test('displayLarge fontSize matches light', () {
        final light = AppTypography.textTheme(Brightness.light);
        expect(textTheme.displayLarge?.fontSize, light.displayLarge?.fontSize);
      });

      test('bodyMedium fontSize matches light', () {
        final light = AppTypography.textTheme(Brightness.light);
        expect(textTheme.bodyMedium?.fontSize, light.bodyMedium?.fontSize);
      });

      test('titleLarge fontSize matches light', () {
        final light = AppTypography.textTheme(Brightness.light);
        expect(textTheme.titleLarge?.fontSize, light.titleLarge?.fontSize);
      });
    });
  });

  group('AppTypography — font size hierarchy', () {
    late TextTheme textTheme;

    setUp(() {
      textTheme = AppTypography.textTheme(Brightness.light);
    });

    test('display > headline > title > body > bodySmall', () {
      expect(
        textTheme.displayLarge!.fontSize!,
        greaterThan(textTheme.headlineLarge!.fontSize!),
      );
      expect(
        textTheme.headlineLarge!.fontSize!,
        greaterThan(textTheme.titleLarge!.fontSize!),
      );
      expect(
        textTheme.titleLarge!.fontSize!,
        greaterThan(textTheme.bodyMedium!.fontSize!),
      );
      expect(
        textTheme.bodyMedium!.fontSize!,
        greaterThan(textTheme.bodySmall!.fontSize!),
      );
    });

    test('displayLarge > displayMedium', () {
      expect(
        textTheme.displayLarge!.fontSize!,
        greaterThan(textTheme.displayMedium!.fontSize!),
      );
    });

    test('headlineLarge > headlineMedium', () {
      expect(
        textTheme.headlineLarge!.fontSize!,
        greaterThan(textTheme.headlineMedium!.fontSize!),
      );
    });

    test('titleLarge > titleMedium', () {
      expect(
        textTheme.titleLarge!.fontSize!,
        greaterThan(textTheme.titleMedium!.fontSize!),
      );
    });

    test('bodyLarge > bodyMedium > bodySmall', () {
      expect(
        textTheme.bodyLarge!.fontSize!,
        greaterThan(textTheme.bodyMedium!.fontSize!),
      );
      expect(
        textTheme.bodyMedium!.fontSize!,
        greaterThan(textTheme.bodySmall!.fontSize!),
      );
    });
  });

  group('AppTypography — all defined styles are non-null', () {
    for (final brightness in Brightness.values) {
      test('all styles defined for ${brightness.name}', () {
        final textTheme = AppTypography.textTheme(brightness);
        expect(textTheme.displayLarge, isNotNull);
        expect(textTheme.displayMedium, isNotNull);
        expect(textTheme.headlineLarge, isNotNull);
        expect(textTheme.headlineMedium, isNotNull);
        expect(textTheme.titleLarge, isNotNull);
        expect(textTheme.titleMedium, isNotNull);
        expect(textTheme.bodyLarge, isNotNull);
        expect(textTheme.bodyMedium, isNotNull);
        expect(textTheme.bodySmall, isNotNull);
        expect(textTheme.labelLarge, isNotNull);
      });
    }
  });

  group('AppTypography — light vs dark use different base colors', () {
    test('light uses neutral900, dark uses neutral50 for main text', () {
      final light = AppTypography.textTheme(Brightness.light);
      final dark = AppTypography.textTheme(Brightness.dark);

      expect(light.displayLarge?.color, isNot(dark.displayLarge?.color));
      expect(light.bodyMedium?.color, isNot(dark.bodyMedium?.color));
    });
  });
}
