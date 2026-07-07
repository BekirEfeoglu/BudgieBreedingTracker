import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/feature_flags.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/app_screen_title.dart';
import '../../../core/widgets/error_state.dart';
import '../../../data/models/profile_model.dart';
import '../../../router/route_names.dart';
import 'package:budgie_breeding_tracker/shared/providers/auth.dart';
import 'package:budgie_breeding_tracker/shared/providers/gamification.dart'
    as gamification;
import 'package:budgie_breeding_tracker/shared/widgets/gamification.dart';
import '../providers/profile_providers.dart';
import '../widgets/account_info_card.dart';
import '../widgets/animated_section.dart';
import '../widgets/avatar_picker_sheet.dart';
import '../widgets/danger_zone_section.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/password_change_sheet.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_tile.dart';
import '../widgets/profile_skeleton.dart';
import '../widgets/security_section.dart';
import '../widgets/subscription_card.dart';
import 'package:budgie_breeding_tracker/core/providers/action_feedback_providers.dart';

/// Comprehensive user profile screen with collapsing header.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    final user = ref.watch(currentUserProvider);
    final avatarState = ref.watch(avatarUploadStateProvider);
    final userId = ref.watch(currentUserIdProvider);

    // Avatar upload side effects
    ref.listen<AvatarUploadState>(avatarUploadStateProvider, (_, state) {
      if (!context.mounted) return;
      if (state.isSuccess) {
        ref.read(avatarUploadStateProvider.notifier).reset();
        ActionFeedbackService.show('profile.avatar_upload_success'.tr());
      }
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile.avatar_upload_error'.tr())),
        );
      }
    });

    return Scaffold(
      body: profileAsync.when(
        loading: () => const ProfileSkeleton(),
        error: (e, _) => ErrorState(
          message: 'common.data_load_error'.tr(),
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
        data: (profile) {
          final displayName =
              profile?.resolvedDisplayName ??
              user?.email?.split('@').first ??
              '';
          final email = user?.email ?? profile?.email ?? '';
          final statsAsync = ref.watch(profileStatsProvider(userId));
          final userLevelAsync = ref.watch(
            gamification.userLevelProvider(userId),
          );
          final badgesAsync = ref.watch(gamification.badgesProvider);
          final userBadgesAsync = ref.watch(
            gamification.userBadgesProvider(userId),
          );
          final badges = badgesAsync.value ?? const <gamification.Badge>[];
          final userBadges =
              userBadgesAsync.value ?? const <gamification.UserBadge>[];
          final unlockedBadges = ref
              .watch(
                gamification.enrichedBadgesProvider((
                  badges: badges,
                  userBadges: userBadges,
                )),
              )
              .where((badge) => badge.isUnlocked)
              .toList(growable: false);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userProfileProvider);
              ref.invalidate(profileStatsProvider(userId));
              ref.invalidate(gamification.userLevelProvider(userId));
              ref.invalidate(gamification.badgesProvider);
              ref.invalidate(gamification.userBadgesProvider(userId));
              AppHaptics.mediumImpact();
              if (context.mounted) {
                ActionFeedbackService.show('profile.refresh_complete'.tr());
              }
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Pinned AppBar (title only)
                SliverAppBar(
                  pinned: true,
                  backgroundColor: theme.colorScheme.surface,
                  surfaceTintColor: Colors.transparent,
                  scrolledUnderElevation: 0,
                  clipBehavior: Clip.hardEdge,
                  title: AppScreenTitle(
                    title: 'profile.title'.tr(),
                    iconAsset: AppIcons.profile,
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ),

                // Profile header (self-sizing — no fixed height)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: ProfileHeader(
                      profile: profile,
                      displayName: displayName,
                      email: email,
                      isAvatarUploading: avatarState.isUploading,
                      stats: statsAsync.value,
                      userLevel: userLevelAsync.value,
                      unlockedBadges: unlockedBadges,
                      onEditProfile: () => openEditProfileSheet(
                        context,
                        ref: ref,
                        profile: profile,
                        email: email,
                      ),
                      onEditAvatar: () => showAvatarPickerSheet(
                        context,
                        ref: ref,
                        hasAvatar: profile?.avatarUrl != null,
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: _BadgeShowcaseSection(unlockedBadges: unlockedBadges),
                ),

                // Content sections
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  sliver: SliverList.list(
                    children: [
                      // Account Info
                      AnimatedSection(
                        index: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ProfileSectionTitle(
                              label: 'profile.account_info'.tr(),
                            ),
                            AccountInfoCard(profile: profile, email: email),
                            const SizedBox(height: AppSpacing.md),
                            SubscriptionCard(profile: profile),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Security
                      AnimatedSection(
                        index: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ProfileSectionTitle(label: 'profile.security'.tr()),
                            SecuritySection(
                              onChangePassword: () =>
                                  showPasswordChangeSheet(context, ref: ref),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Danger Zone
                      AnimatedSection(
                        index: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ProfileSectionTitle(
                              label: 'profile.danger_zone'.tr(),
                              color: AppColors.error,
                            ),
                            const DangerZoneSection(),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl * 2),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BadgeShowcaseSection extends StatelessWidget {
  const _BadgeShowcaseSection({required this.unlockedBadges});

  final List<gamification.EnrichedBadge> unlockedBadges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionTitle(label: 'badges.showcase'.tr()),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (unlockedBadges.isEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'badges.no_badges'.tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: unlockedBadges.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, index) => _BadgeShowcaseItem(
                        enrichedBadge: unlockedBadges[index],
                      ),
                    ),
                  ),
                if (FeatureFlags.gamificationEnabled) ...[
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(AppRoutes.badges),
                      icon: const AppIcon(AppIcons.rank, size: 16),
                      label: Text('badges.all_badges'.tr()),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BadgeShowcaseItem extends StatelessWidget {
  const _BadgeShowcaseItem({required this.enrichedBadge});

  final gamification.EnrichedBadge enrichedBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badge = enrichedBadge.badge;

    return Semantics(
      label: badge.nameKey.tr(),
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedRankIcon(
              iconAsset: AppIcons.getBadgeIcon(badge.tier.name),
              size: 32,
              isAnimated: false,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              badge.nameKey.tr(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
