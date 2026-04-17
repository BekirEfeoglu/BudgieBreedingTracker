import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_screen_title.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_content_widgets.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_data.dart';

class GuideDetailScreen extends StatelessWidget {
  final int topicIndex;
  const GuideDetailScreen({super.key, required this.topicIndex});

  @override
  Widget build(BuildContext context) {
    if (topicIndex < 0 || topicIndex >= guideTopics.length) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('common.not_found'.tr())),
      );
    }

    final topic = guideTopics[topicIndex];

    return Scaffold(
      appBar: AppBar(
        title: AppScreenTitle(title: topic.title, iconAsset: topic.iconAsset),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailHeader(topic: topic),
            const SizedBox(height: AppSpacing.lg),
            GuideBlockRenderer(blocks: topic.blocks),
            if (topic.relatedTopicIndices.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              _RelatedTopicsSection(
                indices: topic.relatedTopicIndices,
                currentIndex: topicIndex,
              ),
            ],
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail header — icon, category label, step count
// ---------------------------------------------------------------------------

class _DetailHeader extends StatelessWidget {
  final GuideTopic topic;
  const _DetailHeader({required this.topic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Center(
            child: IconTheme(
              data: IconThemeData(color: theme.colorScheme.primary, size: 24),
              child: AppIcon(topic.iconAsset),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topic.category.label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              if (topic.stepCount > 0) ...[
                const SizedBox(height: 2),
                Text(
                  'user_guide.step_count'.tr(
                    args: [topic.stepCount.toString()],
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Related topics section
// ---------------------------------------------------------------------------

class _RelatedTopicsSection extends StatelessWidget {
  final List<int> indices;
  final int currentIndex;

  const _RelatedTopicsSection({
    required this.indices,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'user_guide.related_topics'.tr().toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < indices.length; i++) ...[
                _RelatedTopicItem(topicIndex: indices[i]),
                if (i < indices.length - 1)
                  Divider(
                    height: 1,
                    indent: AppSpacing.lg + 32 + AppSpacing.md,
                    endIndent: 0,
                    color: theme.colorScheme.outlineVariant,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RelatedTopicItem extends StatelessWidget {
  final int topicIndex;
  const _RelatedTopicItem({required this.topicIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topic = guideTopics[topicIndex];

    return InkWell(
      onTap: () => context.push('${AppRoutes.userGuide}/$topicIndex'),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Center(
                child: IconTheme(
                  data: IconThemeData(
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  child: AppIcon(topic.iconAsset),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                topic.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
