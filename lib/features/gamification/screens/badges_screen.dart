import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/app_icon_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart' as app;
import '../../breeding/providers/breeding_providers.dart';
import '../../../router/route_names.dart';
import '../providers/gamification_providers.dart';
import '../widgets/badge_card.dart';
import '../widgets/xp_progress_bar.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final badgesAsync = ref.watch(badgesProvider);
    final userBadgesAsync = ref.watch(userBadgesProvider(userId));
    final userLevelAsync = ref.watch(userLevelProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text('badges.title'.tr()),
        actions: [
          AppIconButton(
            icon: const Icon(LucideIcons.trophy),
            tooltip: 'leaderboard.title'.tr(),
            semanticLabel: 'leaderboard.title'.tr(),
            onPressed: () => context.push(AppRoutes.leaderboard),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(badgesProvider);
          ref.invalidate(userBadgesProvider(userId));
          ref.invalidate(userLevelProvider(userId));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.xxxl * 2),
          child: Column(
            children: [
              // XP/Level header
              userLevelAsync.when(
                loading: () => const SizedBox(height: 100),
                error: (_, __) => const SizedBox.shrink(),
                data: (level) => level != null
                    ? Padding(
                        padding: AppSpacing.screenPadding,
                        child: XpProgressBar(userLevel: level),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Category filter
              const _CategoryFilterBar(),
              const SizedBox(height: AppSpacing.lg),
              // Badges grid
              badgesAsync.when(
                loading: () =>
                    const LoadingState(),
                error: (error, _) => app.ErrorState(
                  message: '${'common.data_load_error'.tr()}: $error',
                  onRetry: () => ref.invalidate(badgesProvider),
                ),
                data: (allBadges) {
                  return userBadgesAsync.when(
                    loading: () =>
                        const LoadingState(),
                    error: (error, _) => app.ErrorState(
                      message: '${'common.data_load_error'.tr()}: $error',
                    ),
                    data: (userBadges) {
                      final filtered =
                          ref.watch(filteredBadgesProvider(allBadges));
                      final enriched = ref.watch(enrichedBadgesProvider(
                        (badges: filtered, userBadges: userBadges),
                      ));

                      if (enriched.isEmpty) {
                        return EmptyState(
                          icon: const Icon(LucideIcons.award),
                          title: 'badges.no_badges'.tr(),
                          subtitle: 'badges.no_badges_hint'.tr(),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                        ),
                        itemCount: enriched.length,
                        itemBuilder: (context, index) => BadgeCard(
                          enrichedBadge: enriched[index],
                          onTap: () => context.push(
                            '${AppRoutes.badges}/${enriched[index].badge.id}',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterBar extends ConsumerWidget {
  const _CategoryFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(badgeCategoryFilterProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: BadgeCategoryFilter.values.map((filter) {
          final isSelected = currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (_) {
                ref.read(badgeCategoryFilterProvider.notifier).state = filter;
              },
              selectedColor: theme.colorScheme.primaryContainer,
              checkmarkColor: theme.colorScheme.primary,
            ),
          );
        }).toList(),
      ),
    );
  }
}
