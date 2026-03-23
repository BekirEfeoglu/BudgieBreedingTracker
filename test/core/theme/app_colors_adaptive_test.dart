import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';

/// Helper to pump a widget tree with a specific brightness and capture a color.
Future<Color> _captureColor(
  WidgetTester tester,
  Brightness brightness,
  Color Function(BuildContext) colorFn,
) async {
  late Color captured;
  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.light
          ? ThemeData.light()
          : ThemeData.dark(),
      home: Builder(
        builder: (context) {
          captured = colorFn(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  group('alleleStateColor — light theme', () {
    testWidgets('visual returns alleleVisual', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.alleleStateColor(ctx, 'visual'),
      );
      expect(color, AppColors.alleleVisual);
    });

    testWidgets('carrier returns alleleCarrier', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.alleleStateColor(ctx, 'carrier'),
      );
      expect(color, AppColors.alleleCarrier);
    });

    testWidgets('split returns alleleSplit', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.alleleStateColor(ctx, 'split'),
      );
      expect(color, AppColors.alleleSplit);
    });

    testWidgets('unknown state returns neutral400', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.alleleStateColor(ctx, 'xyz'),
      );
      expect(color, AppColors.neutral400);
    });
  });

  group('alleleStateColor — dark theme', () {
    testWidgets('visual returns alleleVisualDark', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.dark,
        (ctx) => AppColors.alleleStateColor(ctx, 'visual'),
      );
      expect(color, AppColors.alleleVisualDark);
    });

    testWidgets('carrier returns alleleCarrierDark', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.dark,
        (ctx) => AppColors.alleleStateColor(ctx, 'carrier'),
      );
      expect(color, AppColors.alleleCarrierDark);
    });

    testWidgets('split returns alleleSplitDark', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.dark,
        (ctx) => AppColors.alleleStateColor(ctx, 'split'),
      );
      expect(color, AppColors.alleleSplitDark);
    });
  });

  group('alleleVisualAdaptive', () {
    testWidgets('light theme returns alleleVisual', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        AppColors.alleleVisualAdaptive,
      );
      expect(color, AppColors.alleleVisual);
    });

    testWidgets('dark theme returns alleleVisualDark', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.dark,
        AppColors.alleleVisualAdaptive,
      );
      expect(color, AppColors.alleleVisualDark);
    });
  });

  group('alleleCarrierAdaptive', () {
    testWidgets('light theme returns alleleCarrier', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        AppColors.alleleCarrierAdaptive,
      );
      expect(color, AppColors.alleleCarrier);
    });

    testWidgets('dark theme returns alleleCarrierDark', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.dark,
        AppColors.alleleCarrierAdaptive,
      );
      expect(color, AppColors.alleleCarrierDark);
    });
  });

  group('alleleSplitAdaptive', () {
    testWidgets('light theme returns alleleSplit', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        AppColors.alleleSplitAdaptive,
      );
      expect(color, AppColors.alleleSplit);
    });

    testWidgets('dark theme returns alleleSplitDark', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.dark,
        AppColors.alleleSplitAdaptive,
      );
      expect(color, AppColors.alleleSplitDark);
    });
  });

  group('inheritanceColor — light theme', () {
    testWidgets('autosomalRecessive returns correct color', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.inheritanceColor(ctx, 'autosomalRecessive'),
      );
      expect(color, AppColors.inheritAutosomalRecessive);
    });

    testWidgets('autosomalDominant returns correct color', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.inheritanceColor(ctx, 'autosomalDominant'),
      );
      expect(color, AppColors.inheritAutosomalDominant);
    });

    testWidgets('autosomalIncompleteDominant returns correct color', (
      tester,
    ) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.inheritanceColor(ctx, 'autosomalIncompleteDominant'),
      );
      expect(color, AppColors.inheritAutosomalIncompleteDominant);
    });

    testWidgets('sexLinkedRecessive returns correct color', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.inheritanceColor(ctx, 'sexLinkedRecessive'),
      );
      expect(color, AppColors.inheritSexLinkedRecessive);
    });

    testWidgets('sexLinkedCodominant returns correct color', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.inheritanceColor(ctx, 'sexLinkedCodominant'),
      );
      expect(color, AppColors.inheritSexLinkedCodominant);
    });

    testWidgets('unknown type returns neutral400', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.inheritanceColor(ctx, 'unknown'),
      );
      expect(color, AppColors.neutral400);
    });
  });

  group('inheritanceColor — dark theme', () {
    testWidgets('autosomalRecessive returns dark variant', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.dark,
        (ctx) => AppColors.inheritanceColor(ctx, 'autosomalRecessive'),
      );
      expect(color, AppColors.inheritAutosomalRecessiveDark);
    });

    testWidgets('autosomalDominant returns dark variant', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.dark,
        (ctx) => AppColors.inheritanceColor(ctx, 'autosomalDominant'),
      );
      expect(color, AppColors.inheritAutosomalDominantDark);
    });

    testWidgets('sexLinkedCodominant returns dark variant', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.dark,
        (ctx) => AppColors.inheritanceColor(ctx, 'sexLinkedCodominant'),
      );
      expect(color, AppColors.inheritSexLinkedCodominantDark);
    });
  });

  group('isLightColor', () {
    test('white is light (luminance > 0.85)', () {
      expect(AppColors.isLightColor(Colors.white), isTrue);
    });

    test('black is not light', () {
      expect(AppColors.isLightColor(Colors.black), isFalse);
    });

    test('phenotypeAlbino is light', () {
      expect(AppColors.isLightColor(AppColors.phenotypeAlbino), isTrue);
    });

    test('primaryDark is not light', () {
      expect(AppColors.isLightColor(AppColors.primaryDark), isFalse);
    });

    test('neutral950 is not light', () {
      expect(AppColors.isLightColor(AppColors.neutral950), isFalse);
    });
  });

  group('premiumOnGold', () {
    testWidgets('light theme returns premiumBadgeText', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        AppColors.premiumOnGold,
      );
      expect(color, AppColors.premiumBadgeText);
    });

    testWidgets('dark theme returns white', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.dark,
        AppColors.premiumOnGold,
      );
      expect(color, Colors.white);
    });
  });

  group('chartText', () {
    testWidgets('light theme returns onSurfaceVariant', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        AppColors.chartText,
      );
      expect(color, ThemeData.light().colorScheme.onSurfaceVariant);
    });

    testWidgets('dark theme returns onSurfaceVariant', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.dark,
        AppColors.chartText,
      );
      expect(color, ThemeData.dark().colorScheme.onSurfaceVariant);
    });
  });

  group('chartTitle', () {
    testWidgets('light theme returns black87', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        AppColors.chartTitle,
      );
      expect(color, Colors.black87);
    });

    testWidgets('dark theme returns white', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.dark,
        AppColors.chartTitle,
      );
      expect(color, Colors.white);
    });
  });

  group('overlay', () {
    testWidgets('light theme uses black with alpha', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        AppColors.overlay,
      );
      expect(color, Colors.black.withValues(alpha: 0.08));
    });

    testWidgets('dark theme uses white with alpha', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.dark,
        AppColors.overlay,
      );
      expect(color, Colors.white.withValues(alpha: 0.08));
    });
  });

  group('skeletonBase', () {
    testWidgets('light theme returns neutral300', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        AppColors.skeletonBase,
      );
      expect(color, AppColors.neutral300);
    });

    testWidgets('dark theme returns neutral800', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.dark,
        AppColors.skeletonBase,
      );
      expect(color, AppColors.neutral800);
    });
  });

  group('skeletonHighlight', () {
    testWidgets('light theme returns neutral100', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        AppColors.skeletonHighlight,
      );
      expect(color, AppColors.neutral100);
    });

    testWidgets('dark theme returns neutral700', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.dark,
        AppColors.skeletonHighlight,
      );
      expect(color, AppColors.neutral700);
    });
  });

  group('skeletonSurface', () {
    testWidgets('light theme returns white', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        AppColors.skeletonSurface,
      );
      expect(color, Colors.white);
    });

    testWidgets('dark theme returns neutral800', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.dark,
        AppColors.skeletonSurface,
      );
      expect(color, AppColors.neutral800);
    });
  });

  group('galleryBackground', () {
    testWidgets('light theme returns neutral900', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        AppColors.galleryBackground,
      );
      expect(color, AppColors.neutral900);
    });

    testWidgets('dark theme returns black', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.dark,
        AppColors.galleryBackground,
      );
      expect(color, Colors.black);
    });
  });

  group('statusColor', () {
    testWidgets('alive returns success', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.statusColor(ctx, 'alive'),
      );
      expect(color, AppColors.success);
    });

    testWidgets('active returns success', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.statusColor(ctx, 'active'),
      );
      expect(color, AppColors.success);
    });

    testWidgets('healthy returns success', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.statusColor(ctx, 'healthy'),
      );
      expect(color, AppColors.success);
    });

    testWidgets('completed returns success', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.statusColor(ctx, 'completed'),
      );
      expect(color, AppColors.success);
    });

    testWidgets('dead returns error', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.statusColor(ctx, 'dead'),
      );
      expect(color, AppColors.error);
    });

    testWidgets('deceased returns error', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.statusColor(ctx, 'deceased'),
      );
      expect(color, AppColors.error);
    });

    testWidgets('cancelled returns error', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.statusColor(ctx, 'cancelled'),
      );
      expect(color, AppColors.error);
    });

    testWidgets('error status returns error color', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.statusColor(ctx, 'error'),
      );
      expect(color, AppColors.error);
    });

    testWidgets('sold returns warning', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.statusColor(ctx, 'sold'),
      );
      expect(color, AppColors.warning);
    });

    testWidgets('pending returns warning', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.statusColor(ctx, 'pending'),
      );
      expect(color, AppColors.warning);
    });

    testWidgets('warning status returns warning color', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.statusColor(ctx, 'warning'),
      );
      expect(color, AppColors.warning);
    });

    testWidgets('sick returns injury color', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.statusColor(ctx, 'sick'),
      );
      expect(color, AppColors.injury);
    });

    testWidgets('injured returns injury color', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.statusColor(ctx, 'injured'),
      );
      expect(color, AppColors.injury);
    });

    testWidgets('unknown status returns neutral400', (tester) async {
      final color = await _captureColor(
        tester,
        Brightness.light,
        (ctx) => AppColors.statusColor(ctx, 'nonexistent'),
      );
      expect(color, AppColors.neutral400);
    });
  });

  group('subtitleText', () {
    testWidgets('returns onSurfaceVariant from colorScheme', (tester) async {
      late Color result;
      late Color expected;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              result = AppColors.subtitleText(context);
              expected = Theme.of(context).colorScheme.onSurfaceVariant;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(result, expected);
    });

    testWidgets('dark theme returns dark onSurfaceVariant', (tester) async {
      late Color result;
      late Color expected;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (context) {
              result = AppColors.subtitleText(context);
              expected = Theme.of(context).colorScheme.onSurfaceVariant;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(result, expected);
    });
  });
}
