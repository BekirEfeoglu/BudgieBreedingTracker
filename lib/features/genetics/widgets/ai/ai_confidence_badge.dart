import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';

class AiConfidenceBadge extends StatelessWidget {
  const AiConfidenceBadge({super.key, required this.confidence});

  final LocalAiConfidence confidence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = switch (confidence) {
      LocalAiConfidence.low => 'low',
      LocalAiConfidence.medium => 'medium',
      LocalAiConfidence.high => 'high',
      LocalAiConfidence.unknown => 'unknown',
    };
    final colors = AppColors.aiConfidenceColorsAdaptive(context, level);
    final icon = switch (confidence) {
      LocalAiConfidence.high => LucideIcons.shieldCheck,
      LocalAiConfidence.medium => LucideIcons.shield,
      LocalAiConfidence.low => LucideIcons.shieldAlert,
      LocalAiConfidence.unknown => LucideIcons.shieldQuestion,
    };
    final label = switch (confidence) {
      LocalAiConfidence.low => 'genetics.ai_confidence_low'.tr(),
      LocalAiConfidence.medium => 'genetics.ai_confidence_medium'.tr(),
      LocalAiConfidence.high => 'genetics.ai_confidence_high'.tr(),
      LocalAiConfidence.unknown => 'common.unknown'.tr(),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
