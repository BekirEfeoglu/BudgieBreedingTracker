import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/models/user_streak_model.dart';
import 'package:budgie_breeding_tracker/features/gamification/widgets/streak_celebration_banner.dart';

import '../../../helpers/pump_helpers.dart';

void main() {
  group('showStreakCelebration', () {
    testWidgets('shows celebration snackbar with xp', (tester) async {
      await pumpWidgetSimple(
        tester,
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => showStreakCelebration(
                context,
                const StreakCheckinResult(currentStreak: 8, awardedXp: 10),
              ),
              child: const Text('go'),
            );
          },
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('shows celebration snackbar for grace-consumed check-in', (
      tester,
    ) async {
      await pumpWidgetSimple(
        tester,
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => showStreakCelebration(
                context,
                const StreakCheckinResult(
                  currentStreak: 5,
                  graceConsumed: true,
                ),
              ),
              child: const Text('go'),
            );
          },
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('shows celebration snackbar for milestone unlock', (
      tester,
    ) async {
      await pumpWidgetSimple(
        tester,
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => showStreakCelebration(
                context,
                const StreakCheckinResult(
                  currentStreak: 30,
                  awardedXp: 50,
                  milestoneUnlocked: 'streak_30',
                ),
              ),
              child: const Text('go'),
            );
          },
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
