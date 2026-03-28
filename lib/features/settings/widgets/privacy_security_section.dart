import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../router/route_names.dart';
import '../../auth/providers/auth_providers.dart';
import '../../notifications/providers/action_feedback_providers.dart';
import '../../profile/widgets/account_deletion_dialog.dart';
import '../../profile/widgets/password_change_form.dart';
import 'settings_action_tile.dart';
import 'settings_navigation_tile.dart';
import 'settings_section_header.dart';

class PrivacySecuritySection extends ConsumerWidget {
  const PrivacySecuritySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(
          title: 'settings.privacy_security'.tr(),
          icon: const AppIcon(AppIcons.security),
        ),
        SettingsNavigationTile(
          title: 'settings.change_password'.tr(),
          icon: const AppIcon(AppIcons.password),
          onTap: () => _showPasswordChangeDialog(context, ref),
        ),
        SettingsNavigationTile(
          title: 'settings.two_factor_auth'.tr(),
          subtitle: 'settings.two_factor_desc'.tr(),
          icon: const AppIcon(AppIcons.twoFactor),
          onTap: () => context.push(AppRoutes.twoFactorSetup),
        ),
        SettingsNavigationTile(
          title: 'settings.active_sessions'.tr(),
          subtitle: 'settings.active_sessions_desc'.tr(),
          icon: const Icon(LucideIcons.monitor),
          onTap: () => _showActiveSessionsDialog(context, ref),
        ),
        SettingsActionTile(
          title: 'settings.export_personal_data'.tr(),
          subtitle: 'settings.export_personal_data_desc'.tr(),
          icon: const AppIcon(AppIcons.export),
          onTap: () => _showExportDataDialog(context),
        ),
        SettingsNavigationTile(
          title: 'settings.privacy_policy'.tr(),
          icon: const Icon(LucideIcons.fileText),
          onTap: () => context.push(AppRoutes.privacyPolicy),
        ),
        SettingsNavigationTile(
          title: 'settings.terms'.tr(),
          icon: const Icon(LucideIcons.scale),
          onTap: () => context.push(AppRoutes.termsOfService),
        ),
        SettingsNavigationTile(
          title: 'settings.community_guidelines'.tr(),
          icon: const Icon(LucideIcons.users),
          onTap: () => context.push(AppRoutes.communityGuidelines),
        ),
        SettingsActionTile(
          title: 'settings.delete_account'.tr(),
          subtitle: 'settings.delete_account_desc'.tr(),
          icon: AppIcon(
            AppIcons.delete,
            color: Theme.of(context).colorScheme.error,
          ),
          onTap: () => _showDeleteAccountDialog(context, ref),
        ),
      ],
    );
  }

  void _showPasswordChangeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: PasswordChangeForm(
            onSubmit:
                ({
                  required String currentPassword,
                  required String newPassword,
                }) async {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  try {
                    await ref
                        .read(authActionsProvider)
                        .changePassword(
                          currentPassword: currentPassword,
                          newPassword: newPassword,
                        );
                    navigator.pop();
                    ActionFeedbackService.show('settings.password_changed'.tr());
                  } catch (e) {
                    AppLogger.error(
                      '[PrivacySecurity] Password change failed',
                      e,
                      StackTrace.current,
                    );
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('settings.password_change_error'.tr()),
                      ),
                    );
                  }
                },
          ),
        ),
      ),
    );
  }

  void _showActiveSessionsDialog(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('settings.active_sessions'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.smartphone),
              title: Text('settings.current_device'.tr()),
              subtitle: Text('settings.this_device'.tr()),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'settings.active'.tr(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton.tonal(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              try {
                await ref.read(authActionsProvider).signOutAllSessions();
                navigator.pop();
                ActionFeedbackService.show('settings.sessions_signed_out'.tr());
              } catch (e) {
                AppLogger.error('[PrivacySecurity] Sign out all failed', e, StackTrace.current);
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('errors.unknown'.tr())),
                );
              }
            },
            child: Text('settings.sign_out_all'.tr()),
          ),
        ],
      ),
    );
  }

  void _showExportDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('settings.export_personal_data'.tr()),
        content: Text('settings.export_personal_data_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('settings.export_data_started'.tr())),
              );
            },
            child: Text('settings.export_data_button'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context, WidgetRef ref) =>
      confirmAndDeleteAccount(context, ref);
}
