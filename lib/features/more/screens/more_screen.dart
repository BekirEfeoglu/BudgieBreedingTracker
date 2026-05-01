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
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart'; // Cross-feature import: premium check for feature gating

part 'more_screen_sections.dart';

/// Hub screen accessible via the "More" bottom-nav tab.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userId = ref.watch(currentUserIdProvider);
    final isGuest = userId == 'anonymous';

    return Scaffold(
      appBar: AppBar(
        title: AppScreenTitle(title: 'nav.more'.tr(), iconAsset: AppIcons.more),
        actions: isGuest
            ? [
                TextButton(
                  onPressed: () => context.push(AppRoutes.login),
                  child: Text('auth.login'.tr()),
                ),
              ]
            : const [NotificationBellButton(), ProfileMenuButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          // Features section
          _SectionHeader(title: 'more.section_features'.tr()),
          _MoreTile(
            icon: const AppIcon(AppIcons.chick),
            title: 'nav.chicks'.tr(),
            onTap: () => context.push(AppRoutes.chicks),
          ),
          _MoreTile(
            icon: const AppIcon(AppIcons.health),
            title: 'health_records.title'.tr(),
            onTap: () => context.push(AppRoutes.healthRecords),
          ),
          if (FeatureFlags.communityEnabled)
            Builder(
              builder: (context) {
                final isFounder = ref.watch(isFounderProvider).value == true;
                return _MoreTile(
                  icon: const AppIcon(AppIcons.community),
                  title: 'more.community'.tr(),
                  trailing: isFounder ? null : _ComingSoonBadge(theme: theme),
                  onTap: () {
                    if (isFounder) {
                      context.push(AppRoutes.community);
                    } else {
                      _showComingSoon(context);
                    }
                  },
                );
              },
            ),
          // Marketplace, Messaging, Badges, Leaderboard → accessed via Community tab
          // Premium features section
          // IMPROVED: premium features show hint when not premium instead of silent redirect
          _SectionHeader(title: 'more.section_premium'.tr()),
          ..._buildPremiumTiles(context, ref, theme),
          // Subscription section
          _SectionHeader(title: 'more.section_subscription'.tr()),
          _MoreTile(
            icon: const AppIcon(AppIcons.premium),
            title: 'more.premium'.tr(),
            onTap: () => context.push(AppRoutes.premium),
          ),
          // Support section
          _SectionHeader(title: 'more.section_support'.tr()),
          _MoreTile(
            icon: const AppIcon(AppIcons.guide),
            title: 'more.user_guide'.tr(),
            onTap: () => context.push(AppRoutes.userGuide),
          ),
          _MoreTile(
            icon: const Icon(LucideIcons.messageSquare),
            title: 'more.feedback'.tr(),
            onTap: () => context.push(AppRoutes.feedback),
          ),
          _MoreTile(
            icon: const Icon(LucideIcons.fileText),
            title: 'settings.privacy_policy'.tr(),
            onTap: () => context.push(AppRoutes.privacyPolicy),
          ),
          _MoreTile(
            icon: const Icon(LucideIcons.scale),
            title: 'settings.terms'.tr(),
            onTap: () => context.push(AppRoutes.termsOfService),
          ),
          // Settings section
          _SectionHeader(title: 'more.section_settings'.tr()),
          _MoreTile(
            icon: const AppIcon(AppIcons.settings),
            title: 'settings.title'.tr(),
            onTap: () => context.push(AppRoutes.settings),
          ),
          // Admin panel (only visible to admin users)
          if (ref.watch(isAdminProvider).value == true)
            _MoreTile(
              icon: const AppIcon(AppIcons.security),
              title: 'more.admin_panel'.tr(),
              onTap: () => context.push(AppRoutes.adminDashboard),
            ),
          // About (standalone, no section header)
          _MoreTile(
            icon: const AppIcon(AppIcons.info),
            title: 'more.about'.tr(),
            onTap: () => _showMoreAboutDialog(context, ref),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPremiumTiles(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    final isPremium = ref.watch(isPremiumProvider);
    final isFounder = ref.watch(isFounderProvider).value == true;

    void navigateOrHint(String route) {
      if (isPremium) {
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
        onTap: () => navigateOrHint(AppRoutes.statistics),
      ),
      _MoreTile(
        icon: const AppIcon(AppIcons.genealogy),
        title: 'more.genealogy'.tr(),
        trailing: _PremiumBadge(theme: theme),
        onTap: () => navigateOrHint(AppRoutes.genealogy),
      ),
      _MoreTile(
        icon: const AppIcon(AppIcons.dna),
        title: 'more.genetics'.tr(),
        trailing: _PremiumBadge(theme: theme),
        onTap: () => navigateOrHint(AppRoutes.genetics),
      ),
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
