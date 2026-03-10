import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/widgets/error_state.dart';
import '../../../data/models/profile_model.dart';
import '../../../router/route_names.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import '../widgets/account_info_card.dart';
import '../widgets/animated_section.dart';
import '../widgets/app_preferences_section.dart';
import '../widgets/avatar_picker_sheet.dart';
import '../widgets/danger_zone_section.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/password_change_sheet.dart';
import '../widgets/profile_completion_checklist.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_menu_tile.dart';
import '../widgets/profile_skeleton.dart';
import '../widgets/security_section.dart';
import '../widgets/subscription_card.dart';

/// Comprehensive user profile screen with collapsing header.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final user = ref.watch(currentUserProvider);
    final avatarState = ref.watch(avatarUploadStateProvider);
    final userId = ref.watch(currentUserIdProvider);

    // Avatar upload side effects
    ref.listen<AvatarUploadState>(avatarUploadStateProvider, (_, state) {
      if (state.isSuccess) {
        ref.read(avatarUploadStateProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile.avatar_upload_success'.tr())),
        );
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
          final displayName = profile?.resolvedDisplayName ??
              user?.email?.split('@').first ??
              '';
          final email = user?.email ?? profile?.email ?? '';
          final statsAsync = ref.watch(profileStatsProvider(userId));
          final completion =
              ref.watch(profileCompletionProvider(userId));

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userProfileProvider);
              ref.invalidate(profileStatsProvider(userId));
              AppHaptics.mediumImpact();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('profile.refresh_complete'.tr()),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Pinned AppBar (title only)
                SliverAppBar(
                  pinned: true,
                  title: Text('profile.title'.tr()),
                ),

                // Profile header (self-sizing — no fixed height)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.sm,
                    ),
                    child: ProfileHeader(
                      profile: profile,
                      displayName: displayName,
                      email: email,
                      isAvatarUploading: avatarState.isUploading,
                      stats: statsAsync.value,
                      completion: completion,
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

                // Content sections
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg),
                  sliver: SliverList.list(
                    children: [
                      // Set name banner
                      if (profile?.fullName == null ||
                          profile!.fullName!.isEmpty)
                        SetNameBanner(
                          message: 'profile.set_name_hint'.tr(),
                          onTap: () => openEditProfileSheet(
                            context,
                            ref: ref,
                            profile: profile,
                            email: email,
                          ),
                        ),

                      // Set avatar banner
                      if (profile?.avatarUrl == null &&
                          profile?.fullName != null &&
                          profile!.fullName!.isNotEmpty)
                        SetNameBanner(
                          message: 'profile.set_avatar_hint'.tr(),
                          icon: LucideIcons.camera,
                          onTap: () => showAvatarPickerSheet(
                            context,
                            ref: ref,
                            hasAvatar: false,
                          ),
                        ),

                      // Completion checklist
                      if (completion.percentage < 1.0)
                        CompletionChecklist(
                          completion: completion,
                          onItemTap: (item) =>
                              _handleCompletionTap(
                            context,
                            ref,
                            item,
                            profile: profile,
                            email: email,
                          ),
                        ),

                      // Account Info
                      AnimatedSection(
                        index: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ProfileSectionTitle(
                                label: 'profile.account_info'.tr()),
                            AccountInfoCard(
                                profile: profile, email: email),
                            const SizedBox(height: AppSpacing.md),
                            SubscriptionCard(profile: profile),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // App Preferences
                      AnimatedSection(
                        index: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ProfileSectionTitle(
                                label:
                                    'profile.app_preferences'.tr()),
                            const AppPreferencesSection(),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Security
                      AnimatedSection(
                        index: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ProfileSectionTitle(
                                label: 'profile.security'.tr()),
                            SecuritySection(
                              onChangePassword: () =>
                                  showPasswordChangeSheet(context,
                                      ref: ref),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Danger Zone
                      AnimatedSection(
                        index: 3,
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



  void _handleCompletionTap(
    BuildContext context,
    WidgetRef ref,
    CompletionItem item, {
    Profile? profile,
    required String email,
  }) {
    switch (item.labelKey) {
      case 'profile.completion_name':
        openEditProfileSheet(context, ref: ref, profile: profile, email: email);
      case 'profile.completion_avatar':
        showAvatarPickerSheet(context, ref: ref, hasAvatar: false);
      case 'profile.completion_first_bird':
        context.push('${AppRoutes.birds}/form');
      case 'profile.completion_first_pair':
        context.push('${AppRoutes.breeding}/form');
      case 'profile.completion_first_chick':
        context.push('${AppRoutes.chicks}/form');
      case 'profile.completion_premium':
        context.push(AppRoutes.premium);
    }
  }
}
