import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/action_feedback_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_list_providers.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

/// Bell icon button for the AppBar that shows unread notification count
/// and action feedback badge. Tapping shows feedback popup when available,
/// otherwise navigates to the notifications screen.
class NotificationBellButton extends ConsumerStatefulWidget {
  const NotificationBellButton({super.key});

  @override
  ConsumerState<NotificationBellButton> createState() =>
      _NotificationBellButtonState();
}

class _NotificationBellButtonState
    extends ConsumerState<NotificationBellButton> {
  final _bellKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  Timer? _autoDismissTimer;
  bool _isNavigating = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    try {
      _overlayEntry?.remove();
    } catch (_) {
      // Overlay may already be disposed if navigating away
    }
    _overlayEntry = null;
  }

  void _showFeedbackPopup(List<ActionFeedback> feedbacks) {
    _removeOverlay();

    final renderBox =
        _bellKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenWidth = MediaQuery.sizeOf(context).width;

    _overlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // Dismiss barrier
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeOverlay,
            ),
          ),
          // Popup card
          Positioned(
            top: position.dy + size.height + AppSpacing.xs,
            right: screenWidth - position.dx - size.width,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              builder: (_, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, -8 * (1 - value)),
                  child: child,
                ),
              ),
              child: _ActionFeedbackCard(
                feedbacks: feedbacks,
                onDismiss: _removeOverlay,
                onViewAll: () {
                  if (_isNavigating) return;
                  _isNavigating = true;
                  _removeOverlay();
                  if (!mounted) return;
                  context.push(AppRoutes.notifications);
                  // Reset after a short delay to allow navigation to complete
                  Future.delayed(
                    const Duration(milliseconds: 500),
                    () {
                      if (!mounted) return;
                      _isNavigating = false;
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Overlay.of(context).insert(_overlayEntry!);
    ref.read(actionFeedbackProvider.notifier).markAllRead();

    _autoDismissTimer = Timer(const Duration(seconds: 5), _removeOverlay);
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final unreadAsync = ref.watch(unreadNotificationsProvider(userId));
    final notifCount = unreadAsync.value?.length ?? 0;

    final feedbacks = ref.watch(actionFeedbackProvider);
    final unreadFeedbacks = feedbacks.where((f) => !f.isRead).toList();
    final feedbackCount = unreadFeedbacks.length;

    final totalBadge = notifCount + feedbackCount;

    return IconButton(
      key: _bellKey,
      onPressed: () {
        if (_isNavigating) return;
        if (feedbackCount > 0) {
          _showFeedbackPopup(unreadFeedbacks);
        } else {
          _isNavigating = true;
          context.push(AppRoutes.notifications);
          Future.delayed(
            const Duration(milliseconds: 500),
            () {
              if (!mounted) return;
              _isNavigating = false;
            },
          );
        }
      },
      constraints: const BoxConstraints(
        minWidth: AppSpacing.touchTargetMin,
        minHeight: AppSpacing.touchTargetMin,
      ),
      icon: totalBadge > 0
          ? Badge(
              label: Text(
                totalBadge > 99 ? '99+' : '$totalBadge',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                ),
              ),
              child: const AppIcon(AppIcons.notification, size: 22),
            )
          : const AppIcon(AppIcons.notification, size: 22),
    );
  }
}

/// Popup card showing recent action feedbacks.
class _ActionFeedbackCard extends StatelessWidget {
  final List<ActionFeedback> feedbacks;
  final VoidCallback onViewAll;
  final VoidCallback? onDismiss;

  const _ActionFeedbackCard({
    required this.feedbacks,
    required this.onViewAll,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      color: theme.colorScheme.surface,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xs),
            ...feedbacks.take(5).map(
              (f) => _FeedbackItem(feedback: f, onDismiss: onDismiss),
            ),
            const Divider(height: 1),
            InkWell(
              onTap: onViewAll,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppSpacing.radiusLg),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: Text(
                    'notifications.view_all'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single feedback item row inside the popup.
class _FeedbackItem extends StatelessWidget {
  final ActionFeedback feedback;
  final VoidCallback? onDismiss;

  const _FeedbackItem({required this.feedback, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAction = feedback.actionRoute != null;

    final icon = switch (feedback.type) {
      ActionFeedbackType.success => const Icon(
        LucideIcons.checkCircle2,
        size: 18,
        color: AppColors.success,
      ),
      ActionFeedbackType.error => Icon(
        LucideIcons.alertCircle,
        size: 18,
        color: theme.colorScheme.error,
      ),
      ActionFeedbackType.info => Icon(
        LucideIcons.info,
        size: 18,
        color: theme.colorScheme.primary,
      ),
    };

    return InkWell(
      onTap: hasAction
          ? () {
              onDismiss?.call();
              context.push(feedback.actionRoute!);
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    feedback.message,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasAction)
                    Text(
                      feedback.actionLabel ?? feedback.actionRoute!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            if (hasAction)
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
