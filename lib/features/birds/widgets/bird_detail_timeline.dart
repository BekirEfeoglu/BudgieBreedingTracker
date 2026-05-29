import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/providers/date_format_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_timeline_providers.dart';

/// Compact life timeline assembled from existing local data.
class BirdDetailTimeline extends ConsumerWidget {
  final Bird bird;

  const BirdDetailTimeline({super.key, required this.bird});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(birdTimelineProvider(bird));
    if (events.isEmpty) return const SizedBox.shrink();

    return _TimelineContent(
      events: events,
      dateFormat: ref.watch(dateFormatProvider).formatter(),
    );
  }
}

/// Timeline section with its own divider, omitted entirely when no events exist.
class BirdDetailTimelineSection extends ConsumerWidget {
  final Bird bird;

  const BirdDetailTimelineSection({super.key, required this.bird});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(birdTimelineProvider(bird));
    if (events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(
          height: 1,
          indent: AppSpacing.lg,
          endIndent: AppSpacing.lg,
        ),
        _TimelineContent(
          events: events,
          dateFormat: ref.watch(dateFormatProvider).formatter(),
        ),
      ],
    );
  }
}

class _TimelineContent extends StatelessWidget {
  final List<BirdTimelineEvent> events;
  final DateFormat dateFormat;

  const _TimelineContent({required this.events, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text('birds.timeline_title'.tr(), style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          ...events.indexed.map(
            (entry) => _TimelineRow(
              event: entry.$2,
              isLast: entry.$1 == events.length - 1,
              dateFormat: dateFormat,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final BirdTimelineEvent event;
  final bool isLast;
  final DateFormat dateFormat;

  const _TimelineRow({
    required this.event,
    required this.isLast,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use the user's chosen date format (dateFormatProvider) supplied by the
    // parent instead of a locale-default yMd built per row.
    final dateText = dateFormat.format(event.date);
    final title = event.title ?? event.titleKey.tr(namedArgs: event.namedArgs);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSpacing.touchTargetMin,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: AppIcon(event.iconAsset, size: 18),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 2),
                  Text(
                    dateText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
