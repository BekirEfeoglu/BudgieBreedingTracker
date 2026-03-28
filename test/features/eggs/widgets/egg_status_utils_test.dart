import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/features/eggs/widgets/egg_status_utils.dart';

void main() {
  group('getEggStatusColor', () {
    test('returns stageNew for laid status', () {
      expect(getEggStatusColor(EggStatus.laid), equals(AppColors.stageNew));
    });

    test('returns success for fertile status', () {
      expect(getEggStatusColor(EggStatus.fertile), equals(AppColors.success));
    });

    test('returns neutral400 for infertile status', () {
      expect(
        getEggStatusColor(EggStatus.infertile),
        equals(AppColors.neutral400),
      );
    });

    test('returns stageOngoing for incubating status', () {
      expect(
        getEggStatusColor(EggStatus.incubating),
        equals(AppColors.stageOngoing),
      );
    });

    test('returns stageCompleted for hatched status', () {
      expect(
        getEggStatusColor(EggStatus.hatched),
        equals(AppColors.stageCompleted),
      );
    });

    test('returns error for damaged status', () {
      expect(getEggStatusColor(EggStatus.damaged), equals(AppColors.error));
    });

    test('returns neutral500 for discarded status', () {
      expect(
        getEggStatusColor(EggStatus.discarded),
        equals(AppColors.neutral500),
      );
    });

    test('returns neutral300 for empty status', () {
      expect(getEggStatusColor(EggStatus.empty), equals(AppColors.neutral300));
    });

    test('returns neutral300 for unknown status', () {
      expect(
        getEggStatusColor(EggStatus.unknown),
        equals(AppColors.neutral300),
      );
    });

    test('returns a Color for every EggStatus value', () {
      for (final status in EggStatus.values) {
        final color = getEggStatusColor(status);
        expect(color, isA<Color>(), reason: 'Missing color for $status');
      }
    });

    test('all returned colors are non-transparent', () {
      for (final status in EggStatus.values) {
        final color = getEggStatusColor(status);
        expect(color.a, greaterThan(0), reason: '$status color is transparent');
      }
    });
  });
}
