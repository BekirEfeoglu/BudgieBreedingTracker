import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';

part 'event_card_helpers.dart';

/// Card displaying a single event with type icon, title, date, and actions.
class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat.Hm();
    final isDimmed =
        event.status == EventStatus.completed ||
        event.status == EventStatus.cancelled;

    final double dimAlpha = isDimmed ? 0.6 : 1.0;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EventTypeIcon(type: event.type, alpha: dimAlpha),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.titleSmall?.color?.withValues(
                          alpha: dimAlpha,
                        ),
                        decoration: event.status == EventStatus.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: dimAlpha,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          timeFormat.format(event.eventDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: dimAlpha),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _EventTypeBadge(type: event.type),
                        if (event.status != EventStatus.active &&
                            event.status != EventStatus.unknown) ...[
                          const SizedBox(width: AppSpacing.sm),
                          EventStatusBadge(status: event.status),
                        ],
                      ],
                    ),
                    if (event.notes != null && event.notes!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        event.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: dimAlpha,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              _EventActions(onEdit: onEdit, onDelete: onDelete),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon widget for the event type.
class _EventTypeIcon extends StatelessWidget {
  final EventType type;
  final double alpha;

  const _EventTypeIcon({required this.type, this.alpha = 1.0});

  @override
  Widget build(BuildContext context) {
    final color = eventTypeColor(type).withValues(alpha: alpha);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Icon(eventTypeIcon(type), size: 20, color: color),
    );
  }
}

/// Small badge showing the event type label.
class _EventTypeBadge extends StatelessWidget {
  final EventType type;

  const _EventTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = eventTypeColor(type);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        eventTypeLabel(type),
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

/// Edit and delete action buttons.
class _EventActions extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _EventActions({this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          IconButton(
            icon: const AppIcon(AppIcons.edit, size: 18),
            onPressed: onEdit,
            tooltip: 'calendar.edit_event'.tr(),
            constraints: const BoxConstraints(
              minWidth: AppSpacing.touchTargetMin,
              minHeight: AppSpacing.touchTargetMin,
            ),
          ),
        if (onDelete != null)
          IconButton(
            icon: AppIcon(
              AppIcons.delete,
              size: 18,
              color: Theme.of(context).colorScheme.error,
            ),
            onPressed: onDelete,
            tooltip: 'calendar.delete_event'.tr(),
            constraints: const BoxConstraints(
              minWidth: AppSpacing.touchTargetMin,
              minHeight: AppSpacing.touchTargetMin,
            ),
          ),
      ],
    );
  }
}
