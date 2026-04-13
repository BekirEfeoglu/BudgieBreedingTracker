import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_providers.dart'
    show isFounderProvider;
import 'package:budgie_breeding_tracker/data/providers/premium_shared_providers.dart'
    show isPremiumProvider;
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/account_deletion_dialog.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/password_change_sheet.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_menu_header.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_menu_item.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';

class ProfileMenuDialog extends ConsumerWidget {
  const ProfileMenuDialog({
    super.key,
    required this.profile,
    required this.email,
  });

  final Profile? profile;
  final String? email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final displayName =
        profile?.resolvedDisplayName ?? email?.split('@').first ?? '';
    final displayEmail = email ?? profile?.email ?? '';
    final isFounderFromProfile = profile?.isFounder == true;
    final isFounderFromDb = ref.watch(isFounderProvider).value ?? false;
    final isFounder = isFounderFromProfile || isFounderFromDb;
    final isPremium =
        (profile?.hasPremium == true) || ref.watch(isPremiumProvider);
    final hasBadges = isPremium || isFounder || (profile?.isAdmin == true);

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.only(
          top: mediaQuery.padding.top + kToolbarHeight + AppSpacing.sm,
          right: AppSpacing.lg,
        ),
        child: Material(
          elevation: 4,
          shadowColor: theme.shadowColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          color: theme.colorScheme.surface,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // -- Header --
                ProfileMenuHeader(
                  profile: profile,
                  displayName: displayName,
                  displayEmail: displayEmail,
                  hasBadges: hasBadges,
                  isPremium: isPremium,
                  isFounder: isFounder,
                ),
                const Divider(height: 1),

                // -- Navigation group --
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ProfileMenuItem(
                        icon: const AppIcon(AppIcons.profile),
                        label: 'profile.title'.tr(),
                        showChevron: true,
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push(AppRoutes.profile);
                        },
                      ),
                      ProfileMenuItem(
                        icon: const AppIcon(AppIcons.password),
                        label: 'profile.change_password'.tr(),
                        showChevron: true,
                        onTap: () {
                          Navigator.of(context).pop();
                          showPasswordChangeSheet(context, ref: ref);
                        },
                      ),
                      ProfileMenuItem(
                        icon: const AppIcon(AppIcons.settings),
                        label: 'settings.title'.tr(),
                        showChevron: true,
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push(AppRoutes.settings);
                        },
                      ),
                      ProfileMenuItem(
                        icon: const Icon(LucideIcons.bookOpen),
                        label: 'profile.user_guide'.tr(),
                        showChevron: true,
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push(AppRoutes.userGuide);
                        },
                      ),
                      if (isFounder)
                        ProfileMenuItem(
                          icon: const AppIcon(AppIcons.security),
                          label: 'profile.founder_panel'.tr(),
                          showChevron: true,
                          onTap: () {
                            Navigator.of(context).pop();
                            context.push(AppRoutes.adminDashboard);
                          },
                        ),
                    ],
                  ),
                ),

                Divider(
                  height: 1,
                  indent: AppSpacing.xl,
                  endIndent: AppSpacing.xl,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),

                // -- Logout --
                ProfileMenuItem(
                  icon: const Icon(LucideIcons.logOut),
                  label: 'auth.logout'.tr(),
                  onTap: () {
                    final authActions = ref.read(authActionsProvider);
                    final rootNavigator = Navigator.of(
                      context,
                      rootNavigator: true,
                    );
                    rootNavigator.pop();
                    _confirmLogout(rootNavigator.context, authActions);
                  },
                ),

                Divider(
                  height: 1,
                  color: theme.colorScheme.error.withValues(alpha: 0.12),
                ),

                // -- Delete account (destructive) --
                ColoredBox(
                  color: theme.colorScheme.errorContainer.withValues(
                    alpha: 0.08,
                  ),
                  child: ProfileMenuItem(
                    icon: const AppIcon(AppIcons.delete),
                    label: 'profile.delete_account'.tr(),
                    isDestructive: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      _confirmDeleteAccount(context, ref);
                    },
                  ),
                ),

                // -- App version --
                const ProfileAppVersionLabel(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -- Confirmation Functions --

Future<void> _confirmLogout(
  BuildContext context,
  AuthActions authActions,
) async {
  final theme = Theme.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(
        LucideIcons.logOut,
        color: theme.colorScheme.primary,
        size: 32,
      ),
      title: Text('auth.logout'.tr()),
      content: Text('auth.logout_confirm'.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('common.cancel'.tr()),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text('auth.logout'.tr()),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      await authActions.signOut();
    } catch (e) {
      AppLogger.error('[ProfileMenuDialog] Sign out failed', e, StackTrace.current);
    }
    if (context.mounted) context.go(AppRoutes.login);
  }
}

Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) =>
    confirmAndDeleteAccount(context, ref);
