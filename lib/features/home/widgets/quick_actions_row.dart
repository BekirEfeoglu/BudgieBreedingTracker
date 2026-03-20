import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';

/// Horizontal scrollable row of quick action buttons.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.lg),
      child: Stack(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: Row(
              children: [
                _ActionButton(
                  icon: const AppIcon(AppIcons.bird, size: 18),
                  label: 'birds.add_bird'.tr(),
                  onPressed: () => context.push(AppRoutes.birdForm),
                ),
                const SizedBox(width: AppSpacing.sm),
                _ActionButton(
                  icon: const AppIcon(AppIcons.pair, size: 18),
                  label: 'breeding.add_breeding'.tr(),
                  onPressed: () => context.push(AppRoutes.breedingForm),
                ),
                const SizedBox(width: AppSpacing.sm),
                _ActionButton(
                  icon: const AppIcon(AppIcons.chick, size: 18),
                  label: 'chicks.add_chick'.tr(),
                  onPressed: () => context.push(AppRoutes.chickForm),
                ),
                const SizedBox(width: AppSpacing.sm),
                _ActionButton(
                  icon: const AppIcon(AppIcons.egg, size: 18),
                  label: 'home.manage_eggs'.tr(),
                  onPressed: () => context.go(AppRoutes.breeding),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                width: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [bgColor.withValues(alpha: 0), bgColor],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: IconTheme(
                  data: IconThemeData(
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  child: icon,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
