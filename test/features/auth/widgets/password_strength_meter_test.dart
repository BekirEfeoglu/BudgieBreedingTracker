import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/domain/services/auth/password_policy.dart';
import 'package:budgie_breeding_tracker/features/auth/widgets/password_strength_meter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  group('PasswordStrengthMeter', () {
    testWidgets('renders nothing for empty password', (tester) async {
      await pumpWidgetSimple(tester, const PasswordStrengthMeter(password: ''));

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byIcon(LucideIcons.checkCircle), findsNothing);
      expect(find.byIcon(LucideIcons.circle), findsNothing);
    });

    testWidgets('shows weak state with one passed rule', (tester) async {
      await pumpWidgetSimple(
        tester,
        const PasswordStrengthMeter(password: 'abc'),
      );

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, PasswordStrength.weak.progressValue);
      expect(indicator.color, AppColors.error);
      expect(find.byIcon(LucideIcons.checkCircle), findsOneWidget);
      expect(find.byIcon(LucideIcons.circle), findsNWidgets(4));
    });

    testWidgets('shows strong state when all rules pass', (tester) async {
      await pumpWidgetSimple(
        tester,
        const PasswordStrengthMeter(password: 'Abcdef1!'),
      );

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, PasswordStrength.strong.progressValue);
      expect(indicator.color, AppColors.success);
      expect(find.byIcon(LucideIcons.checkCircle), findsNWidgets(5));
      expect(find.byIcon(LucideIcons.circle), findsNothing);
    });
  });
}
