import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_brand_title.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../data/providers/maintenance_mode_provider.dart';

/// Full-screen maintenance notice shown while global maintenance mode is active.
class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppBrandTitle(size: AppBrandSize.medium),
              const SizedBox(height: AppSpacing.xxxl),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: AppIcon(
                  AppIcons.warning,
                  size: 40,
                  color: AppColors.warning,
                  semanticsLabel: 'maintenance.title'.tr(),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'maintenance.title'.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'maintenance.message'.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => ref.invalidate(maintenanceModeProvider),
                  icon: const AppIcon(AppIcons.sync),
                  label: Text('maintenance.retry'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
