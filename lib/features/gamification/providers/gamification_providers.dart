import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/badge_model.dart';
import '../../../data/models/user_badge_model.dart';
import '../../../data/models/user_level_model.dart';
import '../../../data/models/xp_transaction_model.dart';
import '../../../data/repositories/repository_providers.dart';

export 'package:budgie_breeding_tracker/core/enums/gamification_enums.dart';
export 'package:budgie_breeding_tracker/data/models/badge_model.dart';
export 'package:budgie_breeding_tracker/data/models/user_badge_model.dart';
export 'package:budgie_breeding_tracker/data/models/user_level_model.dart';
export 'package:budgie_breeding_tracker/data/models/xp_transaction_model.dart';

/// All badge definitions
final badgesProvider = FutureProvider<List<Badge>>((ref) async {
  final repo = ref.watch(gamificationRepositoryProvider);
  return repo.getBadges();
});

/// Current user's badge progress
final userBadgesProvider =
    FutureProvider.family<List<UserBadge>, String>((ref, userId) async {
  final repo = ref.watch(gamificationRepositoryProvider);
  return repo.getUserBadges(userId);
});

/// Current user's level
final userLevelProvider =
    FutureProvider.family<UserLevel?, String>((ref, userId) async {
  final repo = ref.watch(gamificationRepositoryProvider);
  return repo.getUserLevel(userId);
});

/// XP history
final xpHistoryProvider =
    FutureProvider.family<List<XpTransaction>, String>((ref, userId) async {
  final repo = ref.watch(gamificationRepositoryProvider);
  return repo.getXpHistory(userId);
});

/// Leaderboard
final leaderboardProvider = FutureProvider<List<UserLevel>>((ref) async {
  final repo = ref.watch(gamificationRepositoryProvider);
  return repo.getLeaderboard();
});

/// Badge category filter
enum BadgeCategoryFilter {
  all,
  breeding,
  community,
  marketplace,
  health,
  milestone,
  special;

  String get label => switch (this) {
        BadgeCategoryFilter.all => 'common.all'.tr(),
        BadgeCategoryFilter.breeding => 'badges.category_breeding'.tr(),
        BadgeCategoryFilter.community => 'badges.category_community'.tr(),
        BadgeCategoryFilter.marketplace => 'badges.category_marketplace'.tr(),
        BadgeCategoryFilter.health => 'badges.category_health'.tr(),
        BadgeCategoryFilter.milestone => 'badges.category_milestone'.tr(),
        BadgeCategoryFilter.special => 'badges.category_special'.tr(),
      };
}

class BadgeCategoryFilterNotifier extends Notifier<BadgeCategoryFilter> {
  @override
  BadgeCategoryFilter build() => BadgeCategoryFilter.all;
}

final badgeCategoryFilterProvider =
    NotifierProvider<BadgeCategoryFilterNotifier, BadgeCategoryFilter>(
  BadgeCategoryFilterNotifier.new,
);

/// Filtered badges
final filteredBadgesProvider =
    Provider.family<List<Badge>, List<Badge>>((ref, badges) {
  final filter = ref.watch(badgeCategoryFilterProvider);
  if (filter == BadgeCategoryFilter.all) return badges;

  final categoryName = filter.name;
  return badges.where((b) => b.category.name == categoryName).toList();
});

/// Enriched badges (Badge + UserBadge combined for display)
class EnrichedBadge {
  final Badge badge;
  final UserBadge? userBadge;

  const EnrichedBadge({required this.badge, this.userBadge});

  int get progress => userBadge?.progress ?? 0;
  bool get isUnlocked => userBadge?.isUnlocked ?? false;
  double get progressPercent =>
      userBadge?.progressPercent(badge.requirement) ?? 0;
}

final enrichedBadgesProvider = Provider.family<
    List<EnrichedBadge>,
    ({List<Badge> badges, List<UserBadge> userBadges})>((ref, params) {
  final userBadgeMap = <String, UserBadge>{};
  for (final ub in params.userBadges) {
    userBadgeMap[ub.badgeId] = ub;
  }

  return params.badges.map((badge) {
    return EnrichedBadge(
      badge: badge,
      userBadge: userBadgeMap[badge.id],
    );
  }).toList();
});
