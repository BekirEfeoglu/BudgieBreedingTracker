import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_content_widgets.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_data.dart';

class GuideTopicCard extends StatelessWidget {
  final GuideTopic topic;
  const GuideTopicCard({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey<String>('guide-topic-${topic.titleKey}'),
        leading: IconTheme(
          data: IconThemeData(color: theme.colorScheme.primary, size: 24),
          child: AppIcon(topic.iconAsset),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(topic.title, style: theme.textTheme.titleSmall),
            ),
            if (topic.isPremium)
              Container(
                margin: const EdgeInsets.only(left: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(color: AppColors.warning, width: 1),
                ),
                child: Text(
                  'user_guide.premium_feature'.tr(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        children: [GuideBlockRenderer(blocks: topic.blocks)],
      ),
    );
  }
}
