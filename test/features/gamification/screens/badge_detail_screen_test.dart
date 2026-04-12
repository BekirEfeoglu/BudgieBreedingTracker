import 'dart:async';

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/gamification/providers/gamification_providers.dart';
import 'package:budgie_breeding_tracker/features/gamification/screens/badge_detail_screen.dart';

import '../../../helpers/test_localization.dart';

void main() {
  const testBadge = Badge(
    id: 'b1',
    key: 'first_egg',
    category: BadgeCategory.breeding,
    tier: BadgeTier.gold,
    nameKey: 'badges.first_egg',
    descriptionKey: 'badges.first_egg_desc',
    requirement: 10,
    xpReward: 50,
  );

  Widget buildSubject({
    List<Badge> badges = const [testBadge],
    List<UserBadge> userBadges = const [],
    bool loading = false,
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        badgesProvider.overrideWith(
          (ref) => loading
              ? Completer<List<Badge>>().future
              : Future.value(badges),
        ),
        userBadgesProvider('user-1').overrideWith(
          (ref) => Future.value(userBadges),
        ),
      ],
      child: const MaterialApp(
        home: BadgeDetailScreen(badgeId: 'b1'),
      ),
    );
  }

  group('BadgeDetailScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(loading: true),
        settle: false,
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows badge details when data available', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows progress for locked badge', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          userBadges: const [
            UserBadge(
              id: 'ub1',
              userId: 'user-1',
              badgeId: 'b1',
              progress: 3,
            ),
          ],
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
