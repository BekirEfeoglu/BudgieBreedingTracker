import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/feature_flags.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_screen_title.dart';
import '../../../router/route_names.dart';
import 'package:budgie_breeding_tracker/shared/widgets/app_shell.dart';
import '../../../data/providers/user_role_providers.dart';
import 'package:budgie_breeding_tracker/shared/providers/auth.dart';
import 'package:budgie_breeding_tracker/shared/providers/settings.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_reward_providers.dart';

part 'more_screen_sections.dart';

const double _bottomNavScrollPadding =
    kBottomNavigationBarHeight + AppSpacing.xxxl;

/// Hub screen accessible via the "More" bottom-nav tab.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userId = ref.watch(currentUserIdProvider);
    final isGuest = userId == 'anonymous';
    // Hoisted: founder flag is read for both the community tile and the AI
    // predictions tile inside _buildPremiumTiles. A previous version wrapped
    // the community tile in a Builder, which is a no-op for Riverpod rebuild
    // scoping (ref is captured from the outer Consumer scope, so the entire
    // MoreScreen rebuilds either way) — reading once here is clearer and
    // keeps the two tiles consistent with the same value.
    final isFounder = ref.watch(isFounderProvider).value == true;

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            title: AppScreenTitle(
              title: 'nav.more'.tr(),
              iconAsset: AppIcons.more,
            ),
            actions: isGuest
                ? [
                    TextButton(
                      onPressed: () => context.push(AppRoutes.login),
                      child: Text('auth.login'.tr()),
                    ),
                  ]
                : const [NotificationBellButton(), ProfileMenuButton()],
          ),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: _bottomNavScrollPadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Features section
                _SectionHeader(title: 'more.section_features'.tr()),
                _SectionCard(
                  children: [
                    _MoreTile(
                      icon: const AppIcon(AppIcons.chick),
                      title: 'nav.chicks'.tr(),
                      onTap: () => context.push(AppRoutes.chicks),
                    ),
                    const _SectionDivider(),
                    _MoreTile(
                      icon: const AppIcon(AppIcons.health),
                      title: 'health_records.title'.tr(),
                      onTap: () => context.push(AppRoutes.healthRecords),
                    ),
                    if (FeatureFlags.communityEnabled) ...[
                      const _SectionDivider(),
                      _MoreTile(
                        icon: const AppIcon(AppIcons.community),
                        title: 'more.community'.tr(),
                        trailing: isFounder
                            ? null
                            : _ComingSoonBadge(theme: theme),
                        onTap: () {
                          if (isFounder) {
                            context.push(AppRoutes.community);
                          } else {
                            _showComingSoon(context);
                          }
                        },
                      ),
                    ],
                  ],
                ),
                // Premium features section
                _SectionHeader(title: 'more.section_premium'.tr()),
                _SectionCard(
                  isPremium: true,
                  children: _buildPremiumTiles(
                    context,
                    ref,
                    theme,
                    isFounder: isFounder,
                  ),
                ),
                // Subscription section
                _SectionHeader(title: 'more.section_subscription'.tr()),
                _SectionCard(
                  children: [
                    _MoreTile(
                      icon: const AppIcon(AppIcons.premium),
                      title: 'more.premium'.tr(),
                      onTap: () => context.push(AppRoutes.premium),
                    ),
                  ],
                ),
                // Support section
                _SectionHeader(title: 'more.section_support'.tr()),
                _SectionCard(
                  children: [
                    _MoreTile(
                      icon: const AppIcon(AppIcons.guide),
                      title: 'more.user_guide'.tr(),
                      onTap: () => context.push(AppRoutes.userGuide),
                    ),
                    const _SectionDivider(),
                    _MoreTile(
                      icon: const Icon(LucideIcons.messageSquare),
                      title: 'more.feedback'.tr(),
                      onTap: () => context.push(AppRoutes.feedback),
                    ),
                    const _SectionDivider(),
                    _MoreTile(
                      icon: const Icon(LucideIcons.fileText),
                      title: 'settings.privacy_policy'.tr(),
                      onTap: () => context.push(AppRoutes.privacyPolicy),
                    ),
                    const _SectionDivider(),
                    _MoreTile(
                      icon: const Icon(LucideIcons.scale),
                      title: 'settings.terms'.tr(),
                      onTap: () => context.push(AppRoutes.termsOfService),
                    ),
                  ],
                ),
                // Settings section
                _SectionHeader(title: 'more.section_settings'.tr()),
                _SectionCard(
                  children: [
                    _MoreTile(
                      icon: const AppIcon(AppIcons.settings),
                      title: 'settings.title'.tr(),
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                  ],
                ),
                // Admin panel (only visible to admin users)
                if (ref.watch(isAdminProvider).value == true) ...[
                  _SectionHeader(title: 'more.admin_panel'.tr()),
                  _SectionCard(
                    children: [
                      _MoreTile(
                        icon: const AppIcon(AppIcons.security),
                        title: 'more.admin_panel'.tr(),
                        onTap: () => context.push(AppRoutes.adminDashboard),
                      ),
                    ],
                  ),
                ],
                // About (standalone, no section header)
                const SizedBox(height: AppSpacing.lg),
                _SectionCard(
                  children: [
                    _MoreTile(
                      icon: const AppIcon(AppIcons.info),
                      title: 'more.about'.tr(),
                      onTap: () => _showMoreAboutDialog(context),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPremiumTiles(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme, {
    required bool isFounder,
  }) {
    // Use effectivePremiumProvider so grace-period subscribers (renewal
    // failure within the grace window) keep route access — isPremiumProvider
    // alone would bounce paying customers to the paywall here.
    final hasPremiumAccess = ref.watch(effectivePremiumProvider);
    // Mirror the router's reward exemptions (app_router.dart): a rewarded-ad
    // unlock grants the SAME access here, otherwise a user who watched an ad
    // for Statistics/Genetics would be bounced back to the paywall from this
    // tile even though the route itself would admit them.
    final statsRewardActive = ref.watch(isStatisticsRewardActiveProvider);
    final geneticsRewardActive = ref.watch(isGeneticsRewardActiveProvider);

    void navigateOrHint(String route, {bool rewardActive = false}) {
      if (hasPremiumAccess || rewardActive) {
        context.push(route);
      } else {
        context.push(AppRoutes.premium);
      }
    }

    return [
      _MoreTile(
        icon: const AppIcon(AppIcons.statistics),
        title: 'more.statistics'.tr(),
        trailing: _PremiumBadge(theme: theme),
        onTap: () => navigateOrHint(
          AppRoutes.statistics,
          rewardActive: statsRewardActive,
        ),
      ),
      const _SectionDivider(),
      _MoreTile(
        icon: const AppIcon(AppIcons.genealogy),
        title: 'more.genealogy'.tr(),
        trailing: _PremiumBadge(theme: theme),
        onTap: () => navigateOrHint(AppRoutes.genealogy),
      ),
      const _SectionDivider(),
      _MoreTile(
        icon: const AppIcon(AppIcons.dna),
        title: 'more.genetics'.tr(),
        trailing: _PremiumBadge(theme: theme),
        onTap: () => navigateOrHint(
          AppRoutes.genetics,
          rewardActive: geneticsRewardActive,
        ),
      ),
      const _SectionDivider(),
      _MoreTile(
        icon: Icon(
          LucideIcons.sparkles,
          size: 22,
          color: theme.colorScheme.primary,
        ),
        title: 'more.ai_predictions'.tr(),
        trailing: isFounder
            ? _PremiumBadge(theme: theme)
            : _ComingSoonBadge(theme: theme),
        onTap: () {
          if (isFounder) {
            navigateOrHint(AppRoutes.aiPredictions);
          } else {
            _showComingSoon(context);
          }
        },
      ),
    ];
  }
}
