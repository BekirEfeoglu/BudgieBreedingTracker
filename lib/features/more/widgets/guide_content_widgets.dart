import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_data.dart';

// ---------------------------------------------------------------------------
// Tip box (blue-tinted)
// ---------------------------------------------------------------------------

class GuideTipBox extends StatelessWidget {
  final String textKey;
  const GuideTipBox({super.key, required this.textKey});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final containerColor =
        theme.colorScheme.primaryContainer.withValues(alpha: 0.3);
    final accentColor = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(AppIcons.info, size: 20, color: accentColor, semanticsLabel: 'Tip'),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: '${'user_guide.tip_label'.tr()} ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                TextSpan(
                  text: textKey.tr(),
                  style: theme.textTheme.bodyMedium,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Warning box (orange-tinted)
// ---------------------------------------------------------------------------

class GuideWarningBox extends StatelessWidget {
  final String textKey;
  const GuideWarningBox({super.key, required this.textKey});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const warningColor = AppColors.warning;
    final containerColor = warningColor.withValues(alpha: 0.1);

    return Container(
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: const Border(left: BorderSide(color: warningColor, width: 4)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIcon(AppIcons.warning, size: 20, color: warningColor, semanticsLabel: 'Warning'),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: '${'user_guide.warning_label'.tr()} ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: warningColor,
                  ),
                ),
                TextSpan(
                  text: textKey.tr(),
                  style: theme.textTheme.bodyMedium,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Premium note (amber-tinted)
// ---------------------------------------------------------------------------

class GuidePremiumNote extends StatelessWidget {
  final String textKey;
  const GuidePremiumNote({super.key, required this.textKey});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final containerColor = AppColors.warning.withValues(alpha: 0.12);

    return Container(
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: const Border(
          left: BorderSide(color: AppColors.premiumGoldDark, width: 4),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIcon(AppIcons.premium, size: 20, color: AppColors.premiumGoldDark),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              textKey.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.premiumGoldDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Numbered step list
// ---------------------------------------------------------------------------

class GuideStepList extends StatelessWidget {
  final String titleKey;
  final List<String> stepKeys;

  const GuideStepList({
    super.key,
    required this.titleKey,
    required this.stepKeys,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titleKey.tr(),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...List.generate(stepKeys.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    '${i + 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      stepKeys[i].tr(),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Block renderer — converts a list of GuideBlock to widgets
// ---------------------------------------------------------------------------

class GuideBlockRenderer extends StatelessWidget {
  final List<GuideBlock> blocks;
  const GuideBlockRenderer({super.key, required this.blocks});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = <Widget>[];

    for (final block in blocks) {
      switch (block.type) {
        case GuideBlockType.text:
          children.add(Text(block.textKey!.tr(), style: theme.textTheme.bodyMedium));
        case GuideBlockType.tip:
          children.add(GuideTipBox(textKey: block.textKey!));
        case GuideBlockType.warning:
          children.add(GuideWarningBox(textKey: block.textKey!));
        case GuideBlockType.premiumNote:
          children.add(GuidePremiumNote(textKey: block.textKey!));
        case GuideBlockType.steps:
          children.add(GuideStepList(
            titleKey: block.stepsTitle!,
            stepKeys: block.stepKeys!,
          ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
