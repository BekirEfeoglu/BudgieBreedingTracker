import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../router/route_names.dart';
import '../../auth/providers/auth_providers.dart';
import 'account_deletion_dialog.dart';
import 'profile_menu_tile.dart';

/// Danger zone section with logout and delete account.
class DangerZoneSection extends ConsumerWidget {
  const DangerZoneSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          ProfileMenuTile(
            icon: const Icon(LucideIcons.logOut, size: 22),
            label: 'auth.logout'.tr(),
            onTap: () => _confirmLogout(context, ref),
          ),
          Divider(
            height: 1,
            indent: AppSpacing.lg + 24 + AppSpacing.md,
            color: AppColors.error.withValues(alpha: 0.2),
          ),
          ProfileMenuTile(
            icon: const AppIcon(AppIcons.delete, size: 22),
            label: 'profile.delete_account'.tr(),
            isDestructive: true,
            onTap: () => confirmAndDeleteAccount(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('auth.logout'.tr()),
        content: Text('auth.logout_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text('auth.logout'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authActionsProvider).signOut();
      if (context.mounted) context.go(AppRoutes.login);
    }
  }
}
