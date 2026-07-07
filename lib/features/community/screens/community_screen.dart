import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../router/route_names.dart';
import '../../../data/providers/user_role_providers.dart'
    show isFounderProvider;
// Cross-feature import: marketplace tab embedded in community hub (composite screen pattern)
import 'package:budgie_breeding_tracker/shared/widgets/marketplace.dart';
import '../providers/community_feed_providers.dart';
import '../providers/community_providers.dart';
import '../widgets/community_app_bar.dart';
import '../widgets/community_feed_list.dart';
import '../widgets/community_pill_tabs.dart';

/// Community screen — social hub with feed, marketplace, messaging access.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = ref.watch(isCommunityEnabledProvider);
    final activeTab = ref.watch(communityActiveTabProvider);
    final theme = Theme.of(context);

    // Hide the FAB while the welcome empty state is showing — that empty state
    // renders its own create-post CTA, so a second FAB would be a redundant
    // duplicate button on an otherwise empty screen.
    final showWelcomeEmpty =
        isEnabled &&
        activeTab != CommunityFeedTab.marketplace &&
        activeTab != CommunityFeedTab.guides &&
        ref.watch(communityShowWelcomeEmptyProvider(activeTab));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const CommunityAppBar(),
      floatingActionButton:
          isEnabled &&
              !showWelcomeEmpty &&
              (activeTab != CommunityFeedTab.guides ||
                  ref.watch(isFounderProvider).value == true)
          ? _CreatePostFab(
              activeTab: activeTab,
              onPressed: () => context.push(_buildCreateRoute(activeTab)),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.38),
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
            stops: const [0, 0.24, 1],
          ),
        ),
        child: SafeArea(
          top: false,
          child: isEnabled
              ? _buildBody(context, activeTab)
              : const _ComingSoonBody(),
        ),
      ),
    );
  }

  String _buildCreateRoute(CommunityFeedTab activeTab) {
    if (activeTab == CommunityFeedTab.marketplace) {
      return '${AppRoutes.marketplace}/form';
    }

    final initialType = switch (activeTab) {
      CommunityFeedTab.guides => CommunityPostType.guide,
      _ => CommunityPostType.general,
    };

    return initialType == CommunityPostType.general
        ? AppRoutes.communityCreatePost
        : '${AppRoutes.communityCreatePost}?type=${initialType.toJson()}';
  }

  Widget _buildBody(BuildContext context, CommunityFeedTab activeTab) {
    final theme = Theme.of(context);

    // marketplace tab renders the embedded marketplace content
    final tabBody = activeTab == CommunityFeedTab.marketplace
        ? Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusXl),
              ),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.18),
              ),
            ),
            child: const MarketplaceTabContent(),
          )
        : CommunityFeedList(tab: activeTab);

    return Column(
      children: [
        const _CommunityTabRail(),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: KeyedSubtree(key: ValueKey(activeTab), child: tabBody),
          ),
        ),
      ],
    );
  }
}

class _CommunityTabRail extends StatelessWidget {
  const _CommunityTabRail();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.6,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.22),
          ),
        ),
        child: const CommunityPillTabs(),
      ),
    );
  }
}

class _ComingSoonBody extends StatelessWidget {
  const _ComingSoonBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        icon: const AppIcon(AppIcons.community),
        title: 'community.coming_soon'.tr(),
        subtitle: 'community.coming_soon_hint'.tr(),
      ),
    );
  }
}

/// Amber-gradient "Gönderi Oluştur" pill FAB matching the community redesign.
///
/// A custom gradient pill (FloatingActionButton has no gradient support) with
/// a plus icon for posts, or the guide glyph on the guides tab.
class _CreatePostFab extends StatelessWidget {
  const _CreatePostFab({required this.activeTab, required this.onPressed});

  final CommunityFeedTab activeTab;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isGuide = activeTab == CommunityFeedTab.guides;
    final isMarket = activeTab == CommunityFeedTab.marketplace;
    final showLabel = MediaQuery.sizeOf(context).width >= 430;

    final label = isMarket
        ? 'marketplace.add_listing'.tr()
        : isGuide
        ? 'community.create_guide'.tr()
        : 'community.create_post'.tr();

    return Semantics(
      button: true,
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.accent, AppColors.accentLight],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: showLabel
                ? ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppSpacing.touchTargetLg,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _CreatePostIcon(isGuide: isGuide, isMarket: isMarket),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            label,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.premiumBadgeText,
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SizedBox.square(
                    dimension: AppSpacing.touchTargetLg,
                    child: Center(
                      child: _CreatePostIcon(
                        isGuide: isGuide,
                        isMarket: isMarket,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _CreatePostIcon extends StatelessWidget {
  const _CreatePostIcon({required this.isGuide, required this.isMarket});

  final bool isGuide;
  final bool isMarket;

  @override
  Widget build(BuildContext context) {
    if (isMarket) {
      return const Icon(
        LucideIcons.store,
        size: 22,
        color: AppColors.premiumBadgeText,
      );
    }

    if (isGuide) {
      return const AppIcon(
        AppIcons.guide,
        size: 22,
        color: AppColors.premiumBadgeText,
      );
    }

    return const Icon(
      LucideIcons.plus,
      size: 22,
      color: AppColors.premiumBadgeText,
    );
  }
}
