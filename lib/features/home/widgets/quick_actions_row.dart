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
    final actions = [
      _QuickAction(
        icon: const AppIcon(AppIcons.bird, size: 18),
        label: 'birds.add_bird'.tr(),
        onPressed: () => context.push(AppRoutes.birdForm),
      ),
      _QuickAction(
        icon: const AppIcon(AppIcons.pair, size: 18),
        label: 'breeding.add_breeding'.tr(),
        onPressed: () => context.push(AppRoutes.breedingForm),
      ),
      _QuickAction(
        icon: const AppIcon(AppIcons.chick, size: 18),
        label: 'chicks.add_chick'.tr(),
        onPressed: () => context.push(AppRoutes.chickForm),
      ),
      _QuickAction(
        icon: const AppIcon(AppIcons.egg, size: 18),
        label: 'home.manage_eggs'.tr(),
        onPressed: () => context.go(AppRoutes.breeding),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 420) {
            final itemWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final action in actions)
                  SizedBox(
                    width: itemWidth,
                    child: _ActionButton(
                      icon: action.icon,
                      label: action.label,
                      onPressed: action.onPressed,
                      expand: true,
                    ),
                  ),
              ],
            );
          }

          return Stack(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                child: Row(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      _ActionButton(
                        icon: actions[i].icon,
                        label: actions[i].label,
                        onPressed: actions[i].onPressed,
                      ),
                      if (i < actions.length - 1)
                        const SizedBox(width: AppSpacing.sm),
                    ],
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
          );
        },
      ),
    );
  }
}

class _QuickAction {
  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
}

class _ActionButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onPressed;
  final bool expand;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.expand = false,
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
            horizontal: AppSpacing.md,
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
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
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
              if (expand)
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                )
              else
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
