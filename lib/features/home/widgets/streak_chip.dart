import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/gamification/streak_providers.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

/// Compact "flame + N" streak chip on the home dashboard. Tapping opens the
/// gamification badges screen. Hidden when there is no active streak.
class StreakChip extends ConsumerWidget {
  const StreakChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider).asData?.value;
    final count = streak?.currentStreak ?? 0;
    if (count <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          button: true,
          label:
              'gamification.streak_chip_label'.tr(namedArgs: {'count': '$count'}),
          child: Material(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              onTap: () => context.push(AppRoutes.badges),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.flame,
                      size: 18,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'gamification.streak_chip_label'
                          .tr(namedArgs: {'count': '$count'}),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
