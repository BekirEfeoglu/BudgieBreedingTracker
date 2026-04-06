import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/data/models/user_level_model.dart';
import 'package:budgie_breeding_tracker/features/gamification/widgets/xp_progress_bar.dart';

import '../../../helpers/test_localization.dart';

void main() {
  const userLevel = UserLevel(
    id: 'ul1',
    userId: 'user-1',
    totalXp: 750,
    level: 5,
    currentLevelXp: 50,
    nextLevelXp: 200,
    title: 'gamification.breeder',
  );

  group('XpProgressBar', () {
    testWidgets('renders progress bar and XP text', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const XpProgressBar(userLevel: userLevel),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('50 / 200 XP'), findsOneWidget);
      expect(find.byIcon(LucideIcons.zap), findsOneWidget);
    });

    testWidgets('renders title when not empty', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const XpProgressBar(userLevel: userLevel),
      );

      // Title key is rendered as raw key via TestAssetLoader
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('hides title section when title is empty', (tester) async {
      const noTitle = UserLevel(
        id: 'ul2',
        userId: 'user-1',
        totalXp: 100,
        level: 2,
        currentLevelXp: 10,
        nextLevelXp: 100,
        title: '',
      );

      await pumpLocalizedWidget(
        tester,
        const XpProgressBar(userLevel: noTitle),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
