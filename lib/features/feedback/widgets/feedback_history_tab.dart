import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/feedback/providers/feedback_providers.dart';
import 'package:budgie_breeding_tracker/features/feedback/widgets/feedback_form_widgets.dart';

/// Tab content that displays the user's previously submitted feedback entries.
class FeedbackHistoryTab extends ConsumerWidget {
  const FeedbackHistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final historyAsync = ref.watch(feedbackHistoryProvider(userId));

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => FeedbackHistoryError(
        onRetry: () => ref.invalidate(feedbackHistoryProvider(userId)),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const FeedbackHistoryEmpty();
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(feedbackHistoryProvider(userId));
            await ref.read(feedbackHistoryProvider(userId).future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.xxxl * 2,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              return FeedbackHistoryCard(entry: entries[index]);
            },
          ),
        );
      },
    );
  }
}

/// Empty state shown when no feedback has been submitted yet.
class FeedbackHistoryEmpty extends StatelessWidget {
  const FeedbackHistoryEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.inbox,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'feedback.no_submissions'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'feedback.no_submissions_hint'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state shown when feedback history fails to load.
class FeedbackHistoryError extends StatelessWidget {
  final VoidCallback onRetry;

  const FeedbackHistoryError({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.alertTriangle,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'feedback.history_error'.tr(),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
