import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../router/route_names.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/data/providers/profile_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/shared/providers/auth.dart';
import 'package:budgie_breeding_tracker/core/providers/action_feedback_providers.dart';
import 'package:budgie_breeding_tracker/shared/widgets/profile_account.dart';
import '../providers/export_providers.dart';
import 'settings_action_tile.dart';
import 'settings_navigation_tile.dart';
import 'settings_section_header.dart';
import 'settings_toggle_tile.dart';

class PrivacySecuritySection extends ConsumerWidget {
  const PrivacySecuritySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(
          title: 'settings.privacy_security'.tr(),
          icon: const AppIcon(AppIcons.security),
        ),
        if (profile != null)
          SettingsToggleTile(
            title: 'settings.show_in_leaderboard'.tr(),
            subtitle: 'settings.show_in_leaderboard_desc'.tr(),
            icon: const Icon(LucideIcons.trophy),
            value: profile.showInLeaderboard,
            onChanged: (value) =>
                _setLeaderboardVisibility(ref, profile, value),
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
          onTap: () => _showExportDataDialog(context, ref),
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

  Future<void> _setLeaderboardVisibility(
    WidgetRef ref,
    Profile profile,
    bool value,
  ) async {
    try {
      await ref
          .read(profileRepositoryProvider)
          .save(
            profile.copyWith(
              showInLeaderboard: value,
              updatedAt: DateTime.now().toUtc(),
            ),
          );
    } catch (e, st) {
      AppLogger.error(
        '[PrivacySecurity] Leaderboard visibility update failed',
        e,
        st,
      );
      await Sentry.captureException(e, stackTrace: st);
      ActionFeedbackService.show('errors.unknown'.tr());
    }
  }

  void _showPasswordChangeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: PasswordChangeForm(
            onSubmit:
                ({
                  required String currentPassword,
                  required String newPassword,
                }) async {
                  try {
                    await ref
                        .read(authActionsProvider)
                        .changePassword(
                          currentPassword: currentPassword,
                          newPassword: newPassword,
                        );
                    // Pop the dialog's own route: popping a captured outer
                    // navigator could remove the settings screen if the
                    // dialog was barrier-dismissed during the request.
                    if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                    ActionFeedbackService.show(
                      'settings.password_changed'.tr(),
                    );
                  } catch (e, st) {
                    AppLogger.error(
                      '[PrivacySecurity] Password change failed',
                      e,
                      st,
                    );
                    await Sentry.captureException(e, stackTrace: st);
                    ActionFeedbackService.show(
                      'settings.password_change_error'.tr(),
                      type: ActionFeedbackType.error,
                    );
                  }
                },
          ),
        ),
      ),
    );
  }

  void _showActiveSessionsDialog(BuildContext context, WidgetRef ref) {
    // No per-session listing is available from the backend yet, so the dialog
    // explains the action honestly instead of rendering a fake device list.
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('settings.active_sessions'.tr()),
        content: Text('settings.active_sessions_info'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton.tonal(
            onPressed: () async {
              try {
                await ref.read(authActionsProvider).signOutAllSessions();
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                ActionFeedbackService.show('settings.sessions_signed_out'.tr());
              } catch (e, st) {
                AppLogger.error('[PrivacySecurity] Sign out all failed', e, st);
                await Sentry.captureException(e, stackTrace: st);
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                ActionFeedbackService.show(
                  'errors.unknown'.tr(),
                  type: ActionFeedbackType.error,
                );
              }
            },
            child: Text('settings.sign_out_all'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportDataDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('settings.export_personal_data'.tr()),
        content: Text('settings.export_personal_data_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text('settings.export_data_button'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      // Data-ownership (GDPR) export: deliberately not premium-gated, unlike
      // the report exports on the backup screen. Returns false when another
      // export/import is already in flight.
      final exported = await ref.read(exportActionsProvider).exportExcel();
      if (!exported) return;
      ActionFeedbackService.show('backup.export_success'.tr());
    } catch (e, st) {
      AppLogger.error('[PrivacySecurity] Personal data export failed', e, st);
      await Sentry.captureException(e, stackTrace: st);
      ActionFeedbackService.show(
        'backup.export_error'.tr(),
        type: ActionFeedbackType.error,
      );
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context, WidgetRef ref) =>
      confirmAndDeleteAccount(context, ref);
}
