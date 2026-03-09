import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';

void main() {
  group('AppSpacing — base spacing scale', () {
    test('xxs is 2', () => expect(AppSpacing.xxs, 2.0));
    test('xs is 4', () => expect(AppSpacing.xs, 4.0));
    test('sm is 8', () => expect(AppSpacing.sm, 8.0));
    test('md is 12', () => expect(AppSpacing.md, 12.0));
    test('lg is 16', () => expect(AppSpacing.lg, 16.0));
    test('xl is 20', () => expect(AppSpacing.xl, 20.0));
    test('xxl is 24', () => expect(AppSpacing.xxl, 24.0));
    test('xxxl is 32', () => expect(AppSpacing.xxxl, 32.0));

    test('spacing scale is strictly increasing', () {
      final scale = [
        AppSpacing.xxs,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ];
      for (var i = 0; i < scale.length - 1; i++) {
        expect(
          scale[i],
          lessThan(scale[i + 1]),
          reason: 'spacing step $i should be smaller than step ${i + 1}',
        );
      }
    });
  });

  group('AppSpacing — touch targets (WCAG 2.1 AA)', () {
    test('touchTargetMin is at least 44', () {
      expect(AppSpacing.touchTargetMin, greaterThanOrEqualTo(44.0));
    });

    test('touchTargetMd is at least 48', () {
      expect(AppSpacing.touchTargetMd, greaterThanOrEqualTo(48.0));
    });

    test('touchTargetLg is at least 52', () {
      expect(AppSpacing.touchTargetLg, greaterThanOrEqualTo(52.0));
    });

    test('touch target scale is increasing', () {
      expect(AppSpacing.touchTargetMin, lessThan(AppSpacing.touchTargetMd));
      expect(AppSpacing.touchTargetMd, lessThan(AppSpacing.touchTargetLg));
    });
  });

  group('AppSpacing — border radius', () {
    test('radiusSm is 4', () => expect(AppSpacing.radiusSm, 4.0));
    test('radiusMd is 8', () => expect(AppSpacing.radiusMd, 8.0));
    test('radiusLg is 12', () => expect(AppSpacing.radiusLg, 12.0));
    test('radiusXl is 16', () => expect(AppSpacing.radiusXl, 16.0));
    test('radiusFull is 999 (pill shape)', () {
      expect(AppSpacing.radiusFull, 999.0);
    });

    test('border radius scale is strictly increasing', () {
      final scale = [
        AppSpacing.radiusSm,
        AppSpacing.radiusMd,
        AppSpacing.radiusLg,
        AppSpacing.radiusXl,
      ];
      for (var i = 0; i < scale.length - 1; i++) {
        expect(
          scale[i],
          lessThan(scale[i + 1]),
          reason: 'radius step $i should be smaller than step ${i + 1}',
        );
      }
    });
  });

  group('AppSpacing — EdgeInsets constants', () {
    test('screenPadding is EdgeInsets.all(16)', () {
      expect(AppSpacing.screenPadding, const EdgeInsets.all(16));
    });

    test('cardPadding is EdgeInsets.all(16)', () {
      expect(AppSpacing.cardPadding, const EdgeInsets.all(16));
    });

    test('listItemPadding has horizontal 16 and vertical 12', () {
      expect(
        AppSpacing.listItemPadding,
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
    });

    test('screenPadding has consistent left and right insets', () {
      expect(AppSpacing.screenPadding.left, AppSpacing.screenPadding.right);
    });

    test('screenPadding has consistent top and bottom insets', () {
      expect(AppSpacing.screenPadding.top, AppSpacing.screenPadding.bottom);
    });

    test('listItemPadding horizontal exceeds vertical', () {
      expect(
        AppSpacing.listItemPadding.left,
        greaterThan(AppSpacing.listItemPadding.top),
      );
    });
  });
}
