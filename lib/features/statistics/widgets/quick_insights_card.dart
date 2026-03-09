import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/statistics_models.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/statistics/providers/statistics_trend_providers.dart';

/// A card displaying 3-4 quick text insights about the current period.
class QuickInsightsCard extends ConsumerWidget {
  const QuickInsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final insightsAsync = ref.watch(quickInsightsProvider(userId));

    return insightsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (insights) {
        if (insights.isEmpty) return const SizedBox.shrink();
        return _InsightsCardContent(insights: insights);
      },
    );
  }
}

class _InsightsCardContent extends StatelessWidget {
  const _InsightsCardContent({required this.insights});

  final List<QuickInsight> insights;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.lightbulb,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'statistics.insights_title'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _InsightRow(insight: insight),
                )),
          ],
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight});

  final QuickInsight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (Widget icon, Color color) = switch (insight.sentiment) {
      InsightSentiment.positive => (
          const AppIcon(AppIcons.growth, size: 14, color: AppColors.success),
          AppColors.success,
        ),
      InsightSentiment.negative => (
          const Icon(LucideIcons.trendingDown, size: 14, color: AppColors.error),
          AppColors.error,
        ),
      InsightSentiment.neutral => (
          AppIcon(AppIcons.info, size: 14, color: theme.colorScheme.onSurfaceVariant),
          theme.colorScheme.onSurfaceVariant,
        ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: icon,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            insight.text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
