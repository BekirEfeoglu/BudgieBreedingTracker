import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/dialogs/confirm_dialog.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';

/// Card widget for displaying a single notification item.
class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.read;
    final typeColor = notificationTypeColor(notification.type);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => showConfirmDialog(
        context,
        title: 'notifications.delete_title'.tr(),
        message: 'notifications.delete_confirm'.tr(),
        confirmLabel: 'common.delete'.tr(),
        isDestructive: true,
      ),
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: theme.colorScheme.error,
        child: AppIcon(
          AppIcons.delete,
          color: theme.colorScheme.onError,
          semanticsLabel: 'common.delete'.tr(),
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        color: isUnread
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
            : null,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type icon
                CircleAvatar(
                  radius: 20,
                  backgroundColor: typeColor.withValues(alpha: 0.15),
                  child: notificationTypeWidget(notification.type, typeColor),
                ),
                const SizedBox(width: AppSpacing.md),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Unread dot
                          if (isUnread) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                          ],
                          Expanded(
                            child: Text(
                              notification.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: isUnread
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (notification.body != null &&
                          notification.body!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          notification.body!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _formatTimeAgo(notification.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Priority indicator
                if (notification.priority == NotificationPriority.high ||
                    notification.priority == NotificationPriority.critical)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm),
                    child: AppIcon(
                      AppIcons.warning,
                      size: 16,
                      color:
                          notification.priority == NotificationPriority.critical
                          ? theme.colorScheme.error
                          : AppColors.warning,
                      semanticsLabel: 'notifications.high_priority'.tr(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'common.just_now'.tr();
    if (diff.inMinutes < 60) {
      return 'common.minutes_ago'.tr(args: ['${diff.inMinutes}']);
    }
    if (diff.inHours < 24) {
      return 'common.hours_ago'.tr(args: ['${diff.inHours}']);
    }
    if (diff.inDays < 7) {
      return 'common.days_ago'.tr(args: ['${diff.inDays}']);
    }
    return DateFormat.yMMMd(Intl.getCurrentLocale()).format(dateTime);
  }
}

/// Returns a widget icon for a notification type.
///
/// Uses SVG [AppIcon] where available, falls back to [Icon] with LucideIcons.
Widget notificationTypeWidget(NotificationType type, Color color) =>
    switch (type) {
      NotificationType.eggTurning => Icon(
        LucideIcons.rotateCw,
        size: 20,
        color: color,
      ),
      NotificationType.temperatureAlert => Icon(
        LucideIcons.thermometer,
        size: 20,
        color: color,
      ),
      NotificationType.humidityAlert => Icon(
        LucideIcons.droplets,
        size: 20,
        color: color,
      ),
      NotificationType.feedingReminder => Icon(
        LucideIcons.utensils,
        size: 20,
        color: color,
      ),
      NotificationType.incubationReminder => AppIcon(
        AppIcons.incubation,
        size: 20,
        color: color,
      ),
      NotificationType.healthCheck => AppIcon(
        AppIcons.health,
        size: 20,
        color: color,
      ),
      NotificationType.custom || NotificationType.unknown => AppIcon(
        AppIcons.notification,
        size: 20,
        color: color,
      ),
    };

/// Returns the color for a notification type.
Color notificationTypeColor(NotificationType type) => switch (type) {
  NotificationType.eggTurning => AppColors.warning,
  NotificationType.temperatureAlert => AppColors.error,
  NotificationType.humidityAlert => AppColors.info,
  NotificationType.feedingReminder => AppColors.success,
  NotificationType.incubationReminder => AppColors.medication,
  NotificationType.healthCheck => AppColors.teal,
  NotificationType.custom || NotificationType.unknown => AppColors.neutral400,
};

/// Returns a localized label for a notification type.
String notificationTypeLabel(NotificationType type) => switch (type) {
  NotificationType.eggTurning => 'notifications.egg_turning'.tr(),
  NotificationType.temperatureAlert => 'notifications.temperature_alert'.tr(),
  NotificationType.humidityAlert => 'notifications.humidity_alert'.tr(),
  NotificationType.feedingReminder => 'notifications.feeding_reminder'.tr(),
  NotificationType.incubationReminder => 'notifications.incubation'.tr(),
  NotificationType.healthCheck => 'notifications.health_check'.tr(),
  NotificationType.custom ||
  NotificationType.unknown => 'notifications.custom'.tr(),
};
