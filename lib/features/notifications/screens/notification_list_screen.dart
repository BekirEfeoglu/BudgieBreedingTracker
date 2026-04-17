import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_screen_title.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/action_feedback_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_list_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/widgets/notification_action_feedback_section.dart';
import 'package:budgie_breeding_tracker/features/notifications/widgets/notification_card.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

/// Screen showing the user's notification inbox.
class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final notificationsAsync = ref.watch(notificationsStreamProvider(userId));
    final filter = ref.watch(notificationFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: AppScreenTitle(
          title: 'notifications.inbox_title'.tr(),
          iconAsset: AppIcons.notification,
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.checkCheck),
            tooltip: 'notifications.mark_all_read'.tr(),
            onPressed: () => _markAllAsRead(ref, userId),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: NotificationFilter.values.map((f) {
                final isSelected = f == filter;
                return ChoiceChip(
                  label: Text(f.label),
                  selected: isSelected,
                  onSelected: (_) =>
                      ref.read(notificationFilterProvider.notifier).state = f,
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // Notification list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(notificationsStreamProvider(userId));
              },
              child: notificationsAsync.when(
                loading: () => const LoadingState(),
                error: (error, _) => ErrorState(
                  message: 'notifications.load_error'.tr(),
                  onRetry: () =>
                      ref.invalidate(notificationsStreamProvider(userId)),
                ),
                data: (allNotifications) {
                  final filtered = ref.watch(
                    filteredNotificationsProvider(allNotifications),
                  );
                  final feedbacks = ref.watch(actionFeedbackProvider);
                  final hasFeedbacks = feedbacks.isNotEmpty;

                  if (allNotifications.isEmpty && !hasFeedbacks) {
                    return EmptyState(
                      icon: const Icon(LucideIcons.bellOff),
                      title: 'notifications.no_notifications'.tr(),
                      subtitle: 'notifications.no_notifications_hint'.tr(),
                    );
                  }

                  // Lazy-render notification list via CustomScrollView so
                  // long lists don't pay the upfront build cost of eager
                  // ListView children.
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            sliver: SliverToBoxAdapter(
                              child: hasFeedbacks
                                  ? Column(
                                      children: [
                                        ActionFeedbacksSection(
                                          feedbacks: feedbacks,
                                        ),
                                        if (filtered.isNotEmpty)
                                          const Divider(
                                            height: AppSpacing.lg,
                                          ),
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                          if (filtered.isEmpty && allNotifications.isNotEmpty)
                            SliverToBoxAdapter(
                              child: EmptyState(
                                icon: const Icon(LucideIcons.searchX),
                                title: 'common.no_results'.tr(),
                                subtitle: 'common.no_results_hint'.tr(),
                              ),
                            )
                          else
                            SliverList.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final notification = filtered[index];
                                return NotificationCard(
                                  key: ValueKey(notification.id),
                                  notification: notification,
                                  onTap: () => _onNotificationTap(
                                    context,
                                    ref,
                                    notification,
                                  ),
                                  onDismiss: () => _onDelete(
                                    context,
                                    ref,
                                    notification.id,
                                  ),
                                );
                              },
                            ),
                          const SliverPadding(
                            padding: EdgeInsets.only(
                              bottom: AppSpacing.xxxl * 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    // Mark as read
    if (!notification.read) {
      ref.read(notificationActionsProvider).markAsRead(notification.id);
    }

    // Deep link to referenced entity
    if (notification.referenceType != null &&
        notification.referenceId != null) {
      final route = NotificationService.payloadToRoute(
        '${notification.referenceType}:${notification.referenceId}',
      );
      if (route != null) {
        context.push(route);
        return;
      }
    }
  }

  void _markAllAsRead(WidgetRef ref, String userId) {
    ref.read(notificationActionsProvider).markAllAsRead(userId);
  }

  Future<void> _onDelete(
    BuildContext context,
    WidgetRef ref,
    String notificationId,
  ) async {
    try {
      await ref.read(notificationActionsProvider).delete(notificationId);
    } catch (e) {
      AppLogger.error('[NotificationListScreen]', e, StackTrace.current);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('notifications.delete_error'.tr())),
        );
      }
    }
  }
}
