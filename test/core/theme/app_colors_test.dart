import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';

void main() {
  group('AppColors — primary palette', () {
    test('primary is Color instance', () {
      expect(AppColors.primary, isA<Color>());
    });

    test('primaryLight is Color instance', () {
      expect(AppColors.primaryLight, isA<Color>());
    });

    test('primaryDark is Color instance', () {
      expect(AppColors.primaryDark, isA<Color>());
    });

    test('primary has expected hex value', () {
      expect(AppColors.primary, const Color(0xFF1E40AF));
    });

    test('primaryDark is darker than primaryLight', () {
      expect(
        AppColors.primaryDark.computeLuminance(),
        lessThan(AppColors.primaryLight.computeLuminance()),
      );
    });
  });

  group('AppColors — semantic colors', () {
    test('success is a Color', () => expect(AppColors.success, isA<Color>()));
    test('warning is a Color', () => expect(AppColors.warning, isA<Color>()));
    test('error is a Color', () => expect(AppColors.error, isA<Color>()));
    test('info is a Color', () => expect(AppColors.info, isA<Color>()));

    test('success has expected hex value', () {
      expect(AppColors.success, const Color(0xFF22C55E));
    });

    test('error has expected hex value', () {
      expect(AppColors.error, const Color(0xFFEF4444));
    });

    test('warning has expected hex value', () {
      expect(AppColors.warning, const Color(0xFFF59E0B));
    });
  });

  group('AppColors — neutral scale', () {
    test('neutral50 is the lightest neutral', () {
      expect(
        AppColors.neutral50.computeLuminance(),
        greaterThan(AppColors.neutral900.computeLuminance()),
      );
    });

    test('neutral950 is very dark', () {
      expect(AppColors.neutral950.computeLuminance(), lessThan(0.01));
    });

    test('neutral scale is ordered (50 → 950 descending luminance)', () {
      final scale = [
        AppColors.neutral50,
        AppColors.neutral100,
        AppColors.neutral200,
        AppColors.neutral300,
        AppColors.neutral400,
        AppColors.neutral500,
        AppColors.neutral600,
        AppColors.neutral700,
        AppColors.neutral800,
        AppColors.neutral900,
        AppColors.neutral950,
      ];
      for (var i = 0; i < scale.length - 1; i++) {
        expect(
          scale[i].computeLuminance(),
          greaterThanOrEqualTo(scale[i + 1].computeLuminance()),
          reason: 'neutral step $i should be lighter than step ${i + 1}',
        );
      }
    });
  });

  group('AppColors — gender colors', () {
    test('genderMale is a Color', () {
      expect(AppColors.genderMale, isA<Color>());
    });

    test('genderFemale is a Color', () {
      expect(AppColors.genderFemale, isA<Color>());
    });

    test('genderUnknown is a Color', () {
      expect(AppColors.genderUnknown, isA<Color>());
    });

    test('genderMale and genderFemale are visually distinct', () {
      expect(AppColors.genderMale, isNot(equals(AppColors.genderFemale)));
    });
  });

  group('AppColors — premium colors', () {
    test('premiumGold is a Color', () {
      expect(AppColors.premiumGold, isA<Color>());
    });

    test('premiumGradient is a LinearGradient', () {
      expect(AppColors.premiumGradient, isA<LinearGradient>());
    });

    test('premiumGradientDiagonal has topLeft to bottomRight orientation', () {
      expect(AppColors.premiumGradientDiagonal.begin, Alignment.topLeft);
      expect(AppColors.premiumGradientDiagonal.end, Alignment.bottomRight);
    });
  });

  group('AppColors — isLightColor helper', () {
    test('returns true for very light colors', () {
      // White (luminance = 1.0)
      expect(AppColors.isLightColor(Colors.white), isTrue);
    });

    test('returns false for dark colors', () {
      // Black (luminance = 0.0)
      expect(AppColors.isLightColor(Colors.black), isFalse);
    });

    test('returns true for albino phenotype color (very light)', () {
      expect(AppColors.isLightColor(AppColors.phenotypeAlbino), isTrue);
    });
  });

  group('AppColors — statusColor helper', () {
    testWidgets('alive returns success color', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppColors.statusColor(context, 'alive');
              return const SizedBox();
            },
          ),
        ),
      );
      expect(result, AppColors.success);
    });

    testWidgets('dead returns error color', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppColors.statusColor(context, 'dead');
              return const SizedBox();
            },
          ),
        ),
      );
      expect(result, AppColors.error);
    });

    testWidgets('sold returns warning color', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppColors.statusColor(context, 'sold');
              return const SizedBox();
            },
          ),
        ),
      );
      expect(result, AppColors.warning);
    });

    testWidgets('unknown status returns neutral400', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppColors.statusColor(context, 'unknown_status');
              return const SizedBox();
            },
          ),
        ),
      );
      expect(result, AppColors.neutral400);
    });
  });

  group('AppColors — alleleStateColor helper', () {
    testWidgets('visual returns alleleVisual in light theme', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              result = AppColors.alleleStateColor(context, 'visual');
              return const SizedBox();
            },
          ),
        ),
      );
      expect(result, AppColors.alleleVisual);
    });

    testWidgets('carrier returns alleleCarrier in light theme', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              result = AppColors.alleleStateColor(context, 'carrier');
              return const SizedBox();
            },
          ),
        ),
      );
      expect(result, AppColors.alleleCarrier);
    });

    testWidgets('unknown state returns neutral400', (tester) async {
      late Color result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              result = AppColors.alleleStateColor(context, 'nonexistent');
              return const SizedBox();
            },
          ),
        ),
      );
      expect(result, AppColors.neutral400);
    });
  });

  group('AppColors — bird-themed colors', () {
    test('budgieGreen matches success color', () {
      expect(AppColors.budgieGreen, AppColors.success);
    });

    test('all bird phenotype colors are Colors', () {
      final phenotypes = [
        AppColors.phenotypeAlbino,
        AppColors.phenotypeLutino,
        AppColors.phenotypeCinnamon,
        AppColors.phenotypeOpaline,
        AppColors.phenotypeSpangle,
        AppColors.phenotypePied,
        AppColors.phenotypeViolet,
        AppColors.phenotypeGrey,
      ];
      for (final color in phenotypes) {
        expect(color, isA<Color>());
      }
    });
  });
}
