import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/skeleton_loader.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_confidence_badge.dart';

/// Animated slot that shows loading skeleton, error, or result content.
class AiAnimatedResultSlot extends StatelessWidget {
  const AiAnimatedResultSlot({
    super.key,
    required this.isLoading,
    required this.hasError,
    this.errorMessage,
    this.child,
  });

  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final showContent = isLoading || hasError || child != null;
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: showContent
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: isLoading
                    ? const AiInsightSkeleton(key: ValueKey('skeleton'))
                    : hasError
                        ? AiErrorBox(
                            key: const ValueKey('error'),
                            message: errorMessage ?? '',
                          )
                        : KeyedSubtree(
                            key: const ValueKey('result'),
                            child: child!,
                          ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// Displays AI analysis result: confidence badge, summary, bullet points.
class AiResultSection extends StatelessWidget {
  const AiResultSection({
    super.key,
    required this.title,
    required this.confidence,
    required this.summary,
    required this.bullets,
  });

  final String title;
  final LocalAiConfidence confidence;
  final String summary;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredBullets =
        bullets.where((item) => item.trim().isNotEmpty).toList();
    final level = switch (confidence) {
      LocalAiConfidence.low => 'low',
      LocalAiConfidence.medium => 'medium',
      LocalAiConfidence.high => 'high',
      LocalAiConfidence.unknown => 'unknown',
    };
    final colors = AppColors.aiConfidenceColorsAdaptive(context, level);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AiConfidenceBadge(confidence: confidence),
            ],
          ),
          if (summary.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border(
                  left: BorderSide(color: colors.border, width: 2.5),
                ),
              ),
              child: Text(
                summary,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
          if (filteredBullets.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ...filteredBullets.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              colors.foreground.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        item,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Skeleton placeholder shown while AI analysis is loading.
class AiInsightSkeleton extends StatelessWidget {
  const AiInsightSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color:
              theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: SkeletonLoader(height: 16, width: 180),
              ),
              SizedBox(width: AppSpacing.md),
              SkeletonLoader(
                height: 24,
                width: 100,
                borderRadius: AppSpacing.radiusFull,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const SkeletonLoader(height: 12),
          const SizedBox(height: AppSpacing.sm),
          const SkeletonLoader(height: 12, width: 260),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < 3; i++) ...[
            Row(
              children: [
                const SizedBox(width: AppSpacing.xs),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.2),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SkeletonLoader(
                    height: 12,
                    width: i == 1 ? 200 : double.infinity,
                  ),
                ),
              ],
            ),
            if (i < 2) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

/// Error display box for failed AI analysis.
class AiErrorBox extends StatelessWidget {
  const AiErrorBox({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}
