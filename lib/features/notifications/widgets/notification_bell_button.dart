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
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/action_feedback_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_list_providers.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

part 'notification_bell_button_widgets.dart';

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
