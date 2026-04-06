import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/enums/gamification_enums.dart';
import 'package:budgie_breeding_tracker/data/models/badge_model.dart';
import 'package:budgie_breeding_tracker/data/models/user_badge_model.dart';
import 'package:budgie_breeding_tracker/features/gamification/providers/gamification_providers.dart';
import 'package:budgie_breeding_tracker/features/gamification/widgets/badge_card.dart';

import '../../../helpers/test_localization.dart';

void main() {
  const badge = Badge(
    id: 'b1',
    key: 'first_egg',
    category: BadgeCategory.breeding,
    tier: BadgeTier.gold,
    nameKey: 'badges.first_egg',
    requirement: 10,
  );

  group('BadgeCard', () {
    testWidgets('renders locked state with progress bar', (tester) async {
      final enriched = EnrichedBadge(
        badge: badge,
        userBadge: const UserBadge(
          id: 'ub1',
          userId: 'user-1',
          badgeId: 'b1',
          progress: 3,
        ),
      );

      await pumpLocalizedWidget(tester, BadgeCard(enrichedBadge: enriched));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('3/10'), findsOneWidget);
      expect(find.byIcon(LucideIcons.lock), findsOneWidget);
    });

    testWidgets('renders unlocked state with check icon', (tester) async {
      final enriched = EnrichedBadge(
        badge: badge,
        userBadge: const UserBadge(
          id: 'ub1',
          userId: 'user-1',
          badgeId: 'b1',
          progress: 10,
          isUnlocked: true,
        ),
      );

      await pumpLocalizedWidget(tester, BadgeCard(enrichedBadge: enriched));

      expect(find.byIcon(LucideIcons.checkCircle), findsOneWidget);
      expect(find.byIcon(LucideIcons.award), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('renders without userBadge (no progress)', (tester) async {
      const enriched = EnrichedBadge(badge: badge);

      await pumpLocalizedWidget(
        tester,
        const BadgeCard(enrichedBadge: enriched),
      );

      expect(find.byIcon(LucideIcons.lock), findsOneWidget);
      expect(find.text('0/10'), findsOneWidget);
    });

    testWidgets('fires onTap callback', (tester) async {
      var tapped = false;
      const enriched = EnrichedBadge(badge: badge);

      await pumpLocalizedWidget(
        tester,
        BadgeCard(enrichedBadge: enriched, onTap: () => tapped = true),
      );

      await tester.tap(find.byType(BadgeCard));
      expect(tapped, isTrue);
    });
  });
}
