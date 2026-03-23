import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';

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

    return Opacity(
      opacity: isDimmed ? 0.6 : 1.0,
      child: Card(
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
                _EventTypeIcon(type: event.type),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
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
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            timeFormat.format(event.eventDate),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
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
                            color: theme.colorScheme.onSurfaceVariant,
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
      ),
    );
  }
}

/// Icon widget for the event type.
class _EventTypeIcon extends StatelessWidget {
  final EventType type;

  const _EventTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = eventTypeColor(type);

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

/// Returns the appropriate icon for an [EventType].
IconData eventTypeIcon(EventType type) {
  return switch (type) {
    EventType.breeding || EventType.mating => LucideIcons.heart,
    EventType.egg || EventType.eggLaying => LucideIcons.egg,
    EventType.hatching || EventType.chick => LucideIcons.baby,
    EventType.banding => LucideIcons.tag,
    EventType.vaccination => LucideIcons.syringe,
    EventType.healthCheck || EventType.health => LucideIcons.stethoscope,
    EventType.medication => LucideIcons.pill,
    EventType.feeding => LucideIcons.wheat,
    EventType.cleaning || EventType.cageChange => LucideIcons.sparkles,
    EventType.weightCheck => LucideIcons.scale,
    EventType.custom ||
    EventType.other ||
    EventType.unknown => LucideIcons.calendar,
  };
}

/// Returns a display label for an [EventType].
String eventTypeLabel(EventType type) {
  return switch (type) {
    EventType.breeding => 'calendar.breeding_start'.tr(),
    EventType.mating => 'calendar.breeding_start'.tr(),
    EventType.egg || EventType.eggLaying => 'calendar.egg_laid'.tr(),
    EventType.hatching || EventType.chick => 'calendar.expected_hatch'.tr(),
    EventType.banding => 'calendar.milestone_banding'.tr(),
    EventType.vaccination => 'calendar.vaccination'.tr(),
    EventType.healthCheck || EventType.health => 'calendar.health_check'.tr(),
    EventType.medication => 'calendar.medication'.tr(),
    EventType.feeding => 'calendar.feeding'.tr(),
    EventType.cleaning || EventType.cageChange => 'calendar.cleaning'.tr(),
    EventType.weightCheck => 'calendar.weight_check'.tr(),
    EventType.custom ||
    EventType.other ||
    EventType.unknown => 'calendar.general'.tr(),
  };
}

/// Badge showing event status (completed, cancelled, pending).
class EventStatusBadge extends StatelessWidget {
  final EventStatus status;

  const EventStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = eventStatusColor(status);

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
        eventStatusLabel(status),
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

/// Returns a display label for an [EventStatus].
String eventStatusLabel(EventStatus status) {
  return switch (status) {
    EventStatus.active => 'calendar.status_active'.tr(),
    EventStatus.completed => 'calendar.status_completed'.tr(),
    EventStatus.cancelled => 'calendar.status_cancelled'.tr(),
    EventStatus.pending => 'calendar.status_pending'.tr(),
    EventStatus.unknown => 'calendar.status_active'.tr(),
  };
}

/// Returns a color for an [EventStatus].
Color eventStatusColor(EventStatus status) {
  return switch (status) {
    EventStatus.active => AppColors.success,
    EventStatus.completed => AppColors.primaryLight,
    EventStatus.cancelled => AppColors.error,
    EventStatus.pending => AppColors.warning,
    EventStatus.unknown => AppColors.neutral400,
  };
}

/// Centralized event type color constants.
abstract class EventTypeColors {
  static const breeding = AppColors.genderFemale;
  static const egg = AppColors.warning;
  static const hatching = AppColors.success;
  static const vaccination = AppColors.vaccination;
  static const health = AppColors.primaryLight;
  static const medication = AppColors.deepOrange;
  static const feeding = AppColors.feeding;
  static const cleaning = AppColors.info;
  static const weight = AppColors.neutral500;
  static const general = AppColors.neutral400;
}

/// Returns a color for an [EventType].
Color eventTypeColor(EventType type) {
  return switch (type) {
    EventType.breeding || EventType.mating => EventTypeColors.breeding,
    EventType.egg || EventType.eggLaying => EventTypeColors.egg,
    EventType.hatching || EventType.chick => EventTypeColors.hatching,
    EventType.banding => EventTypeColors.hatching,
    EventType.vaccination => EventTypeColors.vaccination,
    EventType.healthCheck || EventType.health => EventTypeColors.health,
    EventType.medication => EventTypeColors.medication,
    EventType.feeding => EventTypeColors.feeding,
    EventType.cleaning || EventType.cageChange => EventTypeColors.cleaning,
    EventType.weightCheck => EventTypeColors.weight,
    EventType.custom ||
    EventType.other ||
    EventType.unknown => EventTypeColors.general,
  };
}
