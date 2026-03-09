import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../data/models/profile_model.dart';
import 'profile_menu_tile.dart';

/// Card displaying user account information.
class AccountInfoCard extends StatelessWidget {
  const AccountInfoCard({
    super.key,
    required this.profile,
    required this.email,
  });

  final Profile? profile;
  final String email;

  @override
  Widget build(BuildContext context) {
    final createdAt = profile?.createdAt;
    final role = profile?.role;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Email
            ProfileInfoRow(
              icon: const Icon(LucideIcons.mail, size: 20),
              label: 'profile.email'.tr(),
              value: email,
              trailing: email.isNotEmpty
                  ? Tooltip(
                      message: 'profile.copy_email'.tr(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _copyEmail(context, email),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          child: Icon(
                            LucideIcons.copy,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),

            // Full name
            if (profile?.fullName != null &&
                profile!.fullName!.isNotEmpty) ...[
              const Divider(height: AppSpacing.xxl),
              ProfileInfoRow(
                icon: const AppIcon(AppIcons.profile, size: 20),
                label: 'profile.full_name'.tr(),
                value: profile!.fullName!,
              ),
            ],

            // Member since
            if (createdAt != null) ...[
              const Divider(height: AppSpacing.xxl),
              ProfileInfoRow(
                icon: const AppIcon(AppIcons.calendar, size: 20),
                label: 'profile.member_since'.tr(),
                value: DateFormat.yMMMMd(
                  context.locale.toStringWithSeparator(),
                ).format(createdAt),
              ),
            ],

            // Role
            if (role != null && role.isNotEmpty) ...[
              const Divider(height: AppSpacing.xxl),
              ProfileInfoRow(
                icon: const AppIcon(AppIcons.security, size: 20),
                label: 'profile.role_label'.tr(),
                value: _roleLabel(role),
                valueColor: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _copyEmail(BuildContext context, String email) {
    Clipboard.setData(ClipboardData(text: email));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('profile.email_copied'.tr()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _roleLabel(String role) => switch (role) {
        'founder' => 'profile.role_founder'.tr(),
        'admin' => 'profile.role_admin'.tr(),
        _ => 'profile.role_user'.tr(),
      };
}
