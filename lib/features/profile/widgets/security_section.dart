import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../router/route_names.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import 'profile_menu_tile.dart';
import 'security_score_card.dart';

/// Security section with security score, password change and 2FA options.
class SecuritySection extends ConsumerWidget {
  const SecuritySection({super.key, required this.onChangePassword});

  final VoidCallback onChangePassword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final score = ref.watch(securityScoreProvider(userId));

    return Column(
      children: [
        // Security score card
        SecurityScoreCard(
          securityScore: score,
          onFactorTap: (factor) => _handleFactorTap(context, factor),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Action tiles
        Card(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              ProfileMenuTile(
                icon: const AppIcon(AppIcons.password, size: 22),
                label: 'profile.change_password'.tr(),
                onTap: onChangePassword,
              ),
              const Divider(
                height: 1,
                indent: AppSpacing.lg + 24 + AppSpacing.md,
              ),
              ProfileMenuTile(
                icon: const AppIcon(AppIcons.security, size: 22),
                label: 'profile.two_factor_auth'.tr(),
                onTap: () => context.push(AppRoutes.twoFactorSetup),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleFactorTap(BuildContext context, SecurityFactor factor) {
    if (factor.labelKey == 'profile.security_factor_2fa') {
      context.push(AppRoutes.twoFactorSetup);
    } else if (factor.labelKey == 'profile.security_factor_password') {
      onChangePassword();
    } else if (factor.labelKey == 'profile.security_factor_profile') {
      context.push(AppRoutes.profile);
    } else if (factor.labelKey == 'profile.security_factor_premium') {
      context.push(AppRoutes.premium);
    }
  }
}
