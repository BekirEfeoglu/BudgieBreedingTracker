import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/features/calendar/widgets/event_card.dart';

/// Shows an event detail bottom sheet.
Future<void> showEventDetailModal(
  BuildContext context, {
  required Event event,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  ValueChanged<EventStatus>? onStatusChange,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
    ),
    builder: (ctx) => _EventDetailContent(
      event: event,
      onEdit: onEdit,
      onDelete: onDelete,
      onStatusChange: onStatusChange,
    ),
  );
}

class _EventDetailContent extends StatelessWidget {
  final Event event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<EventStatus>? onStatusChange;

  const _EventDetailContent({
    required this.event,
    required this.onEdit,
    required this.onDelete,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat(
      'dd MMMM yyyy, HH:mm',
      context.locale.toStringWithSeparator(),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Type icon + title
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor:
                    eventTypeColor(event.type).withValues(alpha: 0.15),
                child: Icon(
                  eventTypeIcon(event.type),
                  size: 22,
                  color: eventTypeColor(event.type),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          eventTypeLabel(event.type),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: eventTypeColor(event.type),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (event.status != EventStatus.active &&
                            event.status != EventStatus.unknown) ...[
                          const SizedBox(width: AppSpacing.sm),
                          EventStatusBadge(status: event.status),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Date/time
          Row(
            children: [
              Icon(
                LucideIcons.clock,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                dateFormat.format(event.eventDate),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),

          // Status
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                LucideIcons.checkCircle,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${'calendar.event_status'.tr()}: ${eventStatusLabel(event.status)}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),

          // Notes
          if (event.notes != null && event.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              event.notes!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Status change buttons
          if (onStatusChange != null &&
              event.status == EventStatus.active) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onStatusChange!(EventStatus.completed);
                    },
                    icon: const Icon(LucideIcons.checkCircle, size: 18),
                    label: Text('calendar.mark_completed'.tr()),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onStatusChange!(EventStatus.cancelled);
                    },
                    icon: Icon(
                      LucideIcons.xCircle,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    label: Text(
                      'calendar.mark_cancelled'.tr(),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onEdit();
                },
                icon: const AppIcon(AppIcons.edit, size: 18),
                label: Text('common.edit'.tr()),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  Navigator.pop(context);
                  onDelete();
                },
                icon: AppIcon(
                  AppIcons.delete,
                  size: 18,
                  color: theme.colorScheme.onError,
                ),
                label: Text('common.delete'.tr()),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
